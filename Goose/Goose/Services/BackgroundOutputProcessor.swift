//
//  BackgroundOutputProcessor.swift
//  Goose
//
//  Processes command output in background for performance
//

import Foundation
import Combine

/// Processes command output in background threads to avoid blocking UI
public actor BackgroundOutputProcessor {
    // MARK: - Properties
    
    private let bufferManager: OutputBufferManager
    private let processingQueue = DispatchQueue(label: "com.goose.outputprocessor", qos: .userInitiated, attributes: .concurrent)
    private var cancellables = Set<AnyCancellable>()
    
    // Chunk processing configuration
    private let chunkSize = 4096 // Process 4KB chunks at a time
    private let maxConcurrentChunks = 4
    
    // Syntax highlighting cache
    private var highlightCache = [String: NSAttributedString]()
    private let cacheLimit = 100 // Limit cache size
    
    // Performance metrics
    private var processedBytes: Int = 0
    private var processingStartTime: Date?
    
    // MARK: - Initialization
    
    public init(bufferManager: OutputBufferManager) {
        self.bufferManager = bufferManager
    }
    
    // MARK: - Public Methods
    
    /// Process raw output asynchronously
    public func processOutput(_ rawOutput: String) async {
        processingStartTime = processingStartTime ?? Date()
        
        // Split into chunks for parallel processing
        let chunks = splitIntoChunks(rawOutput)
        
        await withTaskGroup(of: ProcessedChunk.self) { group in
            // Limit concurrent processing
            var activeChunks = 0
            var chunkIndex = 0
            
            while chunkIndex < chunks.count || activeChunks > 0 {
                // Add new chunks if under limit
                while activeChunks < maxConcurrentChunks && chunkIndex < chunks.count {
                    let chunk = chunks[chunkIndex]
                    group.addTask {
                        await self.processChunk(chunk)
                    }
                    activeChunks += 1
                    chunkIndex += 1
                }
                
                // Process completed chunks
                if let processedChunk = await group.next() {
                    await handleProcessedChunk(processedChunk)
                    activeChunks -= 1
                }
            }
        }
        
        // Update metrics
        processedBytes += rawOutput.utf8.count
        logPerformanceMetrics()
    }
    
    /// Apply syntax highlighting to text
    public func applySyntaxHighlighting(to text: String) async -> NSAttributedString {
        // Check cache first
        if let cached = highlightCache[text] {
            return cached
        }
        
        return await Task.detached(priority: .userInitiated) {
            let attributedString = NSMutableAttributedString(string: text)
            
            // Apply basic syntax highlighting
            self.highlightKeywords(in: attributedString)
            self.highlightStrings(in: attributedString)
            self.highlightNumbers(in: attributedString)
            self.highlightComments(in: attributedString)
            self.highlightErrors(in: attributedString)
            
            // Cache result
            await self.cacheHighlightedString(text, attributedString: attributedString)
            
            return attributedString
        }.value
    }
    
    /// Clear all caches and reset state
    public func reset() {
        highlightCache.removeAll()
        processedBytes = 0
        processingStartTime = nil
    }
    
    // MARK: - Private Methods
    
    private func splitIntoChunks(_ text: String) -> [String] {
        var chunks: [String] = []
        var currentChunk = ""
        var currentSize = 0
        
        // Split by lines to maintain line integrity
        let lines = text.components(separatedBy: .newlines)
        
        for line in lines {
            let lineSize = line.utf8.count
            
            if currentSize + lineSize > chunkSize && !currentChunk.isEmpty {
                chunks.append(currentChunk)
                currentChunk = line
                currentSize = lineSize
            } else {
                if !currentChunk.isEmpty {
                    currentChunk += "\n"
                }
                currentChunk += line
                currentSize += lineSize + 1
            }
        }
        
        if !currentChunk.isEmpty {
            chunks.append(currentChunk)
        }
        
        return chunks
    }
    
    private func processChunk(_ chunk: String) async -> ProcessedChunk {
        // Apply any transformations or parsing
        let processed = await Task.detached(priority: .userInitiated) {
            // Remove ANSI escape codes
            let cleanedChunk = self.removeANSIEscapeCodes(from: chunk)
            
            // Detect and mark special content
            let hasErrors = self.detectErrors(in: cleanedChunk)
            let hasWarnings = self.detectWarnings(in: cleanedChunk)
            
            return ProcessedChunk(
                content: cleanedChunk,
                hasErrors: hasErrors,
                hasWarnings: hasWarnings,
                originalSize: chunk.count,
                processedSize: cleanedChunk.count
            )
        }.value
        
        return processed
    }
    
    private func handleProcessedChunk(_ chunk: ProcessedChunk) async {
        // Send to buffer manager
        await bufferManager.appendOutput(chunk.content)
        
        // Log if chunk has errors or warnings
        if chunk.hasErrors {
            logError("Errors detected in output chunk")
        }
        if chunk.hasWarnings {
            logWarning("Warnings detected in output chunk")
        }
    }
    
    private func removeANSIEscapeCodes(from text: String) -> String {
        // Remove ANSI escape sequences
        let pattern = "\\x1B\\[[0-9;]*[mGKH]"
        return text.replacingOccurrences(of: pattern, with: "", options: .regularExpression)
    }
    
    private func detectErrors(in text: String) -> Bool {
        let errorPatterns = [
            "error:",
            "ERROR:",
            "Error:",
            "fatal:",
            "FATAL:",
            "Failed",
            "FAILED",
            "exception",
            "Exception"
        ]
        
        return errorPatterns.contains { text.contains($0) }
    }
    
    private func detectWarnings(in text: String) -> Bool {
        let warningPatterns = [
            "warning:",
            "WARNING:",
            "Warning:",
            "warn:",
            "WARN:"
        ]
        
        return warningPatterns.contains { text.contains($0) }
    }
    
    // MARK: - Syntax Highlighting
    
    private func highlightKeywords(in attributedString: NSMutableAttributedString) {
        let keywords = ["func", "var", "let", "class", "struct", "enum", "protocol", "import", "if", "else", "for", "while", "return", "async", "await", "try", "catch", "throw"]
        
        for keyword in keywords {
            highlightPattern("\\b\(keyword)\\b", color: .systemPurple, in: attributedString)
        }
    }
    
    private func highlightStrings(in attributedString: NSMutableAttributedString) {
        // Highlight strings in quotes
        highlightPattern("\"[^\"]*\"", color: .systemRed, in: attributedString)
        highlightPattern("'[^']*'", color: .systemRed, in: attributedString)
    }
    
    private func highlightNumbers(in attributedString: NSMutableAttributedString) {
        // Highlight numbers
        highlightPattern("\\b[0-9]+\\.?[0-9]*\\b", color: .systemBlue, in: attributedString)
    }
    
    private func highlightComments(in attributedString: NSMutableAttributedString) {
        // Highlight single-line comments
        highlightPattern("//.*$", color: .systemGray, in: attributedString, options: [.anchorsMatchLines])
        // Highlight multi-line comments
        highlightPattern("/\\*[^*]*\\*+(?:[^/*][^*]*\\*+)*/", color: .systemGray, in: attributedString)
    }
    
    private func highlightErrors(in attributedString: NSMutableAttributedString) {
        // Highlight error patterns
        let errorPatterns = ["error:", "ERROR:", "Error:", "fatal:", "FATAL:"]
        for pattern in errorPatterns {
            highlightPattern(".*\(pattern).*$", color: .systemRed, in: attributedString, options: [.anchorsMatchLines, .caseInsensitive])
        }
    }
    
    private func highlightPattern(_ pattern: String, color: NSColor, in attributedString: NSMutableAttributedString, options: NSRegularExpression.Options = []) {
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: options)
            let range = NSRange(location: 0, length: attributedString.length)
            
            regex.enumerateMatches(in: attributedString.string, options: [], range: range) { match, _, _ in
                if let matchRange = match?.range {
                    attributedString.addAttribute(.foregroundColor, value: color, range: matchRange)
                }
            }
        } catch {
            // Ignore regex errors
        }
    }
    
    private func cacheHighlightedString(_ original: String, attributedString: NSAttributedString) async {
        // Limit cache size
        if highlightCache.count >= cacheLimit {
            // Remove oldest entries (simple FIFO for now)
            highlightCache.removeAll()
        }
        
        highlightCache[original] = attributedString as? NSAttributedString
    }
    
    // MARK: - Performance Monitoring
    
    private func logPerformanceMetrics() {
        guard let startTime = processingStartTime else { return }
        
        let elapsed = Date().timeIntervalSince(startTime)
        let throughput = Double(processedBytes) / elapsed / 1024.0 / 1024.0 // MB/s
        
        if elapsed > 10 { // Log every 10 seconds
            print("Output processing: \(String(format: "%.2f", throughput)) MB/s, Total: \(processedBytes / 1024 / 1024) MB")
            processingStartTime = Date()
            processedBytes = 0
        }
    }
    
    private func logError(_ message: String) {
        #if DEBUG
        print("❌ [BackgroundOutputProcessor] \(message)")
        #endif
    }
    
    private func logWarning(_ message: String) {
        #if DEBUG
        print("⚠️ [BackgroundOutputProcessor] \(message)")
        #endif
    }
}

// MARK: - Supporting Types

private struct ProcessedChunk {
    let content: String
    let hasErrors: Bool
    let hasWarnings: Bool
    let originalSize: Int
    let processedSize: Int
}

// MARK: - NSColor Extension for Cross-platform Compatibility

#if os(macOS)
import AppKit
#else
import UIKit
typealias NSColor = UIColor
typealias NSAttributedString = AttributedString
#endif

extension NSColor {
    static let systemPurple = NSColor.purple
    static let systemRed = NSColor.red
    static let systemBlue = NSColor.blue
    static let systemGray = NSColor.gray
}
