//
//  CommandInputView.swift
//  Goose
//
//  Created on 2024-09-15
//

import SwiftUI

/// SwiftUI view for the command input interface
struct CommandInputView: View {
    @Binding var isVisible: Bool
    @State private var commandText: String = ""
    @FocusState private var isTextFieldFocused: Bool
    
    // Callback for when a command is submitted
    var onSubmit: ((String) -> Void)?
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                // Icon
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.secondary)
                    .frame(width: 24)
                
                // Text Field
                TextField("Type a Goose command...", text: $commandText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 18, weight: .regular))
                    .focused($isTextFieldFocused)
                    .onSubmit {
                        handleSubmit()
                    }
                    .onReceive(NotificationCenter.default.publisher(for: NSWindow.didResignKeyNotification)) { _ in
                        // Handle escape key or click outside
                        dismiss()
                    }
                
                // Clear button (only show when there's text)
                if !commandText.isEmpty {
                    Button(action: {
                        commandText = ""
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
        }
        .background(VisualEffectBackground())
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.1), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
        .onAppear {
            // Auto-focus the text field when view appears
            isTextFieldFocused = true
        }
    }
    
    private func handleSubmit() {
        let trimmedCommand = commandText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedCommand.isEmpty else { return }
        
        onSubmit?(trimmedCommand)
        commandText = ""
        dismiss()
    }
    
    private func dismiss() {
        isVisible = false
    }
}

/// Visual effect background view for the blur/vibrancy effect
struct VisualEffectBackground: NSViewRepresentable {
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
