import Foundation
#if canImport(Virtualization)
import Virtualization
#endif

/// VirtualMachineEngine communicates directly with Apple's Virtualization.framework
/// to build hardware definitions, initialize hypervisors, and manage VM runtimes.
public final class VirtualMachineEngine: NSObject, ObservableObject {
    public let config: VMConfiguration

    @Published public private(set) var state: VMState = .stopped
    @Published public private(set) var ipAddress: String? = nil
    @Published public private(set) var errorMessage: String? = nil

    #if canImport(Virtualization)
    private var vzVM: VZVirtualMachine?
    #endif

    public init(config: VMConfiguration) {
        self.config = config
        super.init()
    }

    #if canImport(Virtualization)
    /// Exposes the underlying VZVirtualMachine for rendering in SwiftUI via VZVirtualMachineView
    public var rawVirtualMachine: VZVirtualMachine? {
        return vzVM
    }
    #endif

    // MARK: - Lifecycle Controls

    @MainActor
    public func start(completion: @escaping (Result<Void, Error>) -> Void) {
        guard state.canStart else {
            completion(.failure(EngineError.invalidStateTransition("Cannot start from state: \(state.title)")))
            return
        }

        state = .starting
        errorMessage = nil

        #if canImport(Virtualization)
        // 1. Build Virtualization Configuration
        let vzConfig: VZVirtualMachineConfiguration
        do {
            vzConfig = try buildVZConfiguration()
            try vzConfig.validate()
        } catch {
            let errorMsg = error.localizedDescription
            self.errorMessage = errorMsg
            self.state = .error(message: errorMsg)
            completion(.failure(error))
            return
        }

        // 2. Initialize VZVirtualMachine instance
        let machine = VZVirtualMachine(configuration: vzConfig)
        machine.delegate = self
        self.vzVM = machine

        // 3. Start execution
        machine.start { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                switch result {
                case .success:
                    self.state = .running
                    completion(.success(()))
                case .failure(let error):
                    let errorMsg = error.localizedDescription
                    self.errorMessage = errorMsg
                    self.state = .error(message: errorMsg)
                    self.vzVM = nil
                    completion(.failure(error))
                }
            }
        }
        #else
        // Mock fallback for non-macOS environments
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.state = .running
            completion(.success(()))
        }
        #endif
    }

    @MainActor
    public func pause(completion: @escaping (Result<Void, Error>) -> Void) {
        guard state.canPause else {
            completion(.failure(EngineError.invalidStateTransition("Cannot pause from state: \(state.title)")))
            return
        }

        #if canImport(Virtualization)
        guard let machine = vzVM else {
            completion(.failure(EngineError.machineNotInitialized))
            return
        }

        machine.pause { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                switch result {
                case .success:
                    self.state = .paused
                    completion(.success(()))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
        #else
        self.state = .paused
        completion(.success(()))
        #endif
    }

    @MainActor
    public func resume(completion: @escaping (Result<Void, Error>) -> Void) {
        guard state.canResume else {
            completion(.failure(EngineError.invalidStateTransition("Cannot resume from state: \(state.title)")))
            return
        }

        #if canImport(Virtualization)
        guard let machine = vzVM else {
            completion(.failure(EngineError.machineNotInitialized))
            return
        }

        machine.resume { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                switch result {
                case .success:
                    self.state = .running
                    completion(.success(()))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
        #else
        self.state = .running
        completion(.success(()))
        #endif
    }

    @MainActor
    public func requestStop(completion: @escaping (Result<Void, Error>) -> Void) {
        guard state.canStop else {
            completion(.failure(EngineError.invalidStateTransition("Cannot stop from state: \(state.title)")))
            return
        }

        self.state = .stopping

        #if canImport(Virtualization)
        guard let machine = vzVM else {
            self.state = .stopped
            completion(.success(()))
            return
        }

        do {
            try machine.requestStop()
            completion(.success(()))
        } catch {
            // Fallback to force stop if graceful shutdown request fails
            self.forceStop(completion: completion)
        }
        #else
        self.state = .stopped
        completion(.success(()))
        #endif
    }

    @MainActor
    public func forceStop(completion: @escaping (Result<Void, Error>) -> Void) {
        self.state = .stopping

        #if canImport(Virtualization)
        guard let machine = vzVM else {
            self.state = .stopped
            completion(.success(()))
            return
        }

        machine.stop { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.vzVM = nil
                self.state = .stopped
                switch result {
                case .success:
                    completion(.success(()))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
        #else
        self.state = .stopped
        completion(.success(()))
        #endif
    }

    // MARK: - Hardware Configuration Builder

    #if canImport(Virtualization)
    private func buildVZConfiguration() throws -> VZVirtualMachineConfiguration {
        let vz = VZVirtualMachineConfiguration()

        // 1. CPU & Memory
        vz.cpuCount = config.cpuCount
        vz.memorySize = config.memorySizeMB * 1024 * 1024

        // 2. Platform Configuration (Generic platform for Linux & UEFI guest OS)
        let platform = VZGenericPlatformConfiguration()
        vz.platform = platform

        // 3. Bootloader (EFI bootloader with persistent NVRAM if supported)
        let bootloader = VZEFIBootLoader()
        vz.bootLoader = bootloader

        // 4. Storage (Primary Virtual Disk)
        let diskURL = URL(fileURLWithPath: config.diskImagePath)
        guard FileManager.default.fileExists(atPath: diskURL.path) else {
            throw EngineError.diskFileNotFound(diskURL.path)
        }

        let diskAttachment = try VZDiskImageStorageDeviceAttachment(
            url: diskURL,
            readOnly: false
        )
        let mainStorageDevice = VZVirtioBlockDeviceConfiguration(attachment: diskAttachment)
        var storageDevices: [VZStorageDeviceConfiguration] = [mainStorageDevice]

        // Optional: Mount ISO image as CD-ROM/read-only drive
        if let isoPath = config.isoPath, !isoPath.isEmpty {
            let isoURL = URL(fileURLWithPath: isoPath)
            if FileManager.default.fileExists(atPath: isoURL.path) {
                let isoAttachment = try VZDiskImageStorageDeviceAttachment(
                    url: isoURL,
                    readOnly: true
                )
                let cdromDevice = VZVirtioBlockDeviceConfiguration(attachment: isoAttachment)
                storageDevices.append(cdromDevice)
            }
        }
        vz.storageDevices = storageDevices

        // 5. Network (Virtio NAT Network Adapter with internet sharing)
        let networkDevice = VZVirtioNetworkDeviceConfiguration()
        networkDevice.attachment = VZNATNetworkDeviceAttachment()
        vz.networkDevices = [networkDevice]

        // 6. Graphics Display (High-performance GPU scanout)
        let graphics = VZVirtioGraphicsDeviceConfiguration()
        let scanout = VZVirtioGraphicsScanoutConfiguration(
            widthInPixels: config.displayWidth,
            heightInPixels: config.displayHeight
        )
        graphics.scanouts = [scanout]
        vz.graphicsDevices = [graphics]

        // 7. Input Devices (Pointing & Keyboard)
        let pointingDevice = VZUSBScreenCoordinatePointingDeviceConfiguration()
        let keyboardDevice = VZUSBKeyboardConfiguration()
        vz.pointingDevices = [pointingDevice]
        vz.keyboards = [keyboardDevice]

        // 8. Audio Devices (Output stream)
        let soundDevice = VZVirtioSoundDeviceConfiguration()
        let outputStream = VZVirtioSoundDeviceOutputStreamConfiguration()
        outputStream.sink = VZHostAudioOutputStreamSink()
        soundDevice.streams = [outputStream]
        vz.audioDevices = [soundDevice]

        // 9. Entropy (Random number generator for guest OS security)
        vz.entropyDevices = [VZVirtioEntropyDeviceConfiguration()]

        // 10. Memory Balloon (Dynamic RAM allocation & reclaim)
        vz.memoryBalloonDevices = [VZVirtioTraditionalMemoryBalloonDeviceConfiguration()]

        // 11. Shared Directory (VirtioFS for native high-speed folder sharing)
        if let sharedFolder = config.sharedFolderPath, !sharedFolder.isEmpty {
            let sharedFolderURL = URL(fileURLWithPath: sharedFolder)
            if FileManager.default.fileExists(atPath: sharedFolderURL.path) {
                let sharedDir = VZSharedDirectory(url: sharedFolderURL, readOnly: false)
                let singleShare = VZSingleDirectoryShare(directory: sharedDir)
                let fsConfig = VZVirtioFileSystemDeviceConfiguration(tag: "macOS_Share")
                fsConfig.share = singleShare
                vz.directorySharingDevices = [fsConfig]
            }
        }

        return vz
    }
    #endif
}

// MARK: - VZVirtualMachineDelegate
#if canImport(Virtualization)
extension VirtualMachineEngine: VZVirtualMachineDelegate {
    public func guestDidStop(_ virtualMachine: VZVirtualMachine) {
        DispatchQueue.main.async {
            self.state = .stopped
            self.vzVM = nil
        }
    }

    public func virtualMachine(_ virtualMachine: VZVirtualMachine, didStopWithError error: Error) {
        DispatchQueue.main.async {
            let errorMsg = error.localizedDescription
            self.errorMessage = errorMsg
            self.state = .error(message: errorMsg)
            self.vzVM = nil
        }
    }
}
#endif

// MARK: - Engine Errors
public enum EngineError: LocalizedError, Equatable {
    case invalidStateTransition(String)
    case machineNotInitialized
    case diskFileNotFound(String)

    public var errorDescription: String? {
        switch self {
        case .invalidStateTransition(let msg):
            return "Invalid VM state transition: \(msg)"
        case .machineNotInitialized:
            return "Virtual machine hypervisor instance is not active."
        case .diskFileNotFound(let path):
            return "Virtual disk file does not exist at path: \(path)"
        }
    }
}
