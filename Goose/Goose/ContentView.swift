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
    @State private var shakeAnimation: CGFloat = 0
    @EnvironmentObject private var notificationManager: NotificationManager
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HeaderView(isRunning: isRunning) {
                showSpotlightWindow { command in
                    executeCommand(command)
                }
            }
            
            Divider()
                .foregroundColor(Theme.Colors.divider)
            
            // Output area
            OutputArea(output: output, isEmpty: commandHistory.isEmpty)
            
            Divider()
                .foregroundColor(Theme.Colors.divider)
            
            // Command input
            CommandInputArea(
                commandText: $commandText,
                isRunning: isRunning,
                shakeAnimation: shakeAnimation,
                onSubmit: executeCommand
            )
        }
        .frame(minWidth: 600, minHeight: 400)
        .background(Theme.Colors.background)
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("ShowCommandOutput"))) { notification in
            if let command = notification.userInfo?["command"] as? GooseCommand,
               let commandOutput = notification.userInfo?["output"] as? String {
                withAnimation(Theme.Animation.smooth) {
                    output += "\n\n> \(command.fullCommand)\n\(commandOutput)"
                    commandHistory.append(command)
                }
            }
        }
    }
}

// MARK: - Header View
struct HeaderView: View {
    let isRunning: Bool
    let onSpotlight: () -> Void
    @State private var isHoveringSpotlight = false
    
    var body: some View {
        HStack(spacing: Theme.Spacing.medium) {
            HStack(spacing: Theme.Spacing.small) {
                Image(systemName: "bird.fill")
                    .font(Theme.Typography.title2)
                    .foregroundColor(Theme.Colors.primary)
                    .rotationEffect(.degrees(isRunning ? 360 : 0))
                    .animation(isRunning ? Theme.Animation.smooth.repeatForever(autoreverses: false) : .default, value: isRunning)
                
                Text("Goose")
                    .font(Theme.Typography.title2)
                    .foregroundColor(Theme.Colors.primaryText)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Goose Application")
            
            Spacer()
            
            Button(action: onSpotlight) {
                HStack(spacing: Theme.Spacing.xSmall) {
                    Image(systemName: "magnifyingglass")
                        .font(Theme.Typography.body)
                    Text("⌘K")
                        .font(Theme.Typography.caption1)
                        .opacity(isHoveringSpotlight ? 1 : 0.5)
                }
                .foregroundColor(Theme.Colors.secondaryText)
                .padding(.horizontal, Theme.Spacing.small)
                .padding(.vertical, Theme.Spacing.xSmall)
                .background(
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.small)
                        .fill(isHoveringSpotlight ? Theme.Colors.hover : Color.clear)
                )
            }
            .buttonStyle(.plain)
            .onHover { hovering in
                withAnimation(Theme.Animation.quick) {
                    isHoveringSpotlight = hovering
                }
            }
            .help("Show Spotlight (⌘K)")
            .accessibilityLabel("Show Spotlight Window")
            .accessibilityHint("Press to open the spotlight search window")
            
            if isRunning {
                LoadingIndicator()
            }
        }
        .padding(Theme.Spacing.large)
        .background(Theme.Colors.secondaryBackground)
    }
}

// MARK: - Loading Indicator
struct LoadingIndicator: View {
    @State private var rotation: Double = 0
    
    var body: some View {
        Circle()
            .trim(from: 0, to: 0.7)
            .stroke(Theme.Colors.primary, lineWidth: 2)
            .frame(width: 16, height: 16)
            .rotationEffect(.degrees(rotation))
            .onAppear {
                withAnimation(Theme.Animation.smooth.repeatForever(autoreverses: false)) {
                    rotation = 360
                }
            }
            .accessibilityLabel("Loading")
            .accessibilityHint("Command is currently executing")
    }
}

// MARK: - Output Area
struct OutputArea: View {
    let output: String
    let isEmpty: Bool
    @State private var scrollID = UUID()
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                if isEmpty {
                    CommandEmptyStateView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(Theme.Spacing.xxLarge)
                } else {
                    Text(output)
                        .font(Theme.Typography.code)
                        .foregroundColor(Theme.Colors.terminalText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(Theme.Spacing.large)
                        .textSelection(.enabled)
                        .id(scrollID)
                        .accessibilityLabel("Command output")
                        .accessibilityValue(output)
                }
            }
            .background(Theme.Colors.tertiaryBackground)
            .onChange(of: output) { _ in
                withAnimation(Theme.Animation.smooth) {
                    proxy.scrollTo(scrollID, anchor: .bottom)
                }
            }
        }
    }
}

