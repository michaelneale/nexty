//
//  OutputBufferManager.swift
//  Goose
//
//  Manages output buffering with memory limits and file overflow
//

import Foundation
import Combine

/// Manages command output with efficient memory usage and overflow to disk
@MainActor
public class OutputBufferManager: ObservableObject {
    // MARK: - Properties
    
    @Published public private(set) var lineCount: Int = 0
    @Published public private(set) var totalCharacters: Int = 0
    @Published public private(set) var isStreaming: Bool = false
    @Published public private(set) var memoryUsage: Int = 0
    
    private var inMemoryBuffer: [String] = []
    private var overflowFileURL: URL?
    private var overflowFileHandle: FileHandle?
    
    // Configuration
    private let maxMemoryBytes: Int
    private let maxLinesInMemory: Int
    private let chunkSize: Int = 1000 // Lines to process at once
    
    // Thread safety
    private let bufferQueue = DispatchQueue(label: "com.goose.outputbuffer", attributes: .concurrent)
    private let fileQueue = DispatchQueue(label: "com.goose.outputbuffer.file")
    
    // Performance tracking
    private var lastUpdateTime = Date()
    private let updateInterval: TimeInterval = 0.1 // Update UI every 100ms
    
    // MARK: - Initialization
    
    public init(maxMemoryMB: Int = 10) {
        self.maxMemoryBytes = maxMemoryMB * 1024 * 1024
        self.maxLinesInMemory = 10000 // Keep recent lines in memory for fast access
    }
    
    deinit {
        cleanupOverflowFile()
    }
    
    // MARK: - Public Methods
    
    /// Append new output to the buffer
    public func appendOutput(_ output: String) async {
        isStreaming = true
        
        await withCheckedContinuation { continuation in
            bufferQueue.async(flags: .barrier) {
                let lines = output.components(separatedBy: .newlines)
                
                for line in lines {
                    self.appendLine(line)
                }
                
                Task { @MainActor in
                    self.updateMetrics()
                    continuation.resume()
                }
            }
        }
    }
    
    /// Get lines in the specified range
    public func getLines(from startLine: Int, to endLine: Int) async -> [String] {
        await withCheckedContinuation { continuation in
            bufferQueue.async {
                let start = max(0, startLine)
                let end = min(self.lineCount, endLine)
                
                var result: [String] = []
                
                // Check if requested range is in memory
                if start < self.inMemoryBuffer.count {
                    let memoryEnd = min(end, self.inMemoryBuffer.count)
                    result = Array(self.inMemoryBuffer[start..<memoryEnd])
                }
                
                // If we need lines from overflow file
                if end > self.inMemoryBuffer.count && self.overflowFileURL != nil {
                    let overflowLines = self.readLinesFromOverflow(
                        from: max(0, start - self.inMemoryBuffer.count),
                        count: end - max(start, self.inMemoryBuffer.count)
                    )
                    result.append(contentsOf: overflowLines)
                }
                
                continuation.resume(returning: result)
            }
        }
    }
    
    /// Search for text across all buffered output
    public func search(for searchText: String, options: String.CompareOptions = .caseInsensitive) async -> [SearchResult] {
        await withCheckedContinuation { continuation in
            bufferQueue.async {
                var results: [SearchResult] = []
                
                // Search in memory buffer
                for (index, line) in self.inMemoryBuffer.enumerated() {
                    if line.range(of: searchText, options: options) != nil {
                        results.append(SearchResult(lineNumber: index, line: line, matchRanges: []))
                    }
                }
                
                // Search in overflow file if exists
                if self.overflowFileURL != nil {
                    let overflowResults = self.searchInOverflow(for: searchText, options: options, startLine: self.inMemoryBuffer.count)
                    results.append(contentsOf: overflowResults)
                }
                
                continuation.resume(returning: results)
            }
        }
    }
    
    /// Clear all buffered content
    public func clear() {
        bufferQueue.async(flags: .barrier) {
            self.inMemoryBuffer.removeAll()
            self.cleanupOverflowFile()
            
            Task { @MainActor in
                self.lineCount = 0
                self.totalCharacters = 0
                self.memoryUsage = 0
                self.isStreaming = false
            }
        }
    }
    
    /// Stop streaming (called when command completes)
    public func stopStreaming() {
        Task { @MainActor in
            self.isStreaming = false
        }
    }
    
