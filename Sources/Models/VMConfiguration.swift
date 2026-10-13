import Foundation

/// Persistent configuration model representing a single virtual machine instance.
public struct VMConfiguration: Identifiable, Codable, Equatable {
    public var id: UUID
    public var name: String
    public var osType: OSType
    public var cpuCount: Int
    public var memorySizeMB: UInt64
    public var diskSizeBytes: UInt64
    public var diskImagePath: String
    public var isoPath: String?
    public var sharedFolderPath: String?
    public var enableRosetta: Bool
    public var displayWidth: Int
    public var displayHeight: Int
    public var displayDPI: Int
    public var createdAt: Date
    public var lastRunAt: Date?

    public init(
        id: UUID = UUID(),
        name: String,
        osType: OSType,
        cpuCount: Int,
        memorySizeMB: UInt64,
        diskSizeBytes: UInt64,
        diskImagePath: String,
        isoPath: String? = nil,
        sharedFolderPath: String? = nil,
        enableRosetta: Bool = false,
        displayWidth: Int = 1920,
        displayHeight: Int = 1080,
        displayDPI: Int = 144,
        createdAt: Date = Date(),
        lastRunAt: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.osType = osType
        self.cpuCount = cpuCount
        self.memorySizeMB = memorySizeMB
        self.diskSizeBytes = diskSizeBytes
        self.diskImagePath = diskImagePath
        self.isoPath = isoPath
        self.sharedFolderPath = sharedFolderPath
        self.enableRosetta = enableRosetta
        self.displayWidth = displayWidth
        self.displayHeight = displayHeight
        self.displayDPI = displayDPI
        self.createdAt = createdAt
        self.lastRunAt = lastRunAt
    }

    /// Validates configuration parameters to avoid runtime crashes or invalid hypervisor arguments.
    public func validate() -> Result<Void, VMValidationError> {
        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return .failure(.invalidName)
        }
        if cpuCount < 1 || cpuCount > ProcessInfo.processInfo.activeProcessorCount {
            return .failure(.invalidCpuCount(min: 1, max: ProcessInfo.processInfo.activeProcessorCount))
        }
        let minRamMB: UInt64 = 1024 // 1GB minimum
        let maxRamBytes = ProcessInfo.processInfo.physicalMemory
        let maxRamMB = maxRamBytes / (1024 * 1024)
        if memorySizeMB < minRamMB || memorySizeMB > maxRamMB {
            return .failure(.invalidMemory(minMB: minRamMB, maxMB: maxRamMB))
        }
        if diskSizeBytes < 1024 * 1024 * 1024 { // Minimum 1GB
            return .failure(.invalidDiskSize)
        }
        return .success(())
    }
}

public enum VMValidationError: LocalizedError, Equatable {
    case invalidName
    case invalidCpuCount(min: Int, max: Int)
    case invalidMemory(minMB: UInt64, maxMB: UInt64)
    case invalidDiskSize
    case missingDiskFile(path: String)
    case missingIsoFile(path: String)

    public var errorDescription: String? {
        switch self {
        case .invalidName:
            return "Virtual Machine name cannot be empty."
        case .invalidCpuCount(let min, let max):
            return "CPU core count must be between \(min) and \(max)."
        case .invalidMemory(let minMB, let maxMB):
            return "Memory must be between \(minMB) MB and \(maxMB) MB."
        case .invalidDiskSize:
            return "Disk size must be at least 1 GB."
        case .missingDiskFile(let path):
            return "Virtual disk file not found at path: \(path)"
        case .missingIsoFile(let path):
            return "Installer ISO file not found at path: \(path)"
        }
    }
}
