//
//  OutputParser+Plugin.swift
//  Goose
//
//  Created by Goose on 15/09/2025.
//

import Foundation

// MARK: - Plugin Support for OutputParser

extension OutputParser {
    /// Type alias for output formatters
    public typealias OutputFormatter = (String) -> String
    public typealias ParsedOutputFormatter = (ParsedOutput) -> ParsedOutput
    
    /// Storage for plugin output formatters
    private struct PluginFormatters {
        static var textFormatters: [(pluginId: String, formatter: OutputFormatter)] = []
        static var parsedFormatters: [(pluginId: String, formatter: ParsedOutputFormatter)] = []
        static let lock = NSLock()
    }
    
    // MARK: - Registration
    
    /// Register a text output formatter from a plugin
    public func registerFormatter(
        from pluginId: String,
        formatter: @escaping OutputFormatter
    ) {
        PluginFormatters.lock.lock()
        defer { PluginFormatters.lock.unlock() }
        
        // Remove any existing formatter from this plugin
        PluginFormatters.textFormatters.removeAll { $0.pluginId == pluginId }
        
        // Add the new formatter
        PluginFormatters.textFormatters.append((pluginId, formatter))
    }
    
    /// Register a parsed output formatter from a plugin
    public func registerParsedFormatter(
        from pluginId: String,
        formatter: @escaping ParsedOutputFormatter
    ) {
        PluginFormatters.lock.lock()
        defer { PluginFormatters.lock.unlock() }
        
        // Remove any existing formatter from this plugin
        PluginFormatters.parsedFormatters.removeAll { $0.pluginId == pluginId }
        
        // Add the new formatter
        PluginFormatters.parsedFormatters.append((pluginId, formatter))
    }
    
    // MARK: - Unregistration
    
    /// Unregister all formatters from a plugin
    public func unregisterFormatters(from pluginId: String) {
        PluginFormatters.lock.lock()
        defer { PluginFormatters.lock.unlock() }
        
        PluginFormatters.textFormatters.removeAll { $0.pluginId == pluginId }
        PluginFormatters.parsedFormatters.removeAll { $0.pluginId == pluginId }
    }
    
    // MARK: - Processing
    
    /// Apply all registered text formatters to output
    internal func applyTextFormatters(to text: String) -> String {
        var formattedText = text
        
        PluginFormatters.lock.lock()
        let formatters = PluginFormatters.textFormatters
        PluginFormatters.lock.unlock()
        
        for (pluginId, formatter) in formatters {
            formattedText = formatter(formattedText)
            print("[OutputParser] Applied text formatter from plugin: \(pluginId)")
        }
        
        return formattedText
    }
    
    /// Apply all registered parsed formatters to output
    internal func applyParsedFormatters(to output: ParsedOutput) -> ParsedOutput {
        var formattedOutput = output
        
        PluginFormatters.lock.lock()
        let formatters = PluginFormatters.parsedFormatters
        PluginFormatters.lock.unlock()
        
        for (pluginId, formatter) in formatters {
            formattedOutput = formatter(formattedOutput)
            print("[OutputParser] Applied parsed formatter from plugin: \(pluginId)")
        }
        
        return formattedOutput
    }
    
    /// Parse output with plugin formatters applied
    public func parseWithPlugins(_ content: String) -> ParsedOutput {
        // Apply text formatters first
        let formattedContent = applyTextFormatters(to: content)
        
        // Parse the formatted content
        let parsedOutput = parse(formattedContent)
        
        // Apply parsed formatters
        return applyParsedFormatters(to: parsedOutput)
    }
}

// MARK: - Plugin Output Formatter Protocols

/// Protocol for plugins that want to format text output
public protocol OutputFormatterPlugin {
    /// Format raw text output
    func formatOutput(_ text: String) -> String
}

/// Protocol for plugins that want to format parsed output
public protocol ParsedOutputFormatterPlugin {
    /// Format parsed output
    func formatParsedOutput(_ output: OutputParser.ParsedOutput) -> OutputParser.ParsedOutput
}

// MARK: - Output Enhancement Helpers

extension OutputParser.ParsedOutput {
    /// Add syntax highlighting to code blocks (for plugins to use)
    public func withSyntaxHighlighting(language: String? = nil) -> OutputParser.ParsedOutput {
        switch self {
        case .plain(let text):
            // Could apply syntax highlighting based on language detection
            return .plain(text)
        case .markdown(let text):
            // Could enhance markdown code blocks
            return .markdown(text)
        default:
            return self
        }
    }
    
    /// Add line numbers to output (for plugins to use)
    public func withLineNumbers() -> OutputParser.ParsedOutput {
        switch self {
        case .plain(let text):
            let lines = text.split(separator: "\n")
            let numberedLines = lines.enumerated().map { index, line in
                String(format: "%4d | %@", index + 1, String(line))
            }
            return .plain(numberedLines.joined(separator: "\n"))
        default:
            return self
        }
    }
    
    /// Truncate output to a maximum number of lines (for plugins to use)
    public func truncated(to maxLines: Int) -> OutputParser.ParsedOutput {
        guard maxLines > 0 else { return self }
        
        switch self {
        case .plain(let text):
            let lines = text.split(separator: "\n")
            if lines.count <= maxLines {
                return self
            }
            let truncated = lines.prefix(maxLines)
            let result = truncated.joined(separator: "\n") + "\n... (\(lines.count - maxLines) more lines)"
            return .plain(result)
        case .markdown(let text):
            let lines = text.split(separator: "\n")
            if lines.count <= maxLines {
                return self
            }
            let truncated = lines.prefix(maxLines)
            let result = truncated.joined(separator: "\n") + "\n\n_... (\(lines.count - maxLines) more lines)_"
            return .markdown(result)
        default:
            return self
        }
    }
}

// MARK: - Custom Output Types for Plugins

extension OutputParser {
    /// Additional parsed output types that plugins might produce
    public enum ExtendedParsedOutput {
        case table([[String]])  // Table data
        case chart(ChartData)   // Chart/graph data
        case image(Data)        // Image data
        case html(String)       // HTML content
        case custom(String, Any) // Custom type with identifier
    }
    
    /// Chart data structure for plugins
    public struct ChartData {
        public let type: ChartType
        public let labels: [String]
        public let datasets: [Dataset]
        
        public enum ChartType {
            case line
            case bar
            case pie
            case scatter
        }
        
        public struct Dataset {
            public let label: String
            public let values: [Double]
            public let color: String?
            
            public init(label: String, values: [Double], color: String? = nil) {
                self.label = label
                self.values = values
                self.color = color
            }
        }
        
        public init(type: ChartType, labels: [String], datasets: [Dataset]) {
            self.type = type
            self.labels = labels
            self.datasets = datasets
        }
    }
}
