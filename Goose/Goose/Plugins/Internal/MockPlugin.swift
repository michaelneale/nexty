//
//  MockPlugin.swift
//  Goose
//
//  Created by Goose on 15/09/2025.
//

import Foundation
import Combine

/// Mock plugin for testing the plugin architecture
public class MockPlugin: BasePlugin {
    
    // MARK: - Properties
    
    private var cancellables = Set<AnyCancellable>()
    public private(set) var preprocessedCommands: [GooseCommand] = []
    public private(set) var formattedOutputs: [String] = []
    public private(set) var receivedEvents: [PluginEvent] = []
    
    // MARK: - Initialization
    
    public convenience init() {
        self.init(
            identifier: "com.goose.mock",
            name: "Mock Plugin",
            version: "1.0.0",
            author: "Goose Team",
            description: "A mock plugin for testing the plugin architecture",
            capabilities: [.commandProcessor, .outputFormatter, .dataProvider],
            dependencies: []
        )
    }
    
    // MARK: - Lifecycle Override
    
    public override func initialize(context: PluginContext) throws {
        try super.initialize(context: context)
        
        // Log initialization
        context.logger.info("Mock plugin initialized")
        
        // Subscribe to events
        context.eventBus.events
            .sink { [weak self] event in
                self?.receivedEvents.append(event)
                context.logger.debug("Received event: \(event)")
            }
            .store(in: &cancellables)
        
        // Store a test setting
        context.settings.set("initialized", value: true)
    }
    
    public override func activate() throws {
        try super.activate()
        
        guard let context = context else {
            throw PluginError.contextNotSet
        }
        
        context.logger.info("Mock plugin activated")
        
        // Publish activation event
        let event = BasicPluginEvent(
            source: identifier,
            type: "activated",
            data: ["timestamp": Date().timeIntervalSince1970]
        )
        context.eventBus.publish(event)
    }
    
    public override func deactivate() {
        super.deactivate()
        
        context?.logger.info("Mock plugin deactivated")
        
        // Clear stored data
        preprocessedCommands.removeAll()
        formattedOutputs.removeAll()
        
        // Publish deactivation event
        if let context = context {
            let event = BasicPluginEvent(
                source: identifier,
                type: "deactivated",
                data: ["timestamp": Date().timeIntervalSince1970]
            )
            context.eventBus.publish(event)
        }
    }
    
    public override func cleanup() {
        cancellables.removeAll()
        receivedEvents.removeAll()
        context?.settings.clearAll()
        
        super.cleanup()
    }
    
    // MARK: - Plugin Capabilities Implementation
    
    /// Process a command (for testing)
    public func processCommand(_ command: GooseCommand) -> GooseCommand {
        preprocessedCommands.append(command)
        return command.appendingArguments(["--mock-processed"])
    }
    
    /// Format output (for testing)
    public func formatOutput(_ output: String) -> String {
        let formatted = "[MOCK] \(output)"
        formattedOutputs.append(formatted)
        return formatted
    }
    
    /// Provide data suggestions (for testing)
    public func provideSuggestions(for input: String) -> [String] {
        return [
            "\(input) suggestion 1",
            "\(input) suggestion 2",
            "\(input) suggestion 3"
        ]
    }
}

// MARK: - Test Helper Plugin

/// A second mock plugin for testing dependencies
public class DependentMockPlugin: BasePlugin {
    
    public convenience init() {
        self.init(
            identifier: "com.goose.mock.dependent",
            name: "Dependent Mock Plugin",
            version: "1.0.0",
            author: "Goose Team",
            description: "A mock plugin that depends on the main mock plugin",
            capabilities: [.workflowAutomation],
            dependencies: ["com.goose.mock"]  // Depends on MockPlugin
        )
    }
    
    public override func activate() throws {
        try super.activate()
        
        guard let context = context else {
            throw PluginError.contextNotSet
        }
        
        context.logger.info("Dependent mock plugin activated")
        
        // This plugin requires the mock plugin to be active
        // The PluginManager should enforce this dependency
    }
}

// MARK: - Failing Mock Plugin

/// A mock plugin that fails during various lifecycle stages (for testing error handling)
public class FailingMockPlugin: BasePlugin {
    
    public enum FailureMode {
        case none
        case duringInitialization
        case duringActivation
        case duringDeactivation
    }
    
    public var failureMode: FailureMode = .none
    
    public convenience init(failureMode: FailureMode = .none) {
        self.init(
            identifier: "com.goose.mock.failing",
            name: "Failing Mock Plugin",
            version: "1.0.0",
            author: "Goose Team",
            description: "A mock plugin that fails for testing error handling",
            capabilities: [],
            dependencies: []
        )
        self.failureMode = failureMode
    }
    
    public override func initialize(context: PluginContext) throws {
        if failureMode == .duringInitialization {
            throw PluginError.initializationFailed("Intentional failure during initialization")
        }
        try super.initialize(context: context)
    }
    
    public override func activate() throws {
        if failureMode == .duringActivation {
            throw PluginError.activationFailed("Intentional failure during activation")
        }
        try super.activate()
    }
    
    public override func deactivate() {
        if failureMode == .duringDeactivation {
            // Log error but don't throw since deactivate doesn't throw
            context?.logger.error("Intentional failure during deactivation")
        }
        super.deactivate()
    }
}
