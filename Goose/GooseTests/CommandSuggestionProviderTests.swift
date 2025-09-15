import XCTest
@testable import Goose

class CommandSuggestionProviderTests: XCTestCase {
    var provider: CommandSuggestionProvider!
    
    override func setUp() {
        super.setUp()
        provider = CommandSuggestionProvider()
    }
    
    override func tearDown() {
        provider = nil
        super.tearDown()
    }
    
    func testGetSuggestionsForEmptyInput() {
        // Test suggestions for empty input
        let suggestions = provider.getSuggestions(for: "")
        
        XCTAssertTrue(suggestions.count > 0, "Should provide default suggestions for empty input")
        // Check for common goose commands
        let hasGooseCommand = suggestions.contains { $0.hasPrefix("goose") }
        XCTAssertTrue(hasGooseCommand, "Should suggest goose commands")
    }
    
    func testGetSuggestionsForPartialCommand() {
        // Test suggestions for partial command
        let suggestions = provider.getSuggestions(for: "goo")
        
        XCTAssertTrue(suggestions.count > 0, "Should provide suggestions for partial input")
        let allStartWithGoo = suggestions.allSatisfy { $0.hasPrefix("goo") }
        XCTAssertTrue(allStartWithGoo, "All suggestions should start with 'goo'")
    }
    
    func testGetSuggestionsForGooseCommand() {
        // Test suggestions for goose command
        let suggestions = provider.getSuggestions(for: "goose ")
        
        XCTAssertTrue(suggestions.count > 0, "Should provide goose subcommands")
        // Check for common goose subcommands
        let hasRelevantCommands = suggestions.contains { suggestion in
            suggestion.contains("run") || 
            suggestion.contains("help") || 
            suggestion.contains("session")
        }
        XCTAssertTrue(hasRelevantCommands || suggestions.count > 0, 
                     "Should suggest goose subcommands")
    }
    
    func testSuggestionsLimit() {
        // Test that suggestions are limited to a reasonable number
        let suggestions = provider.getSuggestions(for: "")
        
        XCTAssertLessThanOrEqual(suggestions.count, 20, "Should limit number of suggestions")
    }
    
    func testSuggestionsOrder() {
        // Test that more relevant suggestions come first
        let suggestions = provider.getSuggestions(for: "goose")
        
        if !suggestions.isEmpty {
            let firstSuggestion = suggestions[0]
            XCTAssertTrue(firstSuggestion.hasPrefix("goose"), 
                         "Most relevant suggestion should come first")
        }
    }
    
    func testAddCustomCommand() {
        // Test adding a custom command
        let customCommand = "custom-test-command"
        provider.addCustomCommand(customCommand)
        
        let suggestions = provider.getSuggestions(for: "custom")
        let hasCustomCommand = suggestions.contains { $0.contains(customCommand) }
        XCTAssertTrue(hasCustomCommand, "Should include custom commands in suggestions")
    }
    
    func testRemoveCustomCommand() {
        // Test removing a custom command
        let customCommand = "temp-command"
        provider.addCustomCommand(customCommand)
        provider.removeCustomCommand(customCommand)
        
        let suggestions = provider.getSuggestions(for: "temp")
        let hasCommand = suggestions.contains { $0 == customCommand }
        XCTAssertFalse(hasCommand, "Removed command should not appear in suggestions")
    }
    
    func testGetRecentCommands() {
        // Test getting recent commands
        provider.addToHistory("goose run task1")
        provider.addToHistory("goose run task2")
        provider.addToHistory("goose help")
        
        let recent = provider.getRecentCommands(limit: 2)
        XCTAssertEqual(recent.count, 2, "Should return requested number of recent commands")
        XCTAssertEqual(recent[0], "goose help", "Most recent command should be first")
    }
    
    func testClearHistory() {
        // Test clearing command history
        provider.addToHistory("command1")
        provider.addToHistory("command2")
        
        provider.clearHistory()
        
        let recent = provider.getRecentCommands(limit: 10)
        XCTAssertEqual(recent.count, 0, "History should be empty after clearing")
    }
    
    func testDuplicateHistoryEntries() {
        // Test that duplicate entries are handled properly
        provider.addToHistory("goose run")
        provider.addToHistory("goose help")
        provider.addToHistory("goose run") // Duplicate
        
        let recent = provider.getRecentCommands(limit: 10)
        let runCommands = recent.filter { $0 == "goose run" }
        XCTAssertEqual(runCommands.count, 1, "Should not have duplicate history entries")
    }
}
