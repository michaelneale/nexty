//
//  ContentView.swift
//  Goose
//
//  Created on 2024-09-15
//

import SwiftUI

struct ContentView: View {
    @State private var commandText = ""
    @State private var output = "Welcome to Goose\nType a command and press Enter to execute."
    @State private var isRunning = false
    
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
    }
    
    private func executeCommand() {
        guard !commandText.isEmpty else { return }
        
        let command = commandText
        commandText = ""
        
        output += "\n\n> \(command)\n"
        isRunning = true
        
        // Placeholder for actual command execution
        // This will be implemented to run goose CLI commands
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            output += "Command execution will be implemented in next task.\n"
            isRunning = false
        }
    }
}
