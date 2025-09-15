//
//  PluginManager.swift
//  Goose
//
//  Created by Goose on 15/09/2025.
//

import Foundation
import Combine

/// Manages the lifecycle and registry of all plugins
public class PluginManager: ObservableObject {
    // MARK: - Singleton
    
    public static let shared = PluginManager()
    
    // MARK: - Published Properties
    
    /// Currently loaded plugins
    @Published public private(set) var plugins: [String: Plugin] = [:]
    
    /// Active plugins
    @Published public private(set) var activePlugins: Set<String> = []
    
    // MARK: - Private Properties
    
    private var pluginContexts: [String: PluginContext] = [:]
    private let queue = DispatchQueue(label: "com.goose.pluginmanager", attributes: .concurrent)
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Event Publishers
    
    /// Publisher for plugin lifecycle events
    public let pluginEvents = PassthroughSubject<PluginLifecycleEvent, Never>()
    
    // MARK: - Initialization
    
    private init() {
        setupEventHandlers()
    }
    
    // MARK: - Plugin Discovery
    
    /// Discover plugins from designated directories
    public func discoverPlugins() async {
        // This will be implemented to scan plugin directories
        // For now, we'll just log
        print("Plugin discovery not yet implemented")
    }
    
    // MARK: - Plugin Registration
    
    /// Register a plugin with the manager
    /// - Parameter plugin: The plugin to register
    /// - Throws: PluginError if registration fails
    public func register(_ plugin: Plugin) throws {
        try queue.sync(flags: .barrier) {
            guard plugins[plugin.identifier] == nil else {
                throw PluginError.initializationFailed("Plugin with identifier '\(plugin.identifier)' already registered")
            }
            
            // Validate dependencies
            try validateDependencies(for: plugin)
            
            // Store the plugin
            plugins[plugin.identifier] = plugin
            
            // Create context for the plugin
            let context = PluginContext(
                pluginIdentifier: plugin.identifier,
                pluginManager: self
            )
            pluginContexts[plugin.identifier] = context
            
            // Initialize the plugin
            try plugin.initialize(context: context)
            
            // Publish registration event
            pluginEvents.send(.registered(plugin.identifier))
        }
    }
    
    /// Unregister a plugin
    /// - Parameter identifier: The identifier of the plugin to unregister
    public func unregister(identifier: String) {
        queue.async(flags: .barrier) { [weak self] in
            guard let self = self,
                  let plugin = self.plugins[identifier] else { return }
            
            // Deactivate if active
            if self.activePlugins.contains(identifier) {
                plugin.deactivate()
                self.activePlugins.remove(identifier)
            }
            
            // Cleanup
            plugin.cleanup()
            self.pluginContexts[identifier]?.cleanup()
            
            // Remove from registry
            self.plugins.removeValue(forKey: identifier)
            self.pluginContexts.removeValue(forKey: identifier)
            
            // Publish unregistration event
            self.pluginEvents.send(.unregistered(identifier))
        }
    }
    
    // MARK: - Plugin Lifecycle
    
    /// Activate a plugin
    /// - Parameter identifier: The identifier of the plugin to activate
    /// - Throws: PluginError if activation fails
    public func activate(identifier: String) throws {
        try queue.sync(flags: .barrier) {
            guard let plugin = plugins[identifier] else {
                throw PluginError.activationFailed("Plugin not found: \(identifier)")
            }
            
            guard !activePlugins.contains(identifier) else {
                throw PluginError.alreadyActive
            }
            
            // Check dependencies are active
            for dependency in plugin.dependencies {
                guard activePlugins.contains(dependency) else {
                    throw PluginError.missingDependency(dependency)
                }
            }
            
            // Activate the plugin
            try plugin.activate()
            activePlugins.insert(identifier)
            
            // Publish activation event
            pluginEvents.send(.activated(identifier))
        }
    }
    
    /// Deactivate a plugin
    /// - Parameter identifier: The identifier of the plugin to deactivate
    public func deactivate(identifier: String) {
        queue.async(flags: .barrier) { [weak self] in
            guard let self = self,
                  let plugin = self.plugins[identifier],
                  self.activePlugins.contains(identifier) else { return }
            
            // Check if any active plugins depend on this one
            let dependents = self.getActiveDependents(of: identifier)
            
            // Deactivate dependents first
            for dependent in dependents {
                self.plugins[dependent]?.deactivate()
                self.activePlugins.remove(dependent)
                self.pluginEvents.send(.deactivated(dependent))
            }
            
            // Deactivate the plugin
            plugin.deactivate()
            self.activePlugins.remove(identifier)
            
            // Publish deactivation event
            self.pluginEvents.send(.deactivated(identifier))
        }
    }
    
