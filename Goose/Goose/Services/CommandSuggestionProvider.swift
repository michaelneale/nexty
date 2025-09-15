//
//  CommandSuggestionProvider.swift
//  Goose
//
//  Created on 2024-09-15
//

import Foundation

/// Provides command suggestions and autocomplete functionality
class CommandSuggestionProvider {
    
    // Common goose commands and their descriptions
    private let commonCommands = [
        ("help", "Show help information"),
        ("version", "Show version information"),
        ("run", "Run a goose session"),
        ("session", "Manage goose sessions"),
        ("session start", "Start a new session"),
        ("session resume", "Resume an existing session"),
        ("session list", "List all sessions"),
        ("session clear", "Clear session history"),
        ("config", "Configure goose settings"),
        ("config set", "Set a configuration value"),
        ("config get", "Get a configuration value"),
        ("config list", "List all configuration"),
        ("provider", "Manage AI providers"),
        ("provider list", "List available providers"),
        ("provider set", "Set the active provider"),
        ("toolkit", "Manage toolkits"),
        ("toolkit list", "List available toolkits"),
        ("toolkit enable", "Enable a toolkit"),
        ("toolkit disable", "Disable a toolkit")
    ]
    
    /// Get suggestions for the given input text
    func getSuggestions(for text: String, history: [String]) -> [CommandSuggestion] {
        let lowercasedText = text.lowercased()
        var suggestions: [CommandSuggestion] = []
        
        // Add suggestions from common commands
        for (command, description) in commonCommands {
            if let confidence = fuzzyMatch(query: lowercasedText, in: command) {
                suggestions.append(CommandSuggestion(
                    fullCommand: command,
                    displayText: "\(command) - \(description)",
                    confidence: confidence
                ))
            }
        }
        
        // Add suggestions from history (with slightly lower confidence)
        for historyCommand in history.reversed() {
            if let confidence = fuzzyMatch(query: lowercasedText, in: historyCommand.lowercased()) {
                // Check if not already in suggestions
                if !suggestions.contains(where: { $0.fullCommand == historyCommand }) {
                    suggestions.append(CommandSuggestion(
                        fullCommand: historyCommand,
                        displayText: historyCommand,
                        confidence: confidence * 0.9 // Slightly lower priority than common commands
                    ))
                }
            }
        }
        
        // Sort by confidence and limit to top 5
        suggestions.sort { $0.confidence > $1.confidence }
        return Array(suggestions.prefix(5))
    }
    
    /// Fuzzy matching algorithm
    private func fuzzyMatch(query: String, in text: String) -> Double? {
        guard !query.isEmpty else { return nil }
        
        // If query is longer than text, no match
        if query.count > text.count { return nil }
        
        // Check if text starts with query (highest confidence)
        if text.hasPrefix(query) {
            return 1.0
        }
        
        // Check if all query characters appear in order in text
        var queryIndex = query.startIndex
        var textIndex = text.startIndex
        var matchedChars = 0
        var lastMatchIndex: String.Index?
        
        while queryIndex < query.endIndex && textIndex < text.endIndex {
            if query[queryIndex] == text[textIndex] {
                matchedChars += 1
                lastMatchIndex = textIndex
                queryIndex = query.index(after: queryIndex)
            }
            textIndex = text.index(after: textIndex)
        }
        
        // If we didn't match all query characters, no match
        if matchedChars != query.count { return nil }
        
        // Calculate confidence based on:
        // 1. How early the match starts
        // 2. How compact the match is
        let startPosition = text.distance(from: text.startIndex, to: text.firstIndex(of: query.first!)!)
        let matchSpread = lastMatchIndex.map { text.distance(from: text.startIndex, to: $0) } ?? text.count
        
        let positionScore = 1.0 - (Double(startPosition) / Double(text.count))
        let compactnessScore = Double(query.count) / Double(matchSpread + 1)
        
        return (positionScore + compactnessScore) / 2.0
    }
    
    /// Get command completion for partial input
    func getCompletion(for text: String) -> String? {
        let lowercasedText = text.lowercased()
        
        // Find first command that starts with the text
        for (command, _) in commonCommands {
            if command.hasPrefix(lowercasedText) && command != lowercasedText {
                return command
            }
        }
        
        return nil
    }
}
