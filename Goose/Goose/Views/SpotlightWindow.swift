//
//  SpotlightWindow.swift
//  Goose
//
//  Created on 2024-09-15
//

import Cocoa
import SwiftUI

/// Custom NSPanel subclass for the Spotlight-like popup window
class SpotlightWindow: NSPanel {
    
    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 680, height: 60),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        setupWindow()
    }
    
    private func setupWindow() {
        // Window configuration
        isFloatingPanel = true
        level = .floating
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        isMovableByWindowBackground = false
        backgroundColor = .clear
        hasShadow = true
        
        // Make window non-opaque for transparency
        isOpaque = false
        
        // Hide window from dock and app switcher
        hidesOnDeactivate = false
        
        // Animation behavior
        animationBehavior = .default
        
        // Add subtle vibrant background
        appearance = NSAppearance(named: .vibrantDark)
    }
    
    override var canBecomeKey: Bool {
        return true
    }
    
    override var canBecomeMain: Bool {
        return true
    }
    
    /// Center the window on the screen
    func centerOnScreen() {
        guard let screen = NSScreen.main else { return }
        
        let screenFrame = screen.visibleFrame
        let windowFrame = frame
        
        let x = (screenFrame.width - windowFrame.width) / 2 + screenFrame.origin.x
        let y = (screenFrame.height - windowFrame.height) * 0.75 + screenFrame.origin.y // Position slightly above center
        
        setFrameOrigin(NSPoint(x: x, y: y))
    }
    
    /// Show the window with animation
    func showWindow(completion: (() -> Void)? = nil) {
        centerOnScreen()
        
        // Set initial alpha for fade-in animation
        alphaValue = 0
        
        makeKeyAndOrderFront(nil)
        
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.25
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            animator().alphaValue = 1.0
        }, completionHandler: {
            completion?()
        })
    }
    
    /// Hide the window with animation
    func hideWindow(completion: (() -> Void)? = nil) {
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.2
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            animator().alphaValue = 0.0
        }, completionHandler: {
            self.orderOut(nil)
            completion?()
        })
    }
    
    override func resignKey() {
        super.resignKey()
        // Hide window when it loses key status (clicked outside)
        hideWindow()
    }
}

// MARK: - Spotlight View
struct SpotlightView: View {
    @Binding var searchText: String
    let onSubmit: (String) -> Void
    let onCancel: () -> Void
    @State private var suggestions: [String] = []
    @FocusState private var isFocused: Bool
    @State private var pulseAnimation = false
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: Theme.Spacing.medium) {
                // Icon with pulse animation
                Image(systemName: "magnifyingglass")
                    .font(Theme.Typography.title3)
                    .foregroundColor(Theme.Colors.primary)
                    .scaleEffect(pulseAnimation ? 1.1 : 1.0)
                    .animation(Theme.Animation.spring, value: pulseAnimation)
                
                // Search field
                TextField("Type command...", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(Theme.Typography.bodyEmphasized)
                    .focused($isFocused)
                    .onSubmit {
                        if !searchText.isEmpty {
                            onSubmit(searchText)
                            searchText = ""
                        }
                    }
                    .accessibilityLabel("Command search")
                    .accessibilityHint("Type your command and press enter")
                
                // Keyboard shortcut hint
                if searchText.isEmpty {
                    Text("ESC to cancel")
                        .font(Theme.Typography.caption1)
                        .foregroundColor(Theme.Colors.secondaryText.opacity(0.5))
                }
                
                // Clear button
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(Theme.Typography.caption1)
                            .foregroundColor(Theme.Colors.secondaryText)
                    }
                    .buttonStyle(.plain)
                    .transition(.scale.combined(with: .opacity))
                    .accessibilityLabel("Clear search")
                }
            }
            .padding(Theme.Spacing.large)
            
            // Suggestions (if needed in future)
            if !suggestions.isEmpty {
                Divider()
                    .foregroundColor(Theme.Colors.divider)
                
                VStack(alignment: .leading, spacing: Theme.Spacing.xSmall) {
                    ForEach(suggestions, id: \.self) { suggestion in
                        SuggestionRow(text: suggestion) {
                            searchText = suggestion
                            onSubmit(suggestion)
                            searchText = ""
                        }
                    }
                }
                .padding(Theme.Spacing.medium)
            }
        }
        .background(
            VisualEffectBackground(material: .hudWindow, blendingMode: .behindWindow)
        )
        .cornerRadius(Theme.CornerRadius.large)
        .shadow(color: Theme.Shadows.large.color, radius: Theme.Shadows.large.radius)
        .onAppear {
            isFocused = true
            withAnimation(Theme.Animation.bouncy) {
                pulseAnimation = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                pulseAnimation = false
            }
        }
        .onExitCommand {
            onCancel()
        }
    }
}

// MARK: - Suggestion Row
struct SuggestionRow: View {
    let text: String
    let onTap: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: "clock.arrow.circlepath")
                    .font(Theme.Typography.caption1)
                    .foregroundColor(Theme.Colors.secondaryText)
                
                Text(text)
                    .font(Theme.Typography.body)
                    .foregroundColor(Theme.Colors.primaryText)
                
                Spacer()
            }
            .padding(.horizontal, Theme.Spacing.small)
            .padding(.vertical, Theme.Spacing.xSmall)
            .background(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.small)
                    .fill(isHovered ? Theme.Colors.hover : Color.clear)
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(Theme.Animation.quick) {
                isHovered = hovering
            }
        }
    }
}

// Removed - using VisualEffectBackground from ViewModifiers.swift instead
