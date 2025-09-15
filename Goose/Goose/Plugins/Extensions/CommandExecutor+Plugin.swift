//
//  CommandExecutor+Plugin.swift
//  Goose
//
//  Created by Goose on 15/09/2025.
//

import Foundation
import Combine

// MARK: - Plugin Support for CommandExecutor

extension CommandExecutor {
    /// Type alias for command processors
    public typealias CommandProcessor = (GooseCommand) -> GooseCommand
    public typealias AsyncCommandProcessor = (GooseCommand) async -> GooseCommand
    
    /// Storage for plugin command processors
    private struct PluginProcessors {
        static var preprocessors: [(pluginId: String, processor: CommandProcessor)] = []
        static var asyncPreprocessors: [(pluginId: String, processor: AsyncCommandProcessor)] = []
        static var postprocessors: [(pluginId: String, processor: CommandProcessor)] = []
        static var asyncPostprocessors: [(pluginId: String, processor: AsyncCommandProcessor)] = []
        static let lock = NSLock()
    }
    
    // MARK: - Registration
    
    /// Register a synchronous command preprocessor from a plugin
    public func registerPreprocessor(
        from pluginId: String,
        processor: @escaping CommandProcessor
    ) {
        PluginProcessors.lock.lock()
        defer { PluginProcessors.lock.unlock() }
        
        // Remove any existing processor from this plugin
        PluginProcessors.preprocessors.removeAll { $0.pluginId == pluginId }
        
        // Add the new processor
        PluginProcessors.preprocessors.append((pluginId, processor))
    }
    
    /// Register an asynchronous command preprocessor from a plugin
    public func registerAsyncPreprocessor(
        from pluginId: String,
        processor: @escaping AsyncCommandProcessor
    ) {
        PluginProcessors.lock.lock()
        defer { PluginProcessors.lock.unlock() }
        
        // Remove any existing processor from this plugin
        PluginProcessors.asyncPreprocessors.removeAll { $0.pluginId == pluginId }
        
        // Add the new processor
        PluginProcessors.asyncPreprocessors.append((pluginId, processor))
    }
    
    /// Register a synchronous command postprocessor from a plugin
    public func registerPostprocessor(
        from pluginId: String,
        processor: @escaping CommandProcessor
    ) {
        PluginProcessors.lock.lock()
        defer { PluginProcessors.lock.unlock() }
        
        // Remove any existing processor from this plugin
        PluginProcessors.postprocessors.removeAll { $0.pluginId == pluginId }
        
        // Add the new processor
        PluginProcessors.postprocessors.append((pluginId, processor))
    }
    
    /// Register an asynchronous command postprocessor from a plugin
    public func registerAsyncPostprocessor(
        from pluginId: String,
        processor: @escaping AsyncCommandProcessor
    ) {
        PluginProcessors.lock.lock()
        defer { PluginProcessors.lock.unlock() }
        
        // Remove any existing processor from this plugin
        PluginProcessors.asyncPostprocessors.removeAll { $0.pluginId == pluginId }
        
        // Add the new processor
        PluginProcessors.asyncPostprocessors.append((pluginId, processor))
    }
    
    // MARK: - Unregistration
    
    /// Unregister all processors from a plugin
    public func unregisterProcessors(from pluginId: String) {
        PluginProcessors.lock.lock()
        defer { PluginProcessors.lock.unlock() }
        
        PluginProcessors.preprocessors.removeAll { $0.pluginId == pluginId }
        PluginProcessors.asyncPreprocessors.removeAll { $0.pluginId == pluginId }
        PluginProcessors.postprocessors.removeAll { $0.pluginId == pluginId }
        PluginProcessors.asyncPostprocessors.removeAll { $0.pluginId == pluginId }
    }
    
    // MARK: - Processing
    
    /// Apply all registered preprocessors to a command
    internal func applyPreprocessors(to command: GooseCommand) async -> GooseCommand {
        var processedCommand = command
        
        PluginProcessors.lock.lock()
        let syncProcessors = PluginProcessors.preprocessors
        let asyncProcessors = PluginProcessors.asyncPreprocessors
        PluginProcessors.lock.unlock()
        
        // Apply synchronous preprocessors
        for (pluginId, processor) in syncProcessors {
            processedCommand = processor(processedCommand)
            print("[CommandExecutor] Applied preprocessor from plugin: \(pluginId)")
        }
        
        // Apply asynchronous preprocessors
        for (pluginId, processor) in asyncProcessors {
            processedCommand = await processor(processedCommand)
            print("[CommandExecutor] Applied async preprocessor from plugin: \(pluginId)")
        }
        
        return processedCommand
    }
    
    /// Apply all registered postprocessors to a command
    internal func applyPostprocessors(to command: GooseCommand) async -> GooseCommand {
        var processedCommand = command
        
        PluginProcessors.lock.lock()
        let syncProcessors = PluginProcessors.postprocessors
        let asyncProcessors = PluginProcessors.asyncPostprocessors
        PluginProcessors.lock.unlock()
        
        // Apply synchronous postprocessors
        for (pluginId, processor) in syncProcessors {
            processedCommand = processor(processedCommand)
            print("[CommandExecutor] Applied postprocessor from plugin: \(pluginId)")
        }
        
        // Apply asynchronous postprocessors
        for (pluginId, processor) in asyncProcessors {
            processedCommand = await processor(processedCommand)
            print("[CommandExecutor] Applied async postprocessor from plugin: \(pluginId)")
        }
        
        return processedCommand
    }
    
    /// Execute a command with plugin preprocessing and postprocessing
    public func executeWithPlugins(
        command: GooseCommand,
        outputHandler: @escaping (String, ResponseType) -> Void
    ) async throws {
        // Apply preprocessors
        let preprocessedCommand = await applyPreprocessors(to: command)
        
        // Execute the command
        try await execute(command: preprocessedCommand, outputHandler: outputHandler)
        
        // Apply postprocessors (for any cleanup or additional processing)
        _ = await applyPostprocessors(to: preprocessedCommand)
    }
}

// MARK: - Plugin Command Hooks

/// Protocol for plugins that want to process commands
public protocol CommandProcessorPlugin {
    /// Called before a command is executed
    func preprocessCommand(_ command: GooseCommand) -> GooseCommand
    
    /// Called after a command is executed
    func postprocessCommand(_ command: GooseCommand) -> GooseCommand
}

/// Async version of command processor plugin
public protocol AsyncCommandProcessorPlugin {
    /// Called before a command is executed
    func preprocessCommand(_ command: GooseCommand) async -> GooseCommand
    
    /// Called after a command is executed  
    func postprocessCommand(_ command: GooseCommand) async -> GooseCommand
}

// MARK: - Command Modification Helpers

extension GooseCommand {
    /// Create a modified copy of the command with new arguments
    public func withArguments(_ newArguments: [String]) -> GooseCommand {
        var copy = GooseCommand(command: self.command, arguments: newArguments)
        copy.status = self.status
        return copy
    }
    
    /// Create a modified copy of the command with additional arguments
    public func appendingArguments(_ additionalArguments: [String]) -> GooseCommand {
        var copy = GooseCommand(command: self.command, arguments: self.arguments + additionalArguments)
        copy.status = self.status
        return copy
    }
    
    /// Create a modified copy with a new command string
    public func withCommand(_ newCommand: String) -> GooseCommand {
        var copy = GooseCommand(command: newCommand, arguments: self.arguments)
        copy.status = self.status
        return copy
    }
}
