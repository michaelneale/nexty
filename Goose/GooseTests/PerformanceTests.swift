//
//  PerformanceTests.swift
//  GooseTests
//
//  Performance tests for virtual scrolling and large output handling
//

import XCTest
@testable import Goose

class PerformanceTests: XCTestCase {
    
    var bufferManager: OutputBufferManager!
    var backgroundProcessor: BackgroundOutputProcessor!
    
    override func setUp() {
        super.setUp()
        bufferManager = OutputBufferManager(maxMemoryMB: 10)
        backgroundProcessor = BackgroundOutputProcessor(bufferManager: bufferManager)
    }
    
    override func tearDown() {
        bufferManager = nil
        backgroundProcessor = nil
        super.tearDown()
    }
    
    // MARK: - Buffer Manager Tests
    
    func testLargeOutputBuffering() async throws {
        // Generate 100K lines
        let testOutput = PerformanceTest.generateTestOutput(lines: 100_000, charactersPerLine: 80)
        
        // Measure time to buffer
        let startTime = Date()
        await bufferManager.appendOutput(testOutput)
        let elapsed = Date().timeIntervalSince(startTime)
        
        // Verify performance
        XCTAssertLessThan(elapsed, 5.0, "Buffering 100K lines should take less than 5 seconds")
        XCTAssertEqual(bufferManager.lineCount, 100_000)
        
        // Check memory usage
        let memoryMB = bufferManager.memoryUsage / 1024 / 1024
        XCTAssertLessThan(memoryMB, 50, "Memory usage should be under 50MB for 100K lines")
    }
    
    func testMemoryOverflowToFile() async throws {
        // Generate enough data to trigger overflow
        let largeOutput = PerformanceTest.generateTestOutput(lines: 50_000, charactersPerLine: 200)
        
        await bufferManager.appendOutput(largeOutput)
        
        // Verify overflow happened
        XCTAssertEqual(bufferManager.lineCount, 50_000)
        
        // Verify we can still access all lines
        let lines = await bufferManager.getLines(from: 0, to: 100)
        XCTAssertEqual(lines.count, 100)
    }
    
    func testSearchPerformance() async throws {
        // Generate test data with known patterns
        var testOutput = ""
        for i in 0..<100_000 {
            testOutput += "Line \(i): This is a test line with searchable content\n"
        }
        
        await bufferManager.appendOutput(testOutput)
        
        // Measure search performance
        let startTime = Date()
        let results = await bufferManager.search(for: "searchable")
        let elapsed = Date().timeIntervalSince(startTime)
        
        // Verify performance
        XCTAssertLessThan(elapsed, 1.0, "Search across 100K lines should take less than 1 second")
        XCTAssertEqual(results.count, 100_000, "Should find matches in all lines")
    }
    
    // MARK: - Background Processor Tests
    
    func testBackgroundProcessing() async throws {
        // Generate output with ANSI codes
        let ansiOutput = """
        \u{001B}[31mError: Something went wrong\u{001B}[0m
        \u{001B}[33mWarning: Check this out\u{001B}[0m
        Normal text here
        """
        
        await backgroundProcessor.processOutput(ansiOutput)
        
        // Wait for processing
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        // Verify ANSI codes were removed
        let content = await bufferManager.getAllContent()
        XCTAssertFalse(content.contains("\u{001B}"))
    }
    
    func testSyntaxHighlighting() async throws {
        let codeOutput = """
        func testFunction() {
            let value = "string"
            var number = 123
            // This is a comment
            return value
        }
        """
        
        let highlighted = await backgroundProcessor.applySyntaxHighlighting(to: codeOutput)
        
        // Verify highlighting was applied
        XCTAssertNotNil(highlighted)
        XCTAssertGreaterThan(highlighted.length, 0)
    }
    
    // MARK: - Virtual Scrolling Tests
    
    func testVirtualScrollingPerformance() {
        // This test would require UI testing
        // Measure FPS while scrolling through large output
        
        let expectation = self.expectation(description: "Scrolling performance test")
        
        PerformanceTest.testScrollingPerformance { acceptable in
            XCTAssertTrue(acceptable, "Scrolling performance should be acceptable")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testMemoryUsageWithLargeOutput() {
        let expectation = self.expectation(description: "Memory usage test")
        
        PerformanceTest.testMemoryUsage(outputSize: 100_000) { acceptable in
            XCTAssertTrue(acceptable, "Memory usage should be acceptable for 100K lines")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 10.0)
    }
    
    // MARK: - Performance Monitor Tests
    
    func testPerformanceMonitor() {
        let monitor = PerformanceMonitor.shared
        
        // Start monitoring
        monitor.startMonitoring()
        
        // Wait for some metrics
        Thread.sleep(forTimeInterval: 2.0)
        
        // Check metrics
        let fps = monitor.getAverageFPS()
        let memory = monitor.getCurrentMemoryUsage()
        
        XCTAssertGreaterThan(fps, 0, "Should have FPS metrics")
        XCTAssertGreaterThan(memory, 0, "Should have memory metrics")
        
        // Check if performance is acceptable
        _ = monitor.isPerformanceAcceptable()
        
        // Log metrics (for debugging)
        monitor.logMetrics()
        
        monitor.stopMonitoring()
    }
    
    func testMeasureTimeUtility() {
        let monitor = PerformanceMonitor.shared
        
        let result = monitor.measureTime(label: "Test operation") {
            Thread.sleep(forTimeInterval: 0.1)
            return 42
        }
        
        XCTAssertEqual(result, 42)
    }
    
    func testMeasureTimeAsyncUtility() async throws {
        let monitor = PerformanceMonitor.shared
        
        let result = await monitor.measureTimeAsync(label: "Async test operation") {
            try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            return "completed"
        }
        
        XCTAssertEqual(result, "completed")
    }
    
    // MARK: - Stress Tests
    
    func testRapidOutputStreaming() async throws {
        // Simulate rapid output streaming
        for i in 0..<1000 {
            let chunk = "Chunk \(i): " + String(repeating: "x", count: 100) + "\n"
            await bufferManager.appendOutput(chunk)
            
            // Small delay to simulate streaming
            try await Task.sleep(nanoseconds: 1_000_000) // 1ms
        }
        
        XCTAssertEqual(bufferManager.lineCount, 1000)
        XCTAssertTrue(bufferManager.isStreaming)
        
        bufferManager.stopStreaming()
        XCTAssertFalse(bufferManager.isStreaming)
    }
    
    func testVeryLongLines() async throws {
        // Test handling of very long single lines
        let longLine = String(repeating: "x", count: 100_000)
        await bufferManager.appendOutput(longLine)
        
        let content = await bufferManager.getAllContent()
        XCTAssertEqual(content.count, 100_000)
    }
    
    func testConcurrentAccess() async throws {
        // Test concurrent read/write access
        await withTaskGroup(of: Void.self) { group in
            // Writers
            for i in 0..<10 {
                group.addTask {
                    let output = "Writer \(i): test output\n"
                    await self.bufferManager.appendOutput(output)
                }
            }
            
            // Readers
            for _ in 0..<10 {
                group.addTask {
                    _ = await self.bufferManager.getLines(from: 0, to: 10)
                }
            }
            
            await group.waitForAll()
        }
        
        // Verify buffer integrity
        XCTAssertGreaterThan(bufferManager.lineCount, 0)
    }
}
