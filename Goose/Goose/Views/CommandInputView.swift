//
//  CommandInputView.swift
//  Goose
//
//  Created on 2024-09-15
//

import SwiftUI
import AppKit

/// SwiftUI view for the command input interface
struct CommandInputView: View {
    @Binding var isVisible: Bool
    @StateObject private var viewModel = CommandInputViewModel()
    @FocusState private var isTextFieldFocused: Bool
    @State private var currentKeyMonitor: Any?
    
    // Callback for opening main window with results
    var onOpenMainWindow: ((GooseCommand, String) -> Void)?
    
    var body: some View {
        VStack(spacing: 0) {
            // Main input area
            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    // Icon
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .scaleEffect(0.8)
                            .frame(width: 24)
                    } else {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.secondary)
                            .frame(width: 24)
                    }
                    
                    // Text Field
                    TextField("Type a Goose command...", text: $viewModel.commandText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 18, weight: .regular))
                        .focused($isTextFieldFocused)
                        .disabled(viewModel.isLoading)
                        .onSubmit {
                            viewModel.executeCommand()
                        }
                    
                    // Clear button or Cancel button
                    if viewModel.isLoading {
                        Button(action: {
                            viewModel.cancelExecution()
                        }) {
                            Text("Cancel")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    } else if !viewModel.commandText.isEmpty {
                        Button(action: {
                            viewModel.commandText = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.secondary.opacity(0.7))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 18)
                
                // Error message
                if let error = viewModel.errorMessage {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                            .font(.system(size: 14))
                        Text(error)
                            .font(.system(size: 14))
                            .foregroundColor(.red)
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)
                }
                
                // Inline result display
                if let result = viewModel.inlineResult {
                    VStack(alignment: .leading, spacing: 4) {
                        Divider()
                        ScrollView {
                            Text(result.output)
                                .font(.system(size: 14, design: .monospaced))
                                .foregroundColor(result.type == .stderr ? .red : .primary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .textSelection(.enabled)
                        }
                        .frame(maxHeight: 120)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                    }
                }
                
                // Suggestions
                if !viewModel.suggestions.isEmpty {
                    VStack(alignment: .leading, spacing: 0) {
                        Divider()
                        ForEach(Array(viewModel.suggestions.enumerated()), id: \.element.id) { index, suggestion in
                            HStack {
                                Text(suggestion.displayText)
                                    .font(.system(size: 14))
                                    .foregroundColor(index == viewModel.selectedSuggestionIndex ? .white : .primary)
                                Spacer()
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            .background(index == viewModel.selectedSuggestionIndex ? Color.accentColor : Color.clear)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                viewModel.applySuggestion(at: index)
                            }
                        }
                    }
                }
            }
        }
        .background(VisualEffectBackground(material: .contentBackground, blendingMode: .behindWindow))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.1), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
        .onAppear {
            setupKeyboardHandling()
            isTextFieldFocused = true
            viewModel.onOpenMainWindow = onOpenMainWindow
        }
        .onDisappear {
            removeKeyboardHandling()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didResignKeyNotification)) { _ in
            // Handle click outside
            if !viewModel.isLoading {
                dismiss()
            }
        }
    }
    
    private func setupKeyboardHandling() {
        currentKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            switch event.keyCode {
            case 125: // Down arrow
                viewModel.handleArrowKey(.down)
                return nil
            case 126: // Up arrow
                viewModel.handleArrowKey(.up)
                return nil
            case 48: // Tab
                if !event.modifierFlags.contains(.shift) {
                    viewModel.handleTabKey()
                    return nil
                }
            case 53: // Escape
                if !viewModel.isLoading {
                    dismiss()
                    return nil
                }
            default:
                break
            }
            return event
        }
    }
    
    private func removeKeyboardHandling() {
        if let monitor = currentKeyMonitor {
            NSEvent.removeMonitor(monitor)
            currentKeyMonitor = nil
        }
    }
    
    private func dismiss() {
        isVisible = false
    }
}

/// Visual effect background view for the blur/vibrancy effect (command input specific)
struct CommandInputVisualEffectBackground: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = .hudWindow
        view.blendingMode = .behindWindow
        view.state = .active
        view.isEmphasized = true
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        // No updates needed
    }
}



// MARK: - Preview

struct CommandInputView_Previews: PreviewProvider {
    static var previews: some View {
        CommandInputView(isVisible: .constant(true))
            .frame(width: 680, height: 60)
            .padding()
    }
}
