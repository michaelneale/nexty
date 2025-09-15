//
//  GooseConfiguration.swift
//  Goose
//
//  Created on 2024-09-15
//

import Foundation

// MARK: - Configuration Models

struct GooseConfiguration: Codable {
    let provider: ProviderConfig?
    let profiles: [String: ProfileConfig]?
    let extensions: [String: ExtensionConfig]?
    
    enum CodingKeys: String, CodingKey {
        case provider
        case profiles
        case extensions
    }
}

struct ProviderConfig: Codable {
    let name: String?
    let model: String?
    let temperature: Double?
    let apiKey: String?
    
    enum CodingKeys: String, CodingKey {
        case name
        case model
        case temperature
        case apiKey = "api_key"
    }
}

struct ProfileConfig: Codable {
    let provider: String?
    let processor: String?
    let accelerator: String?
    let moderator: String?
}

struct ExtensionConfig: Codable {
    let enabled: Bool?
    let type: String?
    let name: String?
    let description: String?
    let commands: [String: CommandConfig]?
    let environment: [String: String]?
    let configuration: [String: Any]?
    
    enum CodingKeys: String, CodingKey {
        case enabled
        case type
        case name
        case description
        case commands
        case environment
        case configuration
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        enabled = try container.decodeIfPresent(Bool.self, forKey: .enabled)
        type = try container.decodeIfPresent(String.self, forKey: .type)
        name = try container.decodeIfPresent(String.self, forKey: .name)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        commands = try container.decodeIfPresent([String: CommandConfig].self, forKey: .commands)
        environment = try container.decodeIfPresent([String: String].self, forKey: .environment)
        
        // Handle dynamic configuration as dictionary
        if let configContainer = try? container.decode([String: AnyCodable].self, forKey: .configuration) {
            configuration = configContainer.mapValues { $0.value }
        } else {
            configuration = nil
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(enabled, forKey: .enabled)
        try container.encodeIfPresent(type, forKey: .type)
        try container.encodeIfPresent(name, forKey: .name)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encodeIfPresent(commands, forKey: .commands)
        try container.encodeIfPresent(environment, forKey: .environment)
        
        if let config = configuration {
            let anyCodable = config.mapValues { AnyCodable($0) }
            try container.encode(anyCodable, forKey: .configuration)
        }
    }
}

struct CommandConfig: Codable {
    let description: String?
    let args: String?
}

// MARK: - Helper for decoding any type

struct AnyCodable: Codable {
    let value: Any
    
    init(_ value: Any) {
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let string = try? container.decode(String.self) {
            value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map { $0.value }
        } else if let dictionary = try? container.decode([String: AnyCodable].self) {
            value = dictionary.mapValues { $0.value }
        } else {
            value = NSNull()
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch value {
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let array as [Any]:
            try container.encode(array.map { AnyCodable($0) })
        case let dictionary as [String: Any]:
            try container.encode(dictionary.mapValues { AnyCodable($0) })
        default:
            try container.encodeNil()
        }
    }
}

// MARK: - Configuration Section

enum ConfigSection: String, CaseIterable {
    case provider = "Provider"
    case profiles = "Profiles"
    case extensions = "Extensions"
    
    var icon: String {
        switch self {
        case .provider:
            return "server.rack"
        case .profiles:
            return "person.2.circle"
        case .extensions:
            return "puzzlepiece.extension"
        }
    }
}
