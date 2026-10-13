import Foundation

/// Represents the runtime lifecycle state of a Virtual Machine.
public enum VMState: Equatable, Codable {
    case stopped
    case starting
    case running
    case paused
    case stopping
    case error(message: String)

    public var title: String {
        switch self {
        case .stopped:
            return "Stopped"
        case .starting:
            return "Starting..."
        case .running:
            return "Running"
        case .paused:
            return "Paused"
        case .stopping:
            return "Stopping..."
        case .error(let message):
            return "Error: \(message)"
        }
    }

    public var isOperational: Bool {
        switch self {
        case .running, .paused:
            return true
        default:
            return false
        }
    }

    public var canStart: Bool {
        switch self {
        case .stopped, .error:
            return true
        default:
            return false
        }
    }

    public var canPause: Bool {
        self == .running
    }

    public var canResume: Bool {
        self == .paused
    }

    public var canStop: Bool {
        switch self {
        case .running, .paused:
            return true
        default:
            return false
        }
    }
}