    // MARK: - Plugin Queries
    
    /// Get a plugin by identifier
    /// - Parameter identifier: The plugin identifier
    /// - Returns: The plugin if found
    public func getPlugin(_ identifier: String) -> Plugin? {
        queue.sync {
            return plugins[identifier]
        }
    }
    
    /// Get all plugins with a specific capability
    /// - Parameter capability: The capability to filter by
    /// - Returns: Array of plugins with the specified capability
    public func getPlugins(withCapability capability: PluginCapability) -> [Plugin] {
        queue.sync {
            return plugins.values.filter { $0.capabilities.contains(capability) }
        }
    }
    
    /// Get all active plugins with a specific capability
    /// - Parameter capability: The capability to filter by
    /// - Returns: Array of active plugins with the specified capability
    public func getActivePlugins(withCapability capability: PluginCapability) -> [Plugin] {
        queue.sync {
            return plugins.values.filter {
                activePlugins.contains($0.identifier) && $0.capabilities.contains(capability)
            }
        }
    }
    
    // MARK: - Dependency Management
    
    /// Validate that all dependencies for a plugin are satisfied
    private func validateDependencies(for plugin: Plugin) throws {
        for dependency in plugin.dependencies {
            guard plugins[dependency] != nil else {
                throw PluginError.missingDependency(dependency)
            }
        }
    }
    
    /// Get active plugins that depend on the specified plugin
    private func getActiveDependents(of identifier: String) -> [String] {
        return activePlugins.filter { pluginId in
            guard let plugin = plugins[pluginId] else { return false }
            return plugin.dependencies.contains(identifier)
        }
    }
    
    /// Resolve plugin load order based on dependencies
    public func resolveLoadOrder(for pluginIds: [String]) -> [String] {
        var resolved: [String] = []
        var visited = Set<String>()
        
        func visit(_ identifier: String) {
            guard !visited.contains(identifier),
                  let plugin = plugins[identifier] else { return }
            
            visited.insert(identifier)
            
            for dependency in plugin.dependencies {
                visit(dependency)
            }
            
            if !resolved.contains(identifier) {
                resolved.append(identifier)
            }
        }
        
        for identifier in pluginIds {
            visit(identifier)
        }
        
        return resolved
    }
    
    // MARK: - Event Handling
    
    private func setupEventHandlers() {
        // Subscribe to plugin events for logging
        pluginEvents
            .sink { event in
                print("Plugin event: \(event)")
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Plugin Loading
    
    /// Load a plugin from a manifest
    /// - Parameter manifest: The plugin manifest
    /// - Throws: PluginError if loading fails
    public func loadPlugin(from manifest: PluginManifest) throws {
        // This will be implemented to load plugins from manifests
        // For now, throw an error
        throw PluginError.initializationFailed("Plugin loading from manifest not yet implemented")
    }
    
    /// Load all plugins from a directory
    /// - Parameter directory: The directory containing plugins
    public func loadPlugins(from directory: URL) async throws {
        // This will be implemented to scan and load plugins from a directory
        // For now, just log
        print("Loading plugins from directory not yet implemented")
    }
}

// MARK: - Plugin Lifecycle Events

/// Events that occur during plugin lifecycle
public enum PluginLifecycleEvent {
    case registered(String)
    case unregistered(String)
    case activated(String)
    case deactivated(String)
    case error(String, Error)
}

// MARK: - Plugin Registry Protocol

/// Protocol for services that need to be notified of plugin changes
public protocol PluginRegistryObserver: AnyObject {
    func pluginRegistered(_ plugin: Plugin)
    func pluginUnregistered(_ plugin: Plugin)
    func pluginActivated(_ plugin: Plugin)
    func pluginDeactivated(_ plugin: Plugin)
}

// MARK: - Extension Point Registration

extension PluginManager {
    /// Register a command processor from a plugin
    public func registerCommandProcessor(
        from plugin: Plugin,
        preprocessor: ((String) -> String)? = nil,
        postprocessor: ((String) -> String)? = nil
    ) {
        // This will integrate with CommandExecutor
        // Implementation to be added when extending CommandExecutor
    }
    
    /// Register an output formatter from a plugin
    public func registerOutputFormatter(
        from plugin: Plugin,
        formatter: @escaping (String) -> String
    ) {
        // This will integrate with OutputParser
        // Implementation to be added when extending OutputParser
    }
}
