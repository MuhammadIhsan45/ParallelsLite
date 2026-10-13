import Foundation

/// Service responsible for managing virtual disk files, creating sparse disks, and checking free space.
public final class DiskManager {
    public static let shared = DiskManager()

    private init() {}

    /// Base directory where VM virtual disks and configurations are stored.
    public var defaultVMStorageURL: URL {
        let fileManager = FileManager.default
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Library/Application Support")
        let vmDir = appSupport.appendingPathComponent("ParallelsLite/VirtualMachines", isDirectory: true)

        if !fileManager.fileExists(atPath: vmDir.path) {
            try? fileManager.createDirectory(at: vmDir, withIntermediateDirectories: true, attributes: nil)
        }
        return vmDir
    }

    /// Creates a sparse disk image file of the specified size in bytes.
    /// Sparse files only consume actual storage on disk as data is written.
    public func createSparseDisk(at url: URL, sizeInBytes: UInt64) -> Result<URL, DiskError> {
        let fileManager = FileManager.default
        let parentDir = url.deletingLastPathComponent()

        do {
            if !fileManager.fileExists(atPath: parentDir.path) {
                try fileManager.createDirectory(at: parentDir, withIntermediateDirectories: true)
            }
        } catch {
            return .failure(.directoryCreationFailed(error.localizedDescription))
        }

        // If file already exists, avoid accidentally overwriting it
        if fileManager.fileExists(atPath: url.path) {
            return .failure(.fileAlreadyExists(url.path))
        }

        // Create empty file
        guard fileManager.createFile(atPath: url.path, contents: nil, attributes: nil) else {
            return .failure(.fileCreationFailed)
        }

        // Allocate sparse size using FileHandle truncation
        do {
            let fileHandle = try FileHandle(forWritingTo: url)
            defer {
                try? fileHandle.close()
            }
            try fileHandle.truncate(atOffset: sizeInBytes)
            return .success(url)
        } catch {
            // Clean up the created empty file if truncation failed
            try? fileManager.removeItem(at: url)
            return .failure(.truncationFailed(error.localizedDescription))
        }
    }

    /// Deletes a virtual disk file safely.
    public func deleteDisk(at url: URL) -> Result<Void, DiskError> {
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: url.path) else {
            return .success(()) // Already gone
        }
        do {
            try fileManager.removeItem(at: url)
            return .success(())
        } catch {
            return .failure(.deletionFailed(error.localizedDescription))
        }
    }
}

public enum DiskError: LocalizedError, Equatable {
    case fileAlreadyExists(String)
    case directoryCreationFailed(String)
    case fileCreationFailed
    case truncationFailed(String)
    case deletionFailed(String)

    public var errorDescription: String? {
        switch self {
        case .fileAlreadyExists(let path):
            return "A disk file already exists at: \(path)"
        case .directoryCreationFailed(let msg):
            return "Failed to create directory: \(msg)"
        case .fileCreationFailed:
            return "Failed to initialize new disk file."
        case .truncationFailed(let msg):
            return "Failed to allocate disk capacity: \(msg)"
        case .deletionFailed(let msg):
            return "Failed to delete disk: \(msg)"
        }
    }
}
