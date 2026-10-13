import Foundation

public struct SystemInfo {
    public static var totalHostMemoryMB: UInt64 {
        ProcessInfo.processInfo.physicalMemory / (1024 * 1024)
    }

    public static var totalHostMemoryGB: Double {
        Double(ProcessInfo.processInfo.physicalMemory) / (1024 * 1024 * 1024)
    }

    public static var hostCpuCores: Int {
        ProcessInfo.processInfo.activeProcessorCount
    }

    public static var isAppleSilicon: Bool {
        #if arch(arm64)
        return true
        #else
        return false
        #endif
    }

    public static var recommendedCpuCount: Int {
        max(1, min(4, hostCpuCores / 2))
    }

    public static var recommendedMemoryMB: UInt64 {
        let halfMemory = totalHostMemoryMB / 2
        return max(2048, min(8192, halfMemory))
    }
}
