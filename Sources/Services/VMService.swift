import Foundation
import Combine

/// Central coordinator for VM management, state persistence, and lifecycle orchestration.
@MainActor
public final class VMService: ObservableObject {
    public static let shared = VMService()

    @Published public var vms: [VMConfiguration] = []
    @Published public var selectedVMId: UUID? = nil
    @Published public var engines: [UUID: VirtualMachineEngine] = [:]
    @Published public var isShowingCreateSheet: Bool = false
    @Published public var isShowingSettingsSheet: Bool = false
    @Published public var alertMessage: String? = nil

    private let persistenceURL: URL

    public init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Library/Application Support")
        let dir = appSupport.appendingPathComponent("ParallelsLite", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        self.persistenceURL = dir.appendingPathComponent("vms.json")

        loadVMs()

        if vms.isEmpty {
            createDemoTemplateIfEmpty()
        }

        if let first = vms.first {
            selectedVMId = first.id
        }
    }

    public var selectedVM: VMConfiguration? {
        guard let id = selectedVMId else { return vms.first }
        return vms.first(where: { $0.id == id })
    }

    public func engine(for id: UUID) -> VirtualMachineEngine {
        if let existing = engines[id] {
            return existing
        }
        guard let config = vms.first(where: { $0.id == id }) else {
            fatalError("Engine requested for non-existent VM ID")
        }
        let newEngine = VirtualMachineEngine(config: config)
        engines[id] = newEngine
        return newEngine
    }

    // MARK: - CRUD Operations

    public func createVM(
        name: String,
        osType: OSType,
        cpuCount: Int,
        memoryMB: UInt64,
        diskGB: UInt64,
        isoPath: String?,
        sharedFolderPath: String?,
        enableRosetta: Bool
    ) -> Result<VMConfiguration, Error> {
        let storageDir = DiskManager.shared.defaultVMStorageURL
        let vmFolder = storageDir.appendingPathComponent(UUID().uuidString, isDirectory: true)
        let diskURL = vmFolder.appendingPathComponent("disk.img")

        let diskSizeBytes = diskGB * 1024 * 1024 * 1024

        // 1. Create sparse disk image
        let diskResult = DiskManager.shared.createSparseDisk(at: diskURL, sizeInBytes: diskSizeBytes)
        switch diskResult {
        case .failure(let err):
            return .failure(err)
        case .success:
            break
        }

        // 2. Build configuration
        var config = VMConfiguration(
            name: name,
            osType: osType,
            cpuCount: cpuCount,
            memorySizeMB: memoryMB,
            diskSizeBytes: diskSizeBytes,
            diskImagePath: diskURL.path,
            isoPath: isoPath,
            sharedFolderPath: sharedFolderPath,
            enableRosetta: enableRosetta
        )

        // 3. Validate
        if case .failure(let valErr) = config.validate() {
            _ = DiskManager.shared.deleteDisk(at: diskURL)
            return .failure(valErr)
        }

        vms.append(config)
        selectedVMId = config.id
        saveVMs()
        return .success(config)
    }

    public func updateVM(_ config: VMConfiguration) {
        guard let index = vms.firstIndex(where: { $0.id == config.id }) else { return }
        vms[index] = config
        // Reset engine so new config takes effect next boot
        engines.removeValue(forKey: config.id)
        saveVMs()
    }

    public func deleteVM(id: UUID) {
        guard let index = vms.firstIndex(where: { $0.id == id }) else { return }
        let vm = vms[index]

        // Stop running engine if active
        if let engine = engines[id], engine.state.canStop {
            engine.forceStop { _ in }
        }
        engines.removeValue(forKey: id)

        // Delete disk
        let diskURL = URL(fileURLWithPath: vm.diskImagePath)
        _ = DiskManager.shared.deleteDisk(at: diskURL)
        let vmFolder = diskURL.deletingLastPathComponent()
        try? FileManager.default.removeItem(at: vmFolder)

        vms.remove(at: index)
        if selectedVMId == id {
            selectedVMId = vms.first?.id
        }
        saveVMs()
    }

    // MARK: - Persistence

    private func saveVMs() {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(vms)
            try data.write(to: persistenceURL, options: .atomic)
        } catch {
            print("[VMService] Failed to save VMs: \(error)")
        }
    }

    private func loadVMs() {
        guard FileManager.default.fileExists(atPath: persistenceURL.path) else { return }
        do {
            let data = try Data(contentsOf: persistenceURL)
            let decoder = JSONDecoder()
            self.vms = try decoder.decode([VMConfiguration].self, from: data)
        } catch {
            print("[VMService] Failed to load VMs: \(error)")
        }
    }

    private func createDemoTemplateIfEmpty() {
        let storageDir = DiskManager.shared.defaultVMStorageURL
        let demoFolder = storageDir.appendingPathComponent("ubuntu-demo", isDirectory: true)
        let demoDisk = demoFolder.appendingPathComponent("disk.img")

        // Create initial sparse disk if not present
        if !FileManager.default.fileExists(atPath: demoDisk.path) {
            _ = DiskManager.shared.createSparseDisk(at: demoDisk, sizeInBytes: 25 * 1024 * 1024 * 1024)
        }

        let demoVM = VMConfiguration(
            name: "Ubuntu 24.04 LTS (Demo)",
            osType: .ubuntu,
            cpuCount: 4,
            memorySizeMB: 4096,
            diskSizeBytes: 25 * 1024 * 1024 * 1024,
            diskImagePath: demoDisk.path,
            isoPath: nil,
            sharedFolderPath: NSHomeDirectory(),
            enableRosetta: true
        )

        self.vms = [demoVM]
        self.selectedVMId = demoVM.id
        saveVMs()
    }
}
