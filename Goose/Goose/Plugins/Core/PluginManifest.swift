//
//  PluginManifest.swift
//  Goose
//
//  Created by Goose on 15/09/2025.
//

import Foundation

/// Represents the manifest file for a plugin
public struct PluginManifest: Codable {
    /// Unique identifier for the plugin (e.g., "com.example.myplugin")
    public let identifier: String
    
    /// Human-readable name for the plugin
    public let name: String
    
    /// Semantic version of the plugin (e.g., "1.0.0")
    public let version: String
    
    /// Minimum app version required
    public let minAppVersion: String
    
    /// Maximum app version supported (optional)
    public let maxAppVersion: String?
    
    /// Author or organization
    public let author: String
    
    /// Brief description
    public let description: String
    
    /// Plugin capabilities
    public let capabilities: [String]
    
    /// Entry point class name
    public let entryPoint: String
    
    /// Dependencies on other plugins
    public let dependencies: [PluginDependency]
    
    /// Resources required by the plugin
    public let resources: PluginResources?
    
    /// Plugin permissions
    public let permissions: [PluginPermission]?
    
    /// Plugin homepage URL
    public let homepage: String?
    
    /// Plugin documentation URL
    public let documentationURL: String?
    
    /// Plugin license
    public let license: String?
    
    /// Plugin icon filename
    public let icon: String?
    
    /// Plugin categories for organization
    public let categories: [String]?
    
    /// Custom configuration options
    public let configuration: [String: AnyCodable]?
    
    // MARK: - Validation
    
    /// Validate the manifest
    /// - Throws: PluginError if validation fails
    public func validate() throws {
        // Validate identifier format
        guard isValidIdentifier(identifier) else {
            throw PluginError.invalidManifest("Invalid identifier format: \(identifier)")
        }
        
        // Validate version format
        guard isValidVersion(version) else {
            throw PluginError.invalidManifest("Invalid version format: \(version)")
        }
        
        // Validate min app version
        guard isValidVersion(minAppVersion) else {
            throw PluginError.invalidManifest("Invalid minAppVersion format: \(minAppVersion)")
        }
        
        // Validate max app version if present
        if let maxVersion = maxAppVersion {
            guard isValidVersion(maxVersion) else {
                throw PluginError.invalidManifest("Invalid maxAppVersion format: \(maxVersion)")
            }
        }
        
        // Validate capabilities
        for capability in capabilities {
            guard PluginCapability(rawValue: capability) != nil else {
                throw PluginError.invalidManifest("Unknown capability: \(capability)")
            }
        }
        
        // Validate entry point
        guard !entryPoint.isEmpty else {
            throw PluginError.invalidManifest("Entry point cannot be empty")
        }
    }
    
    /// Check if the manifest is compatible with the current app version
    /// - Parameter appVersion: The current app version
    /// - Returns: True if compatible
    public func isCompatible(withAppVersion appVersion: String) -> Bool {
        guard let currentVersion = SemanticVersion(appVersion),
              let minVersion = SemanticVersion(minAppVersion) else {
            return false
        }
        
        // Check minimum version
        guard currentVersion >= minVersion else {
            return false
        }
        
        // Check maximum version if specified
        if let maxVersionString = maxAppVersion,
           let maxVersion = SemanticVersion(maxVersionString) {
            guard currentVersion <= maxVersion else {
                return false
            }
        }
        
        return true
    }
    
    // MARK: - Private Helpers
    
    private func isValidIdentifier(_ identifier: String) -> Bool {
        // Identifier should be reverse domain format
        let pattern = #"^[a-z][a-z0-9]*(\.[a-z][a-z0-9]*)+$"#
        let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive)
        let range = NSRange(location: 0, length: identifier.utf16.count)
        return regex?.firstMatch(in: identifier, options: [], range: range) != nil
    }
    
    private func isValidVersion(_ version: String) -> Bool {
        return SemanticVersion(version) != nil
    }
}

// MARK: - Plugin Dependency

/// Represents a dependency on another plugin
public struct PluginDependency: Codable {
    /// Identifier of the required plugin
    public let identifier: String
    
    /// Minimum version required
    public let minVersion: String?
    
