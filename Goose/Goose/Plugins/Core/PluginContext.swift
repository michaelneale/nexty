//
//  PluginContext.swift
//  Goose
//
//  Created by Goose on 15/09/2025.
//

import Foundation
import Combine
import SwiftUI

/// Provides controlled access to app services for plugins
public class PluginContext {
    // MARK: - Properties
    
    /// The plugin that owns this context
    public let pluginIdentifier: String
    
    /// Command execution interface
    public let commandInterface: CommandInterface
    
    /// Settings storage scoped to the plugin
    public let settings: PluginSettingsStorage
    
    /// Event bus for publishing and subscribing to events
    public let eventBus: PluginEventBus
    
    /// Logger for the plugin
    public let logger: PluginLogger
    
    /// UI registration points
    public let uiRegistry: UIRegistry
    
    /// Access to app resources
    public let resources: ResourceAccess
    
    // MARK: - Private Properties
    
    private let pluginManager: PluginManager
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(
        pluginIdentifier: String,
        pluginManager: PluginManager
    ) {
        self.pluginIdentifier = pluginIdentifier
        self.pluginManager = pluginManager
        
        // Initialize scoped services
        self.commandInterface = CommandInterface(pluginIdentifier: pluginIdentifier)
        self.settings = PluginSettingsStorage(pluginIdentifier: pluginIdentifier)
        self.eventBus = PluginEventBus(pluginIdentifier: pluginIdentifier)
        self.logger = PluginLogger(pluginIdentifier: pluginIdentifier)
        self.uiRegistry = UIRegistry(pluginIdentifier: pluginIdentifier)
        self.resources = ResourceAccess(pluginIdentifier: pluginIdentifier)
    }
    
    // MARK: - Cleanup
    
    func cleanup() {
        cancellables.removeAll()
        eventBus.cleanup()
        uiRegistry.cleanup()
    }
}

// MARK: - Command Interface

/// Provides controlled access to command execution
public class CommandInterface {
    private let pluginIdentifier: String
    
    init(pluginIdentifier: String) {
        self.pluginIdentifier = pluginIdentifier
    }
    
    /// Execute a command
    public func execute(_ command: String) async throws -> String {
        // This would integrate with CommandExecutor service
        // For now, return a placeholder
        return "Command execution not yet implemented"
    }
    
    /// Register a command preprocessor
    public func registerPreprocessor(_ handler: @escaping (String) -> String) {
        // Implementation would hook into CommandExecutor
    }
    
    /// Register a command postprocessor
    public func registerPostprocessor(_ handler: @escaping (String) -> String) {
        // Implementation would hook into CommandExecutor
    }
}

// MARK: - Plugin Settings Storage

/// Provides scoped settings storage for plugins
public class PluginSettingsStorage {
    private let pluginIdentifier: String
    private let userDefaults = UserDefaults.standard
    
    init(pluginIdentifier: String) {
        self.pluginIdentifier = pluginIdentifier
    }
    
    private func keyForSetting(_ key: String) -> String {
        return "plugin.\(pluginIdentifier).\(key)"
    }
    
    /// Get a setting value
    public func get<T>(_ key: String, defaultValue: T) -> T {
        let fullKey = keyForSetting(key)
        return userDefaults.object(forKey: fullKey) as? T ?? defaultValue
    }
    
    /// Set a setting value
    public func set<T>(_ key: String, value: T) {
        let fullKey = keyForSetting(key)
        userDefaults.set(value, forKey: fullKey)
    }
    
    /// Remove a setting
    public func remove(_ key: String) {
        let fullKey = keyForSetting(key)
        userDefaults.removeObject(forKey: fullKey)
    }
    
    /// Get all settings for this plugin
    public func getAllSettings() -> [String: Any] {
        let prefix = "plugin.\(pluginIdentifier)."
        var settings: [String: Any] = [:]
        
        for (key, value) in userDefaults.dictionaryRepresentation() {
            if key.hasPrefix(prefix) {
                let settingKey = String(key.dropFirst(prefix.count))
                settings[settingKey] = value
            }
        }
        
        return settings
    }
    
    /// Clear all settings for this plugin
    public func clearAll() {
        let prefix = "plugin.\(pluginIdentifier)."
        let keys = userDefaults.dictionaryRepresentation().keys.filter { $0.hasPrefix(prefix) }
        keys.forEach { userDefaults.removeObject(forKey: $0) }
    }
}

// MARK: - Plugin Event Bus

/// Event bus for plugin communication
public class PluginEventBus {
    private let pluginIdentifier: String
    private var subscriptions = Set<AnyCancellable>()
    
    /// Subject for publishing events
    private let eventSubject = PassthroughSubject<PluginEvent, Never>()
    
