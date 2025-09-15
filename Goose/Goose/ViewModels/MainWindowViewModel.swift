//
//  MainWindowViewModel.swift
//  Goose
//
//  ViewModel for the main window managing commands and their output
//

import SwiftUI
import Combine
import AppKit

@MainActor
class MainWindowViewModel: ObservableObject {
    @Published var commands: [GooseCommand] = []
    @Published var commandOutputs: [UUID: String] = [:]
    
    private var commandExecutor = CommandExecutor()
    private var cancellables = Set<AnyCancellable>()
    private var runningTasks: [UUID: Task<Void, Never>] = [:]
    
    var runningCommands: [GooseCommand] {
        commands.filter { $0.status == .running }
    }
    
    var completedCommands: [GooseCommand] {
        commands.filter { $0.status == .completed || $0.status == .failed || $0.status == .cancelled }
    }
    
    init() {
        setupNotificationObservers()
    }
    
    private func setupNotificationObservers() {
        // Listen for commands from spotlight or other sources
        NotificationCenter.default.publisher(for: Notification.Name("ExecuteGooseCommand"))
            .compactMap { $0.userInfo?["command"] as? String }
            .sink { [weak self] commandString in
                self?.executeCommand(commandString)
            }
            .store(in: &cancellables)
    }
    
    func startMonitoring() {
        // Start any necessary monitoring tasks
    }
    
    func stopMonitoring() {
        // Stop monitoring tasks
        stopAllCommands()
    }
    
    func executeCommand(_ commandString: String) {
        let components = commandString.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        guard !components.isEmpty else { return }
        
        var command = GooseCommand(command: components.first!, arguments: Array(components.dropFirst()))
        command.status = .running
        
        commands.insert(command, at: 0)
        commandOutputs[command.id] = "Starting command execution...\n"
        
        // Execute the command
        let task = Task { [weak self] in
            guard let self = self else { return }
            
            do {
                try await self.commandExecutor.execute(command: command) { text, type in
                    Task { @MainActor [weak self] in
                        guard let self = self else { return }
                        
                        // Append output
                        self.commandOutputs[command.id, default: ""] += text
                        
                        // Update status if needed
                        if let index = self.commands.firstIndex(where: { $0.id == command.id }) {
                            if type == .stderr && !text.isEmpty {
                                self.commands[index].status = .failed
                            }
                        }
                    }
                }
                
                // Mark as completed
                await MainActor.run { [weak self] in
                    guard let self = self else { return }
                    if let index = self.commands.firstIndex(where: { $0.id == command.id }) {
                        if self.commands[index].status == .running {
                            self.commands[index].status = .completed
                        }
                    }
                    self.runningTasks.removeValue(forKey: command.id)
                }
            } catch {
                // Handle error
                await MainActor.run { [weak self] in
                    guard let self = self else { return }
                    if let index = self.commands.firstIndex(where: { $0.id == command.id }) {
                        self.commands[index].status = .failed
                        self.commandOutputs[command.id, default: ""] += "\nError: \(error.localizedDescription)\n"
                    }
                    self.runningTasks.removeValue(forKey: command.id)
                }
            }
        }
        
        runningTasks[command.id] = task
    }
    
    func getOutput(for command: GooseCommand) -> String {
        commandOutputs[command.id] ?? "No output available"
    }
    
    func stopCommand(_ command: GooseCommand) {
        // Cancel the running task
        if let task = runningTasks[command.id] {
            task.cancel()
            runningTasks.removeValue(forKey: command.id)
        }
        
        // Update status
        if let index = commands.firstIndex(where: { $0.id == command.id }) {
            commands[index].status = .cancelled
            commandOutputs[command.id, default: ""] += "\n--- Command cancelled by user ---\n"
        }
    }
    
    func deleteCommand(_ command: GooseCommand) {
        // Stop if running
        if command.status == .running {
            stopCommand(command)
        }
        
        // Remove from lists
        commands.removeAll { $0.id == command.id }
        commandOutputs.removeValue(forKey: command.id)
    }
    
    func clearCompleted() {
        let completedIds = completedCommands.map { $0.id }
        commands.removeAll { completedIds.contains($0.id) }
        completedIds.forEach { commandOutputs.removeValue(forKey: $0) }
    }
    
    func stopAllCommands() {
        for command in runningCommands {
            stopCommand(command)
        }
    }
    
    func copyOutput(for command: GooseCommand) {
        let output = getOutput(for: command)
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(output, forType: .string)
    }
    
    func exportOutput(for command: GooseCommand) {
        let output = getOutput(for: command)
        
        let savePanel = NSSavePanel()
        savePanel.title = "Export Command Output"
        savePanel.nameFieldStringValue = "goose-output-\(command.id.uuidString).txt"
        savePanel.allowedContentTypes = [.plainText]
        
        savePanel.begin { response in
            if response == .OK, let url = savePanel.url {
                do {
                    try output.write(to: url, atomically: true, encoding: .utf8)
                    print("Exported output to: \(url)")
                } catch {
                    print("Failed to export: \(error)")
                }
            }
        }
    }
    
    func exportAllOutput() {
        var allOutput = "Goose Command History\n"
        allOutput += "Generated: \(Date())\n"
        allOutput += String(repeating: "=", count: 50) + "\n\n"
        
        for command in commands {
            allOutput += "Command: \(command.fullCommand)\n"
            allOutput += "Status: \(command.status.rawValue)\n"
            allOutput += "Timestamp: \(command.timestamp)\n"
            allOutput += "Output:\n"
            allOutput += getOutput(for: command)
            allOutput += "\n" + String(repeating: "-", count: 50) + "\n\n"
        }
        
        let savePanel = NSSavePanel()
        savePanel.title = "Export All Command Output"
        savePanel.nameFieldStringValue = "goose-all-output-\(Date().timeIntervalSince1970).txt"
        savePanel.allowedContentTypes = [.plainText]
        
        savePanel.begin { response in
            if response == .OK, let url = savePanel.url {
                do {
                    try allOutput.write(to: url, atomically: true, encoding: .utf8)
                    print("Exported all output to: \(url)")
                } catch {
                    print("Failed to export: \(error)")
                }
            }
        }
    }
}
