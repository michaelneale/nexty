//
//  Plugin.swift
//  Goose
//
//  Created by Goose on 15/09/2025.
//

import Foundation
import Combine

/// Base protocol that all plugins must conform to
public protocol Plugin: AnyObject {
    // MARK: - Metadata
    
    /// Unique identifier for the plugin (e.g., "com.example.myplugin")
    var identifier: String { get }
    
    /// Human-readable name for the plugin
    var name: String { get }
    
    /// Semantic version of the plugin (e.g., "1.0.0")
    var version: String { get }
    
    /// Author or organization that created the plugin
    var author: String { get }
    
    /// Brief description of what the plugin does
    var description: String { get }
    
    /// Set of capabilities that this plugin provides
    var capabilities: Set<PluginCapability> { get }
    
    // MARK: - State
    
    /// Current state of the plugin
    var state: PluginState { get }
    
    // MARK: - Dependencies
    
    /// List of other plugin identifiers that this plugin depends on
    var dependencies: [String] { get }
    
    // MARK: - Lifecycle Methods
    
    /// Initialize the plugin with the provided context
    /// - Parameter context: The plugin context providing access to app services
    /// - Throws: PluginError if initialization fails
    func initialize(context: PluginContext) throws
    
    /// Called when the plugin is activated (enabled)
    /// - Throws: PluginError if activation fails
    func activate() throws
    
    /// Called when the plugin is deactivated (disabled)
    func deactivate()
    
    /// Called before the plugin is removed from memory
    /// Use this to clean up resources, cancel subscriptions, etc.
    func cleanup()
}

/// Represents the current state of a plugin
public enum PluginState: Equatable {
    /// Plugin is loaded but not yet initialized
    case loaded
    
    /// Plugin is initialized but not active
    case initialized
    
    /// Plugin is currently active and running
    case active
    
    /// Plugin is deactivated
    case inactive
    
    /// Plugin encountered an error
    case error(Error)
    
    public static func == (lhs: PluginState, rhs: PluginState) -> Bool {
        switch (lhs, rhs) {
        case (.loaded, .loaded),
             (.initialized, .initialized),
             (.active, .active),
             (.inactive, .inactive):
            return true
        case (.error, .error):
            // For simplicity, consider all errors equal
            // In a real implementation, you might want to compare error details
            return true
        default:
            return false
        }
    }
}

/// Errors that can occur during plugin operations
public enum PluginError: LocalizedError {
    case initializationFailed(String)
    case activationFailed(String)
    case missingDependency(String)
    case incompatibleVersion(String)
    case invalidManifest(String)
    case contextNotSet
    case alreadyActive
    case notActive
    
    public var errorDescription: String? {
        switch self {
        case .initializationFailed(let reason):
            return "Plugin initialization failed: \(reason)"
        case .activationFailed(let reason):
            return "Plugin activation failed: \(reason)"
        case .missingDependency(let dependency):
            return "Missing required dependency: \(dependency)"
        case .incompatibleVersion(let version):
            return "Incompatible plugin version: \(version)"
        case .invalidManifest(let reason):
            return "Invalid plugin manifest: \(reason)"
        case .contextNotSet:
            return "Plugin context not set"
        case .alreadyActive:
            return "Plugin is already active"
        case .notActive:
            return "Plugin is not active"
        }
    }
}

/// Base implementation of Plugin protocol with common functionality
open class BasePlugin: Plugin {
    // MARK: - Metadata
    
    public let identifier: String
    public let name: String
    public let version: String
    public let author: String
    public let description: String
    public let capabilities: Set<PluginCapability>
    public let dependencies: [String]
    
    // MARK: - State
    
    public private(set) var state: PluginState = .loaded
    
    // MARK: - Context
    
    public private(set) var context: PluginContext?
    
    // MARK: - Initialization
    
    public init(
        identifier: String,
        name: String,
        version: String,
        author: String,
        description: String,
        capabilities: Set<PluginCapability> = [],
        dependencies: [String] = []
    ) {
        self.identifier = identifier
        self.name = name
        self.version = version
        self.author = author
        self.description = description
        self.capabilities = capabilities
        self.dependencies = dependencies
    }
    
    // MARK: - Lifecycle Methods
    
    open func initialize(context: PluginContext) throws {
        guard self.context == nil else {
            throw PluginError.initializationFailed("Plugin already initialized")
        }
        self.context = context
        self.state = .initialized
    }
    
    open func activate() throws {
        guard state == .initialized || state == .inactive else {
            if state == .active {
                throw PluginError.alreadyActive
            }
            throw PluginError.activationFailed("Plugin must be initialized before activation")
        }
        state = .active
    }
    
    open func deactivate() {
        guard state == .active else { return }
        state = .inactive
    }
    
    open func cleanup() {
        deactivate()
        context = nil
        state = .loaded
    }
}