    /// Publisher for subscribing to events
    public var events: AnyPublisher<PluginEvent, Never> {
        eventSubject.eraseToAnyPublisher()
    }
    
    init(pluginIdentifier: String) {
        self.pluginIdentifier = pluginIdentifier
    }
    
    /// Publish an event
    public func publish(_ event: PluginEvent) {
        eventSubject.send(event)
    }
    
    /// Subscribe to events of a specific type
    public func subscribe<T: PluginEvent>(
        to eventType: T.Type,
        handler: @escaping (T) -> Void
    ) -> AnyCancellable {
        return events
            .compactMap { $0 as? T }
            .sink { event in
                handler(event)
            }
    }
    
    /// Cleanup subscriptions
    func cleanup() {
        subscriptions.removeAll()
    }
}

// MARK: - Plugin Event

/// Base protocol for plugin events
public protocol PluginEvent {
    var source: String { get }
    var timestamp: Date { get }
}

/// Basic implementation of PluginEvent
public struct BasicPluginEvent: PluginEvent {
    public let source: String
    public let timestamp: Date
    public let type: String
    public let data: [String: Any]?
    
    public init(source: String, type: String, data: [String: Any]? = nil) {
        self.source = source
        self.type = type
        self.data = data
        self.timestamp = Date()
    }
}

// MARK: - Plugin Logger

/// Logger for plugin-specific logging
public class PluginLogger {
    private let pluginIdentifier: String
    
    init(pluginIdentifier: String) {
        self.pluginIdentifier = pluginIdentifier
    }
    
    /// Log a debug message
    public func debug(_ message: String) {
        print("[DEBUG][\(pluginIdentifier)] \(message)")
    }
    
    /// Log an info message
    public func info(_ message: String) {
        print("[INFO][\(pluginIdentifier)] \(message)")
    }
    
    /// Log a warning message
    public func warning(_ message: String) {
        print("[WARNING][\(pluginIdentifier)] \(message)")
    }
    
    /// Log an error message
    public func error(_ message: String) {
        print("[ERROR][\(pluginIdentifier)] \(message)")
    }
}

// MARK: - UI Registry

/// Registry for UI components provided by plugins
public class UIRegistry {
    private let pluginIdentifier: String
    private var registeredViews: [String: AnyView] = [:]
    private var registeredMenuItems: [String: NSMenuItem] = [:]
    
    init(pluginIdentifier: String) {
        self.pluginIdentifier = pluginIdentifier
    }
    
    /// Register a SwiftUI view
    public func registerView<V: View>(_ view: V, forKey key: String) {
        registeredViews[key] = AnyView(view)
    }
    
    /// Get a registered view
    public func getView(forKey key: String) -> AnyView? {
        return registeredViews[key]
    }
    
    /// Register a menu item
    public func registerMenuItem(_ item: NSMenuItem, forKey key: String) {
        registeredMenuItems[key] = item
    }
    
    /// Get a registered menu item
    public func getMenuItem(forKey key: String) -> NSMenuItem? {
        return registeredMenuItems[key]
    }
    
    /// Cleanup registered UI components
    func cleanup() {
        registeredViews.removeAll()
        registeredMenuItems.removeAll()
    }
}

// MARK: - Resource Access

/// Provides controlled access to app resources
public class ResourceAccess {
    private let pluginIdentifier: String
    
    init(pluginIdentifier: String) {
        self.pluginIdentifier = pluginIdentifier
    }
    
    /// Get the plugin's data directory
    public var dataDirectory: URL? {
        guard let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first else { return nil }
        
        let pluginDir = appSupport
            .appendingPathComponent("Goose")
            .appendingPathComponent("Plugins")
            .appendingPathComponent(pluginIdentifier)
        
        // Create directory if it doesn't exist
        try? FileManager.default.createDirectory(
            at: pluginDir,
            withIntermediateDirectories: true,
            attributes: nil
        )
        
        return pluginDir
    }
    
    /// Get the plugin's cache directory
    public var cacheDirectory: URL? {
        guard let caches = FileManager.default.urls(
            for: .cachesDirectory,
            in: .userDomainMask
        ).first else { return nil }
        
        let pluginCache = caches
            .appendingPathComponent("Goose")
            .appendingPathComponent("Plugins")
            .appendingPathComponent(pluginIdentifier)
        
        // Create directory if it doesn't exist
        try? FileManager.default.createDirectory(
            at: pluginCache,
            withIntermediateDirectories: true,
            attributes: nil
        )
        
        return pluginCache
    }
    
    /// Get the bundle for the plugin (if applicable)
    public var bundle: Bundle? {
        // This would return the actual bundle for external plugins
        // For now, return the main bundle
        return Bundle.main
    }
}