// MARK: - Empty State View
struct CommandEmptyStateView: View {
    var body: some View {
        VStack(spacing: Theme.Spacing.large) {
            Image(systemName: "terminal.fill")
                .font(.system(size: 48))
                .foregroundColor(Theme.Colors.secondaryText.opacity(0.3))
            
            VStack(spacing: Theme.Spacing.small) {
                Text("Ready to run commands")
                    .font(Theme.Typography.title3)
                    .foregroundColor(Theme.Colors.primaryText)
                
                Text("Type a command below or use ⌘K for spotlight")
                    .font(Theme.Typography.body)
                    .foregroundColor(Theme.Colors.secondaryText)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("No commands run yet. Ready to accept commands.")
    }
}

// MARK: - Command Input Area
struct CommandInputArea: View {
    @Binding var commandText: String
    let isRunning: Bool
    let shakeAnimation: CGFloat
    let onSubmit: () -> Void
    @FocusState private var isFocused: Bool
    @State private var isHoveringButton = false
    
    var body: some View {
        HStack(spacing: Theme.Spacing.medium) {
            Image(systemName: "chevron.right")
                .font(Theme.Typography.code)
                .foregroundColor(Theme.Colors.terminalPrompt)
                .accessibilityHidden(true)
            
            TextField("Enter command...", text: $commandText)
                .textFieldStyle(.plain)
                .font(Theme.Typography.code)
                .foregroundColor(Theme.Colors.primaryText)
                .focused($isFocused)
                .onSubmit(onSubmit)
                .disabled(isRunning)
                .shake(animatableData: shakeAnimation)
                .accessibilityLabel("Command input")
                .accessibilityHint("Type your command here and press enter to execute")
            
            Button(action: onSubmit) {
                Image(systemName: isRunning ? "stop.fill" : "play.fill")
                    .font(Theme.Typography.body)
                    .foregroundColor(commandText.isEmpty ? Theme.Colors.secondaryText : Theme.Colors.primary)
                    .scaleEffect(isHoveringButton ? 1.1 : 1.0)
            }
            .buttonStyle(.plain)
            .disabled(commandText.isEmpty && !isRunning)
            .onHover { hovering in
                withAnimation(Theme.Animation.quick) {
                    isHoveringButton = hovering
                }
            }
            .accessibilityLabel(isRunning ? "Stop command" : "Execute command")
        }
        .padding(Theme.Spacing.large)
        .background(Theme.Colors.secondaryBackground)
        .onAppear {
            isFocused = true
        }
    }
}

// MARK: - ContentView Extension
extension ContentView {
    private func executeCommand() {
        guard !commandText.isEmpty else { return }
        
        let command = commandText
        commandText = ""
        
        executeCommand(command)
    }
    
    private func executeCommand(_ command: String) {
        withAnimation(Theme.Animation.quick) {
            output += "\n\n> \(command)\n"
        }
        isRunning = true
        
        // Parse command
        let components = command.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        let gooseCommand = GooseCommand(command: components.first ?? "", arguments: Array(components.dropFirst()))
        commandHistory.append(gooseCommand)
        
        // Execute command
        Task {
            do {
                try await commandExecutor.execute(command: gooseCommand) { text, type in
                    DispatchQueue.main.async {
                        withAnimation(Theme.Animation.quick) {
                            self.output += text
                        }
                    }
                }
                
                await MainActor.run {
                    self.isRunning = false
                    self.notificationManager.show(type: .success, title: "Command completed", message: nil)
                }
            } catch {
                await MainActor.run {
                    withAnimation(Theme.Animation.quick) {
                        self.output += "\nError: \(error.localizedDescription)\n"
                    }
                    self.isRunning = false
                    self.notificationManager.show(type: .error, title: "Command failed", message: error.localizedDescription)
                    
                    // Shake animation on error
                    withAnimation(Theme.Animation.quick) {
                        self.shakeAnimation += 1
                    }
                }
            }
        }
    }
}
