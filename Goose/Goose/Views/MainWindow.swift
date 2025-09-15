//
//  MainWindow.swift
//  Goose
//
//  Main application window showing running and completed commands
//

import SwiftUI
import AppKit

struct MainWindow: View {
    @StateObject private var viewModel = MainWindowViewModel()
    @State private var selectedCommand: GooseCommand?
    @State private var searchText = ""
    @State private var showOnlyRunning = false
    
    var body: some View {
        NavigationSplitView {
            // Sidebar with command list
            CommandListView(
                commands: filteredCommands,
                selectedCommand: $selectedCommand,
                onStopCommand: viewModel.stopCommand,
                onDeleteCommand: viewModel.deleteCommand
            )
            .searchable(text: $searchText, prompt: "Search commands...")
            .toolbar {
                ToolbarItem(placement: .navigation) {
                    HStack {
                        Image(systemName: "bird.fill")
                            .foregroundColor(.accentColor)
                        Text("Commands")
                            .font(.headline)
                    }
                }
            }
        } detail: {
            // Main content area with command output
            if let command = selectedCommand {
                CommandOutputView(
                    command: command,
                    output: viewModel.getOutput(for: command),
                    onStop: { viewModel.stopCommand(command) },
                    onCopy: { viewModel.copyOutput(for: command) },
                    onExport: { viewModel.exportOutput(for: command) }
                )
            } else {
                EmptyStateView()
            }
        }
        .navigationSplitViewStyle(.balanced)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                // Filter toggle
                Toggle(isOn: $showOnlyRunning) {
                    Label("Running Only", systemImage: "play.circle")
                }
                .toggleStyle(.button)
                
                // Clear all completed
                Button(action: viewModel.clearCompleted) {
                    Label("Clear Completed", systemImage: "trash")
                }
                .disabled(viewModel.completedCommands.isEmpty)
                
                // Stop all
                Button(action: viewModel.stopAllCommands) {
                    Label("Stop All", systemImage: "stop.circle.fill")
                }
                .disabled(viewModel.runningCommands.isEmpty)
                .foregroundColor(.red)
                
                // Export all
                Button(action: viewModel.exportAllOutput) {
                    Label("Export All", systemImage: "square.and.arrow.up")
                }
                .disabled(viewModel.commands.isEmpty)
            }
        }
        .frame(minWidth: 900, minHeight: 600)
        .onAppear {
            viewModel.startMonitoring()
        }
        .onDisappear {
            viewModel.stopMonitoring()
        }
    }
    
    private var filteredCommands: [GooseCommand] {
        var commands = showOnlyRunning ? viewModel.runningCommands : viewModel.commands
        
        if !searchText.isEmpty {
            commands = commands.filter { command in
                command.fullCommand.localizedCaseInsensitiveContains(searchText) ||
                viewModel.getOutput(for: command).localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return commands
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "terminal")
                .font(.system(size: 64))
                .foregroundColor(.secondary)
            Text("No Command Selected")
                .font(.title2)
                .foregroundColor(.secondary)
            Text("Select a command from the sidebar to view its output")
                .font(.body)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.textBackgroundColor))
    }
}

// MARK: - Preview
struct MainWindow_Previews: PreviewProvider {
    static var previews: some View {
        MainWindow()
    }
}
