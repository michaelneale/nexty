import Foundation

/// Represents a goose CLI command
public struct GooseCommand: Identifiable, Codable, Equatable, Hashable {
    public let id: UUID
    public let command: String
    public let arguments: [String]
    public let timestamp: Date
    public var status: CommandStatus
    
    public init(command: String, arguments: [String] = []) {
        self.id = UUID()
        self.command = command
        self.arguments = arguments
        self.timestamp = Date()
        self.status = .pending
    }
    
    /// Full command string including arguments
    public var fullCommand: String {
        ([command] + arguments).joined(separator: " ")
    }
}

/// Status of a command execution
public enum CommandStatus: String, Codable {
    case pending
    case running
    case completed
    case failed
    case cancelled
}

/// Response from goose CLI
public struct GooseResponse: Identifiable {
    public let id: UUID = UUID()
    public let commandId: UUID
    public let content: String
    public let type: ResponseType
    public let timestamp: Date
    
    public init(commandId: UUID, content: String, type: ResponseType) {
        self.commandId = commandId
        self.content = content
        self.type = type
        self.timestamp = Date()
    }
}

/// Type of response output
public enum ResponseType {
    case stdout
    case stderr
    case system
}

/// Error types for CLI operations
public enum GooseCliError: LocalizedError {
    case cliNotFound
    case permissionDenied
    case executionFailed(String)
    case timeout
    case cancelled
    
    public var errorDescription: String? {
        switch self {
        case .cliNotFound:
            return "Goose CLI not found. Please ensure it's installed and accessible."
        case .permissionDenied:
            return "Permission denied. Please check file permissions."
        case .executionFailed(let message):
            return "Execution failed: \(message)"
        case .timeout:
            return "Command execution timed out."
        case .cancelled:
            return "Command was cancelled."
        }
    }
}