    /// Get all content as a single string (use carefully for large outputs)
    public func getAllContent() async -> String {
        let lines = await getLines(from: 0, to: lineCount)
        return lines.joined(separator: "\n")
    }
    
    // MARK: - Private Methods
    
    private func appendLine(_ line: String) {
        // Check memory usage
        let lineSize = line.utf8.count
        
        if memoryUsage + lineSize > maxMemoryBytes || inMemoryBuffer.count >= maxLinesInMemory {
            // Move oldest lines to overflow file
            moveToOverflow()
        }
        
        inMemoryBuffer.append(line)
        
        Task { @MainActor in
            self.lineCount += 1
            self.totalCharacters += line.count
            self.memoryUsage += lineSize
        }
    }
    
    private func moveToOverflow() {
        fileQueue.sync {
            // Create overflow file if needed
            if overflowFileURL == nil {
                createOverflowFile()
            }
            
            guard let fileHandle = overflowFileHandle else { return }
            
            // Move half of the buffer to file
            let linesToMove = inMemoryBuffer.count / 2
            let lines = Array(inMemoryBuffer.prefix(linesToMove))
            
            for line in lines {
                if let data = (line + "\n").data(using: .utf8) {
                    fileHandle.write(data)
                }
            }
            
            // Remove moved lines from memory
            bufferQueue.async(flags: .barrier) {
                self.inMemoryBuffer.removeFirst(linesToMove)
                
                // Recalculate memory usage
                let newMemoryUsage = self.inMemoryBuffer.reduce(0) { $0 + $1.utf8.count }
                Task { @MainActor in
                    self.memoryUsage = newMemoryUsage
                }
            }
        }
    }
    
    private func createOverflowFile() {
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "goose-output-\(UUID().uuidString).txt"
        overflowFileURL = tempDir.appendingPathComponent(fileName)
        
        guard let url = overflowFileURL else { return }
        
        FileManager.default.createFile(atPath: url.path, contents: nil)
        overflowFileHandle = try? FileHandle(forWritingTo: url)
    }
    
    private func cleanupOverflowFile() {
        fileQueue.sync {
            overflowFileHandle?.closeFile()
            overflowFileHandle = nil
            
            if let url = overflowFileURL {
                try? FileManager.default.removeItem(at: url)
                overflowFileURL = nil
            }
        }
    }
    
    private func readLinesFromOverflow(from startLine: Int, count: Int) -> [String] {
        guard let url = overflowFileURL,
              let fileHandle = try? FileHandle(forReadingFrom: url) else {
            return []
        }
        
        defer { fileHandle.closeFile() }
        
        var lines: [String] = []
        var currentLine = 0
        
        // Read file line by line
        fileHandle.seek(toFileOffset: 0)
        
        while let line = fileHandle.readLine() {
            if currentLine >= startLine && currentLine < startLine + count {
                lines.append(line)
            }
            currentLine += 1
            
            if currentLine >= startLine + count {
                break
            }
        }
        
        return lines
    }
    
    private func searchInOverflow(for searchText: String, options: String.CompareOptions, startLine: Int) -> [SearchResult] {
        guard let url = overflowFileURL,
              let fileHandle = try? FileHandle(forReadingFrom: url) else {
            return []
        }
        
        defer { fileHandle.closeFile() }
        
        var results: [SearchResult] = []
        var currentLine = startLine
        
        fileHandle.seek(toFileOffset: 0)
        
        while let line = fileHandle.readLine() {
            if line.range(of: searchText, options: options) != nil {
                results.append(SearchResult(lineNumber: currentLine, line: line, matchRanges: []))
            }
            currentLine += 1
        }
        
        return results
    }
    
    private func updateMetrics() {
        let now = Date()
        if now.timeIntervalSince(lastUpdateTime) >= updateInterval {
            lastUpdateTime = now
            // Metrics are already updated via @Published properties
        }
    }
}

// MARK: - Supporting Types

public struct SearchResult {
    public let lineNumber: Int
    public let line: String
    public let matchRanges: [Range<String.Index>]
}

// MARK: - FileHandle Extension

extension FileHandle {
    func readLine() -> String? {
        var lineData = Data()
        
        while true {
            let chunk = self.readData(ofLength: 1)
            if chunk.isEmpty {
                return lineData.isEmpty ? nil : String(data: lineData, encoding: .utf8)
            }
            
            if let byte = chunk.first {
                if byte == 10 { // newline character
                    return String(data: lineData, encoding: .utf8)
                }
                lineData.append(chunk)
            }
        }
    }
}
