//
//  CommandInputViewModel.swift
//  Goose
//
//  Created on 2024-09-15
//

import SwiftUI
import Combine

/// View model managing command input state and execution
@MainActor
class CommandInputViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var commandText: String = ""
    @Published var isLoading: Bool = false
    @Published var suggestions: [CommandSuggestion] = []
    @Published var selectedSuggestionIndex: Int = -1
    @Published var commandHistory: [String] = []
    @Published var historyIndex: Int = -1
    @Published var inlineResult: CommandResult?
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    private let commandExecutor = CommandExecutor()
    private let outputParser = OutputParser()
    private let suggestionProvider = CommandSuggestionProvider()
    private var cancellables = Set<AnyCancellable>()
    private var currentCommand: GooseCommand?
    private var outputBuffer = ""
    private let maxInlineLines = 5
    private let debounceInterval: TimeInterval = 0.3
    
    // Callback for opening main window with full output
    var onOpenMainWindow: ((GooseCommand, String) -> Void)?
    
    init() {
        setupBindings()
        loadCommandHistory()
    }
    
    // MARK: - Public Methods
    
    /// Execute the current command
    func executeCommand() {
        let trimmedCommand = commandText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedCommand.isEmpty else { return }
        
        // Add to history
        addToHistory(trimmedCommand)
        
        // Parse command
        let components = parseCommandComponents(trimmedCommand)
        let command = GooseCommand(command: components.first ?? "", arguments: Array(components.dropFirst()))
        currentCommand = command
        
        // Clear previous results
        inlineResult = nil
        errorMessage = nil
        outputBuffer = ""
        
        // Start loading
        isLoading = true
        
        // Execute command
        Task {
            do {
                try await commandExecutor.execute(command: command) { [weak self] output, type in
                    self?.handleCommandOutput(output, type: type)
                }
                
                await MainActor.run {
                    self.completeCommandExecution()
                }
            } catch {
                await MainActor.run {
                    self.handleExecutionError(error)
                }
            }
        }
    }
    
    /// Handle arrow key navigation
    func handleArrowKey(_ direction: ArrowDirection) {
        switch direction {
        case .up:
            if !suggestions.isEmpty && selectedSuggestionIndex > -1 {
                // Navigate suggestions
                selectedSuggestionIndex = max(0, selectedSuggestionIndex - 1)
            } else if !commandHistory.isEmpty {
                // Navigate history
                if historyIndex == -1 {
                    historyIndex = commandHistory.count - 1
                } else if historyIndex > 0 {
                    historyIndex -= 1
                }
                if historyIndex >= 0 && historyIndex < commandHistory.count {
                    commandText = commandHistory[historyIndex]
                }
            }
            
        case .down:
            if !suggestions.isEmpty && selectedSuggestionIndex < suggestions.count - 1 {
                // Navigate suggestions
                selectedSuggestionIndex += 1
            } else if historyIndex != -1 {
                // Navigate history
                if historyIndex < commandHistory.count - 1 {
                    historyIndex += 1
                    commandText = commandHistory[historyIndex]
                } else {
                    historyIndex = -1
                    commandText = ""
                }
            }
        }
    }
    
    /// Handle tab key for autocomplete
    func handleTabKey() {
        if !suggestions.isEmpty {
            if selectedSuggestionIndex == -1 {
                selectedSuggestionIndex = 0
            }
            applySuggestion(at: selectedSuggestionIndex)
        }
    }
    
    /// Apply a suggestion at the given index
    func applySuggestion(at index: Int) {
        guard index >= 0 && index < suggestions.count else { return }
        
        let suggestion = suggestions[index]
        commandText = suggestion.fullCommand
        suggestions = []
        selectedSuggestionIndex = -1
    }
    
    /// Cancel the current command execution
    func cancelExecution() {
        if let command = currentCommand {
            commandExecutor.cancel(commandId: command.id)
            isLoading = false
            errorMessage = "Command cancelled"
        }
    }
    
    // MARK: - Private Methods
    
    private func setupBindings() {
        // Debounced suggestion updates
        $commandText
            .debounce(for: .seconds(debounceInterval), scheduler: RunLoop.main)
            .sink { [weak self] text in
                self?.updateSuggestions(for: text)
            }
            .store(in: &cancellables)
    }
    
    private func updateSuggestions(for text: String) {
        guard !text.isEmpty else {
            suggestions = []
            selectedSuggestionIndex = -1
            return
        }
        
        suggestions = suggestionProvider.getSuggestions(for: text, history: commandHistory)
        selectedSuggestionIndex = -1
    }
    
    private func handleCommandOutput(_ output: String, type: ResponseType) {
        outputBuffer += output
        
        // Count lines
        let lines = outputBuffer.components(separatedBy: .newlines)
        
        // Update inline result
        if lines.count <= maxInlineLines {
            inlineResult = CommandResult(
                output: outputBuffer,
                type: type,
                lineCount: lines.count
            )
        } else {
            // Too many lines, prepare to open main window
            if let command = currentCommand {
                onOpenMainWindow?(command, outputBuffer)
            }
            // Clear inline result as we're switching to main window
            inlineResult = nil
        }
    }
    
    private func completeCommandExecution() {
        isLoading = false
        
        // If we still have inline result (wasn't redirected to main window)
        if inlineResult != nil {
            // Keep result displayed for a moment before clearing
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
                self?.inlineResult = nil
            }
        }
    }
    
    private func handleExecutionError(_ error: Error) {
        isLoading = false
        
        if let gooseError = error as? GooseCliError {
            errorMessage = gooseError.localizedDescription
        } else {
            errorMessage = "Error: \(error.localizedDescription)"
        }
        
        // Clear error after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
            self?.errorMessage = nil
        }
    }
    
    private func parseCommandComponents(_ command: String) -> [String] {
        // Simple command parsing - can be enhanced with proper shell parsing
        return command.components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }
    }
    
    private func addToHistory(_ command: String) {
        // Remove duplicates
        commandHistory.removeAll { $0 == command }
        
        // Add to end
        commandHistory.append(command)
        
        // Limit history size
        if commandHistory.count > 100 {
            commandHistory.removeFirst()
        }
        
        // Save history
        saveCommandHistory()
        
        // Reset history navigation
        historyIndex = -1
    }
    
    private func loadCommandHistory() {
        if let data = UserDefaults.standard.data(forKey: "GooseCommandHistory"),
           let history = try? JSONDecoder().decode([String].self, from: data) {
            commandHistory = history
        }
    }
    
    private func saveCommandHistory() {
        if let data = try? JSONEncoder().encode(commandHistory) {
            UserDefaults.standard.set(data, forKey: "GooseCommandHistory")
        }
    }
}

// MARK: - Supporting Types

enum ArrowDirection {
    case up
    case down
}

struct CommandResult: Identifiable {
    let id = UUID()
    let output: String
    let type: ResponseType
    let lineCount: Int
}

struct CommandSuggestion: Identifiable {
    let id = UUID()
    let fullCommand: String
    let displayText: String
    let confidence: Double
}
