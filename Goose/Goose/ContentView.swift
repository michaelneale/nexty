//
//  ContentView.swift
//  Goose
//
//  Created on 2024-09-15
//

import SwiftUI
import Combine

struct ContentView: View {
    @State private var commandText = ""
    @State private var output = "Welcome to Goose\nType a command and press Enter to execute."
    @State private var isRunning = false
    @State private var commandHistory: [GooseCommand] = []
    @State private var commandExecutor = CommandExecutor()
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "bird.fill")
                    .font(.title2)
                    .foregroundColor(.accentColor)
                Text("Goose")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
                
                Button(action: {
                    showSpotlightWindow { command in
                        executeCommand(command)
                    }
                }) {
                    Image(systemName: "magnifyingglass")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help("Show Spotlight (⌘K)")
                
                if isRunning {
                    ProgressView()
                        .scaleEffect(0.7)
                        .progressViewStyle(CircularProgressViewStyle())
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // Output area
            ScrollViewReader { proxy in
                ScrollView {
                    Text(output)
                        .font(.system(.body, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .textSelection(.enabled)
                        .id("outputBottom")
                }
                .background(Color(NSColor.textBackgroundColor))
                .onChange(of: output) { _ in
                    withAnimation {
                        proxy.scrollTo("outputBottom", anchor: .bottom)
                    }
                }
            }
            
            Divider()
            
            // Command input
            HStack {
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                TextField("Enter command...", text: $commandText)
                    .textFieldStyle(.plain)
                    .font(.system(.body, design: .monospaced))
                    .onSubmit {
                        executeCommand()
                    }
                    .disabled(isRunning)
                
                Button(action: executeCommand) {
                    Image(systemName: "play.fill")
                }
                .buttonStyle(.borderless)
                .disabled(commandText.isEmpty || isRunning)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
        }
        .frame(minWidth: 600, minHeight: 400)
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("ShowCommandOutput"))) { notification in
            if let command = notification.userInfo?["command"] as? GooseCommand,
               let commandOutput = notification.userInfo?["output"] as? String {
                output += "\n\n> \(command.fullCommand)\n\(commandOutput)"
                commandHistory.append(command)
            }
        }
    }
    
    private func executeCommand() {
        guard !commandText.isEmpty else { return }
        
        let command = commandText
        commandText = ""
        
        executeCommand(command)
    }
    
    private func executeCommand(_ command: String) {
        output += "\n\n> \(command)\n"
        isRunning = true
        
        // Parse command
        let components = command.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        let gooseCommand = GooseCommand(command: components.first ?? "", arguments: Array(components.dropFirst()))
        commandHistory.append(gooseCommand)
        
        // Execute command
        Task {
            do {
                try await commandExecutor.execute(command: gooseCommand) { text, type in
                    DispatchQueue.main.async { [self] in
                        self.output += text
                    }
                }
                
                await MainActor.run {
                    self.isRunning = false
                }
            } catch {
                await MainActor.run {
                    self.output += "\nError: \(error.localizedDescription)\n"
                    self.isRunning = false
                }
            }
        }
    }
    

}
