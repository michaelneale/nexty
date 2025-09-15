//
//  PluginManagerTests.swift
//  GooseTests
//
//  Created by Goose on 15/09/2025.
//

import XCTest
import Combine
@testable import Goose

class PluginManagerTests: XCTestCase {
    
    var pluginManager: PluginManager!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        pluginManager = PluginManager.shared
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        // Clean up any registered plugins
        pluginManager.plugins.keys.forEach { identifier in
            pluginManager.unregister(identifier: identifier)
        }
        cancellables.removeAll()
        super.tearDown()
    }
    
    // MARK: - Registration Tests
    
    func testPluginRegistration() throws {
        // Given
        let mockPlugin = MockPlugin()
        
        // When
        try pluginManager.register(mockPlugin)
        
        // Then
        XCTAssertNotNil(pluginManager.getPlugin(mockPlugin.identifier))
        XCTAssertEqual(pluginManager.plugins.count, 1)
        XCTAssertEqual(mockPlugin.state, .initialized)
    }
    
    func testDuplicatePluginRegistrationFails() throws {
        // Given
        let mockPlugin1 = MockPlugin()
        let mockPlugin2 = MockPlugin() // Same identifier
        
        // When
        try pluginManager.register(mockPlugin1)
        
        // Then
        XCTAssertThrowsError(try pluginManager.register(mockPlugin2)) { error in
            XCTAssertTrue(error is PluginError)
        }
    }
    
    func testPluginUnregistration() throws {
        // Given
        let mockPlugin = MockPlugin()
        try pluginManager.register(mockPlugin)
        
        // When
        pluginManager.unregister(identifier: mockPlugin.identifier)
        
        // Then
        XCTAssertNil(pluginManager.getPlugin(mockPlugin.identifier))
        XCTAssertEqual(pluginManager.plugins.count, 0)
    }
    
    // MARK: - Activation Tests
    
    func testPluginActivation() throws {
        // Given
        let mockPlugin = MockPlugin()
        try pluginManager.register(mockPlugin)
        
        // When
        try pluginManager.activate(identifier: mockPlugin.identifier)
        
        // Then
        XCTAssertTrue(pluginManager.activePlugins.contains(mockPlugin.identifier))
        XCTAssertEqual(mockPlugin.state, .active)
    }
    
    func testPluginDeactivation() throws {
        // Given
        let mockPlugin = MockPlugin()
        try pluginManager.register(mockPlugin)
        try pluginManager.activate(identifier: mockPlugin.identifier)
        
        // When
        pluginManager.deactivate(identifier: mockPlugin.identifier)
        
        // Then
        XCTAssertFalse(pluginManager.activePlugins.contains(mockPlugin.identifier))
        XCTAssertEqual(mockPlugin.state, .inactive)
    }
    
    func testActivatingAlreadyActivePluginFails() throws {
        // Given
        let mockPlugin = MockPlugin()
        try pluginManager.register(mockPlugin)
        try pluginManager.activate(identifier: mockPlugin.identifier)
        
        // When/Then
        XCTAssertThrowsError(try pluginManager.activate(identifier: mockPlugin.identifier)) { error in
            guard let pluginError = error as? PluginError else {
                XCTFail("Expected PluginError")
                return
            }
            if case .alreadyActive = pluginError {
                // Success
            } else {
                XCTFail("Expected alreadyActive error")
            }
        }
    }
    
    // MARK: - Dependency Tests
    
    func testPluginWithDependencyRegistration() throws {
        // Given
        let mockPlugin = MockPlugin()
        let dependentPlugin = DependentMockPlugin()
        
        // When - Register in correct order
        try pluginManager.register(mockPlugin)
        try pluginManager.register(dependentPlugin)
        
        // Then
        XCTAssertNotNil(pluginManager.getPlugin(dependentPlugin.identifier))
    }
    
    func testPluginWithMissingDependencyFails() throws {
        // Given
        let dependentPlugin = DependentMockPlugin()
        
        // When/Then - Should fail without the dependency
        XCTAssertThrowsError(try pluginManager.register(dependentPlugin)) { error in
            guard let pluginError = error as? PluginError else {
                XCTFail("Expected PluginError")
                return
            }
            if case .missingDependency = pluginError {
                // Success
            } else {
                XCTFail("Expected missingDependency error")
            }
        }
    }
    
    func testDependentPluginActivationRequiresDependency() throws {
        // Given
        let mockPlugin = MockPlugin()
        let dependentPlugin = DependentMockPlugin()
        try pluginManager.register(mockPlugin)
        try pluginManager.register(dependentPlugin)
        
        // When/Then - Should fail to activate dependent without dependency active
        XCTAssertThrowsError(try pluginManager.activate(identifier: dependentPlugin.identifier)) { error in
            guard let pluginError = error as? PluginError else {
                XCTFail("Expected PluginError")
                return
            }
            if case .missingDependency = pluginError {
                // Success
            } else {
                XCTFail("Expected missingDependency error")
            }
        }
        
        // Activate dependency first
        try pluginManager.activate(identifier: mockPlugin.identifier)
        
        // Now dependent should activate
        XCTAssertNoThrow(try pluginManager.activate(identifier: dependentPlugin.identifier))
    }
    
    func testDeactivatingDependencyDeactivatesDependents() throws {
        // Given
        let mockPlugin = MockPlugin()
        let dependentPlugin = DependentMockPlugin()
        try pluginManager.register(mockPlugin)
        try pluginManager.register(dependentPlugin)
        try pluginManager.activate(identifier: mockPlugin.identifier)
        try pluginManager.activate(identifier: dependentPlugin.identifier)
        
        // When - Deactivate the dependency
        pluginManager.deactivate(identifier: mockPlugin.identifier)
        
        // Then - Both should be deactivated
        XCTAssertFalse(pluginManager.activePlugins.contains(mockPlugin.identifier))
        XCTAssertFalse(pluginManager.activePlugins.contains(dependentPlugin.identifier))
    }
    
    // MARK: - Query Tests
    
    func testGetPluginsWithCapability() throws {
        // Given
        let mockPlugin = MockPlugin() // Has commandProcessor capability
        let dependentPlugin = DependentMockPlugin() // Has workflowAutomation capability
        try pluginManager.register(mockPlugin)
        try pluginManager.register(dependentPlugin)
        
        // When
        let commandProcessors = pluginManager.getPlugins(withCapability: .commandProcessor)
        let workflowPlugins = pluginManager.getPlugins(withCapability: .workflowAutomation)
        
        // Then
        XCTAssertEqual(commandProcessors.count, 1)
        XCTAssertEqual(commandProcessors.first?.identifier, mockPlugin.identifier)
        XCTAssertEqual(workflowPlugins.count, 1)
        XCTAssertEqual(workflowPlugins.first?.identifier, dependentPlugin.identifier)
    }
    
    func testGetActivePluginsWithCapability() throws {
        // Given
        let mockPlugin = MockPlugin()
        try pluginManager.register(mockPlugin)
        
        // When - Before activation
        let inactivePlugins = pluginManager.getActivePlugins(withCapability: .commandProcessor)
        
        // Then
        XCTAssertEqual(inactivePlugins.count, 0)
        
        // When - After activation
        try pluginManager.activate(identifier: mockPlugin.identifier)
        let activePlugins = pluginManager.getActivePlugins(withCapability: .commandProcessor)
        
        // Then
        XCTAssertEqual(activePlugins.count, 1)
        XCTAssertEqual(activePlugins.first?.identifier, mockPlugin.identifier)
    }
    
    // MARK: - Load Order Tests
    
    func testResolveLoadOrder() throws {
        // Given
        let mockPlugin = MockPlugin()
        let dependentPlugin = DependentMockPlugin()
        try pluginManager.register(mockPlugin)
        try pluginManager.register(dependentPlugin)
        
        // When
        let loadOrder = pluginManager.resolveLoadOrder(for: [
            dependentPlugin.identifier,
            mockPlugin.identifier
        ])
        
        // Then - Mock should come before dependent
        XCTAssertEqual(loadOrder.count, 2)
        XCTAssertEqual(loadOrder[0], mockPlugin.identifier)
        XCTAssertEqual(loadOrder[1], dependentPlugin.identifier)
    }
    
    // MARK: - Event Tests
    
    func testPluginLifecycleEvents() throws {
        // Given
        let mockPlugin = MockPlugin()
        var receivedEvents: [PluginLifecycleEvent] = []
        
        pluginManager.pluginEvents
            .sink { event in
                receivedEvents.append(event)
            }
            .store(in: &cancellables)
        
        // When
        try pluginManager.register(mockPlugin)
        try pluginManager.activate(identifier: mockPlugin.identifier)
        pluginManager.deactivate(identifier: mockPlugin.identifier)
        pluginManager.unregister(identifier: mockPlugin.identifier)
        
        // Then
        XCTAssertEqual(receivedEvents.count, 4)
        
        // Verify event sequence
        if case .registered(let id) = receivedEvents[0] {
            XCTAssertEqual(id, mockPlugin.identifier)
        } else {
            XCTFail("Expected registered event")
        }
        
        if case .activated(let id) = receivedEvents[1] {
            XCTAssertEqual(id, mockPlugin.identifier)
        } else {
            XCTFail("Expected activated event")
        }
        
        if case .deactivated(let id) = receivedEvents[2] {
            XCTAssertEqual(id, mockPlugin.identifier)
        } else {
            XCTFail("Expected deactivated event")
        }
        
        if case .unregistered(let id) = receivedEvents[3] {
            XCTAssertEqual(id, mockPlugin.identifier)
        } else {
            XCTFail("Expected unregistered event")
        }
    }
    
    // MARK: - Error Handling Tests
    
    func testFailingPluginInitialization() throws {
        // Given
        let failingPlugin = FailingMockPlugin(failureMode: .duringInitialization)
        
        // When/Then
        XCTAssertThrowsError(try pluginManager.register(failingPlugin)) { error in
            guard let pluginError = error as? PluginError else {
                XCTFail("Expected PluginError")
                return
            }
            if case .initializationFailed = pluginError {
                // Success
            } else {
                XCTFail("Expected initializationFailed error")
            }
        }
    }
    
    func testFailingPluginActivation() throws {
        // Given
        let failingPlugin = FailingMockPlugin(failureMode: .duringActivation)
        try pluginManager.register(failingPlugin)
        
        // When/Then
        XCTAssertThrowsError(try pluginManager.activate(identifier: failingPlugin.identifier)) { error in
            guard let pluginError = error as? PluginError else {
                XCTFail("Expected PluginError")
                return
            }
            if case .activationFailed = pluginError {
                // Success
            } else {
                XCTFail("Expected activationFailed error")
            }
        }
    }
}
