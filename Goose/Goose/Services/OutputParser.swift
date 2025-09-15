import Foundation

/// Parse and structure CLI output
public class OutputParser {
    
    /// Parse output content based on its format
    public func parse(_ content: String) -> ParsedOutput {
        // Try to parse as JSON first
        if let jsonOutput = parseJSON(content) {
            return .json(jsonOutput)
        }
        
        // Check for ANSI codes
        if containsANSI(content) {
            return .ansi(stripANSI(content))
        }
        
        // Check for markdown-like formatting
        if isMarkdown(content) {
            return .markdown(content)
        }
        
        // Default to plain text
        return .plain(content)
    }
    
    /// Parsed output types
    public enum ParsedOutput {
        case plain(String)
        case json([String: Any])
        case ansi(String)  // ANSI stripped text
        case markdown(String)
        
        /// Get the display text for the output
        public var displayText: String {
            switch self {
            case .plain(let text):
                return text
            case .json(let dict):
                if let data = try? JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted),
                   let string = String(data: data, encoding: .utf8) {
                    return string
                }
                return String(describing: dict)
            case .ansi(let text):
                return text
            case .markdown(let text):
                return text
            }
        }
        
        /// Check if output is structured data
        public var isStructured: Bool {
            switch self {
            case .json:
                return true
            default:
                return false
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func parseJSON(_ content: String) -> [String: Any]? {
        guard let data = content.data(using: .utf8) else { return nil }
        
        do {
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                return json
            }
        } catch {
            // Not valid JSON
        }
        
        return nil
    }
    
    private func containsANSI(_ content: String) -> Bool {
        // Check for common ANSI escape sequences
        let ansiPattern = "\\x1B\\[[0-9;]*m"
        return content.range(of: ansiPattern, options: .regularExpression) != nil
    }
    
    private func stripANSI(_ content: String) -> String {
        let ansiPattern = "\\x1B\\[[0-9;]*m"
        return content.replacingOccurrences(of: ansiPattern, with: "", options: .regularExpression)
    }
    
    private func isMarkdown(_ content: String) -> Bool {
        // Simple heuristic: check for common markdown patterns
        let markdownPatterns = [
            "^#+\\s",      // Headers
            "^\\*\\s",     // Bullet points
            "^\\d+\\.\\s", // Numbered lists
            "\\*\\*.+\\*\\*", // Bold text
            "\\[.+\\]\\(.+\\)", // Links
            "```"          // Code blocks
        ]
        
        for pattern in markdownPatterns {
            if content.range(of: pattern, options: .regularExpression) != nil {
                return true
            }
        }
        
        return false
    }
}

/// Extension to extract specific information from parsed output
public extension OutputParser.ParsedOutput {
    
    /// Extract error messages if present
    var errorMessage: String? {
        switch self {
        case .plain(let text), .ansi(let text), .markdown(let text):
            // Look for common error patterns
            let errorPatterns = [
                "error:",
                "Error:",
                "ERROR:",
                "failed:",
                "Failed:"
            ]
            
            for pattern in errorPatterns {
                if let range = text.range(of: pattern, options: .caseInsensitive) {
                    let errorStart = text.index(range.lowerBound, offsetBy: 0)
                    if let lineEnd = text[errorStart...].firstIndex(of: "\n") {
                        return String(text[errorStart..<lineEnd])
                    } else {
                        return String(text[errorStart...])
                    }
                }
            }
            
        case .json(let dict):
            // Check for error field in JSON
            if let error = dict["error"] as? String {
                return error
            }
            if let message = dict["message"] as? String,
               let status = dict["status"] as? String,
               status.lowercased() == "error" {
                return message
            }
        }
        
        return nil
    }
    
    /// Extract progress information if present
    var progressInfo: (current: Int, total: Int)? {
        let progressPattern = "(\\d+)\\s*/\\s*(\\d+)|\\[(\\d+)/(\\d+)\\]"
        
        switch self {
        case .plain(let text), .ansi(let text):
            if let match = text.range(of: progressPattern, options: .regularExpression) {
                let progressText = String(text[match])
                let numbers = progressText.components(separatedBy: CharacterSet.decimalDigits.inverted)
                    .compactMap { Int($0) }
                
                if numbers.count >= 2 {
                    return (current: numbers[0], total: numbers[1])
                }
            }
            
        case .json(let dict):
            if let progress = dict["progress"] as? [String: Any],
               let current = progress["current"] as? Int,
               let total = progress["total"] as? Int {
                return (current: current, total: total)
            }
            
        default:
            break
        }
        
        return nil
    }
}
