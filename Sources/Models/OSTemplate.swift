import Foundation

/// Supported Operating System categories and presets
public enum OSType: String, CaseIterable, Identifiable, Codable {
    case ubuntu = "Ubuntu Linux"
    case debian = "Debian Linux"
    case fedora = "Fedora Linux"
    case arch = "Arch Linux"
    case windowsARM = "Windows 11 ARM"
    case macOS = "macOS"
    case genericLinux = "Other Linux (ISO)"

    public var id: String { rawValue }

    public var systemSymbolName: String {
        switch self {
        case .ubuntu, .debian, .fedora, .arch, .genericLinux:
            return "terminal.fill"
        case .windowsARM:
            return "window.vertical.closed"
        case .macOS:
            return "apple.logo"
        }
    }

    public var defaultCpuCount: Int {
        switch self {
        case .windowsARM, .macOS:
            return 4
        default:
            return 2
        }
    }

    public var defaultMemoryMB: UInt64 {
        switch self {
        case .windowsARM:
            return 8 * 1024 // 8 GB
        case .macOS:
            return 8 * 1024 // 8 GB
        default:
            return 4 * 1024 // 4 GB
        }
    }

    public var defaultDiskGB: UInt64 {
        switch self {
        case .windowsARM:
            return 64 // 64 GB
        case .macOS:
            return 64 // 64 GB
        default:
            return 25 // 25 GB
        }
    }

    public var suggestedIsoDownloadUrl: String? {
        switch self {
        case .ubuntu:
            return "https://ubuntu.com/download/server/arm"
        case .debian:
            return "https://www.debian.org/distrib/"
        case .fedora:
            return "https://getfedora.org/"
        case .windowsARM:
            return "https://www.microsoft.com/en-us/software-download/windows11arm64"
        default:
            return nil
        }
    }
}
