//
//  PluginContextTests.swift
//  GooseTests
//
//  Created by Goose on 15/09/2025.
//

import XCTest
import Combine
@testable import Goose

class PluginContextTests: XCTestCase {
    
    var pluginManager: PluginManager!
    var mockPlugin: MockPlugin!
    var pluginContext: PluginContext!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        pluginManager = PluginManager.shared
        mockPlugin = MockPlugin()
        cancellables = Set<AnyCancellable>()
        
        // Register and get context
        do {
            try pluginManager.register(mockPlugin)
            // Create a test context
            pluginContext = PluginContext(
                pluginIdentifier: mockPlugin.identifier,
                pluginManager: pluginManager
            )
        } catch {
            XCTFail("Failed to setup test: \(error)")
        }
    }
    
    override func tearDown() {
        pluginContext?.cleanup()
        pluginManager.unregister(identifier: mockPlugin.identifier)
        cancellables.removeAll()
        super.tearDown()
    }
    
    // MARK: - Settings Storage Tests
    
    func testSettingsStorage() {
        // Given
        let settings = pluginContext.settings
        
        // When - Store various types
        settings.set("stringKey", value: "test string")
        settings.set("intKey", value: 42)
        settings.set("boolKey", value: true)
        settings.set("arrayKey", value: [1, 2, 3])
        
        // Then - Retrieve values
        XCTAssertEqual(settings.get("stringKey", defaultValue: ""), "test string")
        XCTAssertEqual(settings.get("intKey", defaultValue: 0), 42)
        XCTAssertEqual(settings.get("boolKey", defaultValue: false), true)
        XCTAssertEqual(settings.get("arrayKey", defaultValue: [] as [Int]), [1, 2, 3])
    }
    
    func testSettingsDefaultValues() {
        // Given
        let settings = pluginContext.settings
        
        // When - Get non-existent keys
        let missingString = settings.get("missing", defaultValue: "default")
        let missingInt = settings.get("missing", defaultValue: 99)
        
        // Then
        XCTAssertEqual(missingString, "default")
        XCTAssertEqual(missingInt, 99)
    }
    
    func testSettingsRemoval() {
        // Given
        let settings = pluginContext.settings
        settings.set("testKey", value: "testValue")
        
        // When
        settings.remove("testKey")
        
        // Then
        XCTAssertEqual(settings.get("testKey", defaultValue: "missing"), "missing")
    }
    
    func testSettingsClearAll() {
        // Given
        let settings = pluginContext.settings
        settings.set("key1", value: "value1")
        settings.set("key2", value: "value2")
        settings.set("key3", value: "value3")
        
        // When
        settings.clearAll()
        
        // Then
        let allSettings = settings.getAllSettings()
        XCTAssertEqual(allSettings.count, 0)
    }
    
    func testSettingsIsolation() {
        // Given - Create another plugin with different identifier
        let anotherPlugin = DependentMockPlugin()
        do {
            try pluginManager.register(anotherPlugin)
        } catch {
            XCTFail("Failed to register second plugin")
        }
        
        let anotherContext = PluginContext(
            pluginIdentifier: anotherPlugin.identifier,
            pluginManager: pluginManager
        )
        
        // When - Set values in both contexts
        pluginContext.settings.set("sharedKey", value: "plugin1Value")
        anotherContext.settings.set("sharedKey", value: "plugin2Value")
        
        // Then - Values should be isolated
        XCTAssertEqual(pluginContext.settings.get("sharedKey", defaultValue: ""), "plugin1Value")
        XCTAssertEqual(anotherContext.settings.get("sharedKey", defaultValue: ""), "plugin2Value")
        
        // Cleanup
        anotherContext.cleanup()
        pluginManager.unregister(identifier: anotherPlugin.identifier)
    }
    
    // MARK: - Event Bus Tests
    
    func testEventPublishAndSubscribe() {
        // Given
        let eventBus = pluginContext.eventBus
        var receivedEvents: [BasicPluginEvent] = []
        
        let subscription = eventBus.subscribe(to: BasicPluginEvent.self) { event in
            receivedEvents.append(event)
        }
        
        // When - Publish events
        let event1 = BasicPluginEvent(source: "test", type: "event1", data: ["key": "value1"])
        let event2 = BasicPluginEvent(source: "test", type: "event2", data: ["key": "value2"])
        
        eventBus.publish(event1)
        eventBus.publish(event2)
        
        // Then
        XCTAssertEqual(receivedEvents.count, 2)
        XCTAssertEqual(receivedEvents[0].type, "event1")
        XCTAssertEqual(receivedEvents[1].type, "event2")
        
        subscription.cancel()
    }
    
    func testEventTypeFiltering() {
        // Given
        let eventBus = pluginContext.eventBus
        
        // Custom event type
        struct CustomEvent: PluginEvent {
            let source: String
            let timestamp: Date
            let customData: String
        }
        
        var basicEvents: [BasicPluginEvent] = []
        var customEvents: [CustomEvent] = []
        
        let basicSubscription = eventBus.subscribe(to: BasicPluginEvent.self) { event in
            basicEvents.append(event)
        }
        
        let customSubscription = eventBus.subscribe(to: CustomEvent.self) { event in
            customEvents.append(event)
        }
        
        // When - Publish different event types
        let basicEvent = BasicPluginEvent(source: "test", type: "basic", data: nil)
        let customEvent = CustomEvent(source: "test", timestamp: Date(), customData: "custom")
        
        eventBus.publish(basicEvent)
        eventBus.publish(customEvent)
        
        // Then - Each subscription should only receive its type
        XCTAssertEqual(basicEvents.count, 1)
        XCTAssertEqual(customEvents.count, 1)
        
        basicSubscription.cancel()
        customSubscription.cancel()
    }
    
    // MARK: - Logger Tests
    
    func testLogger() {
        // Given
        let logger = pluginContext.logger
        
        // When/Then - Just verify these don't crash
        logger.debug("Debug message")
        logger.info("Info message")
        logger.warning("Warning message")
        logger.error("Error message")
        
        // Note: In a real implementation, you might capture console output
        // or inject a test logger to verify the messages
    }
    
    // MARK: - UI Registry Tests
    
    func testUIRegistryViews() {
        // Given
        let uiRegistry = pluginContext.uiRegistry
        let testView = Text("Test View")
        
        // When
        uiRegistry.registerView(testView, forKey: "testView")
        
        // Then
        let retrievedView = uiRegistry.getView(forKey: "testView")
        XCTAssertNotNil(retrievedView)
        
        // Non-existent view
        let missingView = uiRegistry.getView(forKey: "nonExistent")
        XCTAssertNil(missingView)
    }
    
    func testUIRegistryMenuItems() {
        // Given
        let uiRegistry = pluginContext.uiRegistry
        let menuItem = NSMenuItem(title: "Test Item", action: nil, keyEquivalent: "")
        
        // When
        uiRegistry.registerMenuItem(menuItem, forKey: "testItem")
        
        // Then
        let retrievedItem = uiRegistry.getMenuItem(forKey: "testItem")
        XCTAssertNotNil(retrievedItem)
        XCTAssertEqual(retrievedItem?.title, "Test Item")
    }
    
    func testUIRegistryCleanup() {
        // Given
        let uiRegistry = pluginContext.uiRegistry
        let testView = Text("Test")
        let menuItem = NSMenuItem(title: "Test", action: nil, keyEquivalent: "")
        
        uiRegistry.registerView(testView, forKey: "view")
        uiRegistry.registerMenuItem(menuItem, forKey: "item")
        
        // When
        uiRegistry.cleanup()
        
        // Then
        XCTAssertNil(uiRegistry.getView(forKey: "view"))
        XCTAssertNil(uiRegistry.getMenuItem(forKey: "item"))
    }
    
    // MARK: - Resource Access Tests
    
    func testResourceAccessDirectories() {
        // Given
        let resources = pluginContext.resources
        
        // When
        let dataDir = resources.dataDirectory
        let cacheDir = resources.cacheDirectory
        
        // Then
        XCTAssertNotNil(dataDir)
        XCTAssertNotNil(cacheDir)
        
        // Verify directories contain plugin identifier
        XCTAssertTrue(dataDir?.path.contains(mockPlugin.identifier) ?? false)
        XCTAssertTrue(cacheDir?.path.contains(mockPlugin.identifier) ?? false)
        
        // Verify directories exist
        if let dataDir = dataDir {
            XCTAssertTrue(FileManager.default.fileExists(atPath: dataDir.path))
        }
        if let cacheDir = cacheDir {
            XCTAssertTrue(FileManager.default.fileExists(atPath: cacheDir.path))
        }
    }
    
    func testResourceAccessBundle() {
        // Given
        let resources = pluginContext.resources
        
        // When
        let bundle = resources.bundle
        
        // Then
        XCTAssertNotNil(bundle)
        // For now, it should return the main bundle
        XCTAssertEqual(bundle, Bundle.main)
    }
    
    // MARK: - Context Cleanup Tests
    
    func testContextCleanup() {
        // Given - Set up some state
        let eventBus = pluginContext.eventBus
        let uiRegistry = pluginContext.uiRegistry
        
        var eventReceived = false
        let subscription = eventBus.subscribe(to: BasicPluginEvent.self) { _ in
            eventReceived = true
        }
        
        uiRegistry.registerView(Text("Test"), forKey: "test")
        
        // When
        pluginContext.cleanup()
        
        // Then - Try to use cleaned up resources
        eventBus.publish(BasicPluginEvent(source: "test", type: "test", data: nil))
        XCTAssertFalse(eventReceived) // Event should not be received after cleanup
        XCTAssertNil(uiRegistry.getView(forKey: "test"))
        
        subscription.cancel()
    }
}

// MARK: - SwiftUI Test Support

import SwiftUI

private struct Text: View {
    let content: String
    
    init(_ content: String) {
        self.content = content
    }
    
    var body: some View {
        SwiftUI.Text(content)
    }
}
