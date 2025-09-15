//
//  PerformanceMonitor.swift
//  Goose
//
//  Utilities for monitoring and tracking performance metrics
//

import Foundation
import QuartzCore
import os.log

/// Monitors performance metrics for the application
public class PerformanceMonitor {
    // MARK: - Singleton
    
    public static let shared = PerformanceMonitor()
    
    // MARK: - Properties
    
    private let logger = Logger(subsystem: "com.goose", category: "Performance")
    private var metricsQueue = DispatchQueue(label: "com.goose.performance", qos: .utility)
    
    // Performance tracking
    private var frameRates: [Double] = []
    private var memoryUsages: [Int] = []
    private var cpuUsages: [Double] = []
    
    // Timing
    private var fpsTimer: Timer?
    private var lastFrameTime: CFTimeInterval = 0
    
    // Thresholds
    private let targetFPS: Double = 60.0
    private let maxMemoryMB: Int = 500
    
    // MARK: - Initialization
    
    private init() {
        startMonitoring()
    }
    
    deinit {
        stopMonitoring()
    }
    
    // MARK: - Public Methods
    
    /// Start monitoring performance metrics
    public func startMonitoring() {
        setupDisplayLink()
        startMemoryMonitoring()
        startCPUMonitoring()
    }
    
    /// Stop monitoring performance metrics
    public func stopMonitoring() {
        fpsTimer?.invalidate()
        fpsTimer = nil
    }
    
    /// Get current FPS
    public func getCurrentFPS() -> Double {
        guard !frameRates.isEmpty else { return 0 }
        return frameRates.last ?? 0
    }
    
    /// Get average FPS over last period
    public func getAverageFPS() -> Double {
        guard !frameRates.isEmpty else { return 0 }
        return frameRates.reduce(0, +) / Double(frameRates.count)
    }
    
    /// Get current memory usage in MB
    public func getCurrentMemoryUsage() -> Int {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if result == KERN_SUCCESS {
            return Int(info.resident_size / 1024 / 1024) // Convert to MB
        }
        
        return 0
    }
    
    /// Get CPU usage percentage
    public func getCurrentCPUUsage() -> Double {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if result == KERN_SUCCESS {
            // This is a simplified CPU calculation
            // For more accurate results, you'd need to track thread times
            return Double(info.user_time.seconds + info.system_time.seconds) / 100.0
        }
        
        return 0
    }
    
    /// Check if performance is within acceptable bounds
    public func isPerformanceAcceptable() -> Bool {
        let fps = getAverageFPS()
        let memory = getCurrentMemoryUsage()
        
        return fps >= (targetFPS * 0.9) && memory < maxMemoryMB
    }
    
    /// Log performance metrics
    public func logMetrics() {
        let fps = getAverageFPS()
        let memory = getCurrentMemoryUsage()
        let cpu = getCurrentCPUUsage()
        
        logger.info("Performance: FPS=\(fps, format: .fixed(precision: 1)), Memory=\(memory)MB, CPU=\(cpu, format: .fixed(precision: 1))%")
        
        if fps < targetFPS * 0.8 {
            logger.warning("Low FPS detected: \(fps, format: .fixed(precision: 1))")
        }
        
        if memory > maxMemoryMB * 0.9 {
            logger.warning("High memory usage: \(memory)MB")
        }
    }
    
    /// Measure execution time of a block
    public func measureTime<T>(label: String, block: () throws -> T) rethrows -> T {
        let startTime = CACurrentMediaTime()
        defer {
            let elapsed = CACurrentMediaTime() - startTime
            logger.debug("\(label) took \(elapsed * 1000, format: .fixed(precision: 2))ms")
        }
        return try block()
    }
    
    /// Measure async execution time
    public func measureTimeAsync<T>(label: String, block: () async throws -> T) async rethrows -> T {
        let startTime = CACurrentMediaTime()
        defer {
            let elapsed = CACurrentMediaTime() - startTime
            logger.debug("\(label) took \(elapsed * 1000, format: .fixed(precision: 2))ms")
        }
        return try await block()
    }
    
    // MARK: - Private Methods
    
    private func setupDisplayLink() {
        // Use timer-based FPS monitoring for all macOS versions
        fpsTimer = Timer.scheduledTimer(withTimeInterval: 1.0/60.0, repeats: true) { _ in
            self.updateFrameRateWithTimer()
        }
    }
    
    private func updateFrameRateWithTimer() {
        let now = CACurrentMediaTime()
        if lastFrameTime == 0 {
            lastFrameTime = now
            return
        }
        
        let elapsed = now - lastFrameTime
        lastFrameTime = now
        
        let fps = 1.0 / elapsed
        
        metricsQueue.async {
            self.frameRates.append(fps)
            
            // Keep only last 60 samples (1 second at 60fps)
            if self.frameRates.count > 60 {
                self.frameRates.removeFirst()
            }
        }
    }
    
    private func startMemoryMonitoring() {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            let memory = self.getCurrentMemoryUsage()
            
            self.metricsQueue.async {
                self.memoryUsages.append(memory)
                
                // Keep only last 60 samples
                if self.memoryUsages.count > 60 {
                    self.memoryUsages.removeFirst()
                }
            }
        }
    }
    
    private func startCPUMonitoring() {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            let cpu = self.getCurrentCPUUsage()
            
            self.metricsQueue.async {
                self.cpuUsages.append(cpu)
                
                // Keep only last 60 samples
                if self.cpuUsages.count > 60 {
                    self.cpuUsages.removeFirst()
                }
            }
        }
    }
}

// MARK: - Performance Testing Utilities

public struct PerformanceTest {
    /// Generate test output with specified number of lines
    public static func generateTestOutput(lines: Int, charactersPerLine: Int = 80) -> String {
        var output = ""
        
        for i in 0..<lines {
            let line = "Line \(i): " + String(repeating: "x", count: charactersPerLine - 10)
            output += line + "\n"
        }
        
        return output
    }
    
    /// Test scrolling performance
    public static func testScrollingPerformance(completion: @escaping (Bool) -> Void) {
        let monitor = PerformanceMonitor.shared
        
        // Reset metrics
        monitor.startMonitoring()
        
        // Wait for metrics to stabilize
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            let fps = monitor.getAverageFPS()
            let acceptable = monitor.isPerformanceAcceptable()
            
            monitor.logMetrics()
            completion(acceptable)
        }
    }
    
    /// Test memory usage with large output
    public static func testMemoryUsage(outputSize: Int, completion: @escaping (Bool) -> Void) {
        let monitor = PerformanceMonitor.shared
        let initialMemory = monitor.getCurrentMemoryUsage()
        
        // Generate large output
        _ = generateTestOutput(lines: outputSize)
        
        // Check memory after generation
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            let finalMemory = monitor.getCurrentMemoryUsage()
            let memoryIncrease = finalMemory - initialMemory
            
            print("Memory increased by \(memoryIncrease)MB for \(outputSize) lines")
            
            // Check if memory increase is reasonable
            let acceptable = memoryIncrease < 100 // Less than 100MB increase
            completion(acceptable)
        }
    }
}