    /// Maximum version allowed
    public let maxVersion: String?
    
    /// Whether the dependency is optional
    public let optional: Bool
    
    public init(
        identifier: String,
        minVersion: String? = nil,
        maxVersion: String? = nil,
        optional: Bool = false
    ) {
        self.identifier = identifier
        self.minVersion = minVersion
        self.maxVersion = maxVersion
        self.optional = optional
    }
}

// MARK: - Plugin Resources

/// Resources required by the plugin
public struct PluginResources: Codable {
    /// Bundle resources
    public let bundles: [String]?
    
    /// Asset catalogs
    public let assetCatalogs: [String]?
    
    /// Storyboards
    public let storyboards: [String]?
    
    /// XIB files
    public let xibs: [String]?
    
    /// Localization files
    public let localizations: [String]?
    
    /// Other resource files
    public let other: [String]?
}

// MARK: - Plugin Permission

/// Permissions required by the plugin
public enum PluginPermission: String, Codable {
    case fileSystem = "fileSystem"
    case network = "network"
    case notifications = "notifications"
    case calendar = "calendar"
    case contacts = "contacts"
    case location = "location"
    case camera = "camera"
    case microphone = "microphone"
    case photos = "photos"
    case reminders = "reminders"
}

// MARK: - Semantic Version

/// Simple semantic version parser
struct SemanticVersion: Comparable {
    let major: Int
    let minor: Int
    let patch: Int
    let prerelease: String?
    let build: String?
    
    init?(_ string: String) {
        // Parse semantic version string (e.g., "1.2.3-beta+001")
        let pattern = #"^(\d+)\.(\d+)\.(\d+)(?:-([A-Za-z0-9.-]+))?(?:\+([A-Za-z0-9.-]+))?$"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        
        let range = NSRange(location: 0, length: string.utf16.count)
        guard let match = regex.firstMatch(in: string, range: range) else { return nil }
        
        guard let majorRange = Range(match.range(at: 1), in: string),
              let major = Int(string[majorRange]),
              let minorRange = Range(match.range(at: 2), in: string),
              let minor = Int(string[minorRange]),
              let patchRange = Range(match.range(at: 3), in: string),
              let patch = Int(string[patchRange]) else { return nil }
        
        self.major = major
        self.minor = minor
        self.patch = patch
        
        if let prereleaseRange = Range(match.range(at: 4), in: string) {
            self.prerelease = String(string[prereleaseRange])
        } else {
            self.prerelease = nil
        }
        
        if let buildRange = Range(match.range(at: 5), in: string) {
            self.build = String(string[buildRange])
        } else {
            self.build = nil
        }
    }
    
    static func < (lhs: SemanticVersion, rhs: SemanticVersion) -> Bool {
        if lhs.major != rhs.major { return lhs.major < rhs.major }
        if lhs.minor != rhs.minor { return lhs.minor < rhs.minor }
        if lhs.patch != rhs.patch { return lhs.patch < rhs.patch }
        
        // Pre-release versions have lower precedence
        if lhs.prerelease != nil && rhs.prerelease == nil { return true }
        if lhs.prerelease == nil && rhs.prerelease != nil { return false }
        
        // Compare pre-release versions lexically
        if let lhsPre = lhs.prerelease, let rhsPre = rhs.prerelease {
            return lhsPre < rhsPre
        }
        
        return false
    }
    
    static func == (lhs: SemanticVersion, rhs: SemanticVersion) -> Bool {
        return lhs.major == rhs.major &&
               lhs.minor == rhs.minor &&
               lhs.patch == rhs.patch &&
               lhs.prerelease == rhs.prerelease
    }
}

// MARK: - AnyCodable

/// Type-erased Codable value for custom configuration
public struct AnyCodable: Codable {
    public let value: Any
    
    public init(_ value: Any) {
        self.value = value
    }
    
    public init(from decoder: Decoder) throws {
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
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Unable to decode value"
            )
        }
    }
    
    public func encode(to encoder: Encoder) throws {
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
            throw EncodingError.invalidValue(
                value,
                EncodingError.Context(
                    codingPath: encoder.codingPath,
                    debugDescription: "Unable to encode value"
                )
            )
        }
    }
}
