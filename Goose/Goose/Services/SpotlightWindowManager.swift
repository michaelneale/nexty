//
//  SpotlightWindowManager.swift
//  Goose
//
//  Created on 2024-09-15
//

import SwiftUI
import Combine

/// Manager class to handle the Spotlight-like window's lifecycle and state
class SpotlightWindowManager: ObservableObject {
    
    // Singleton instance
    static let shared = SpotlightWindowManager()
    
    // Published property to track window visibility
    @Published var isVisible: Bool = false
    
    // The spotlight window instance
    private var spotlightWindow: SpotlightWindow?
    
    // The hosting controller for the SwiftUI view
    private var hostingController: NSHostingController<CommandInputView>?
    
    // Command handler callback
    private var commandHandler: ((String) -> Void)?
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        setupWindow()
        observeVisibilityChanges()
    }
    
    /// Set up the window and its content
    private func setupWindow() {
        // Create the window
        spotlightWindow = SpotlightWindow()
        
        // Create the SwiftUI view - use Binding wrapper
        let commandInputView = CommandInputView(
            isVisible: Binding(
                get: { self.isVisible },
                set: { self.isVisible = $0 }
            ),
            onSubmit: { [weak self] command in
                self?.handleCommand(command)
            }
        )
        
        // Create hosting controller
        hostingController = NSHostingController(rootView: commandInputView)
        
        // Configure the hosting view
        if let hostingView = hostingController?.view {
            hostingView.wantsLayer = true
            hostingView.layer?.backgroundColor = .clear
            
            // Set the content view
            spotlightWindow?.contentView = hostingView
        }
    }
    
    /// Observe visibility changes to sync with window state
    private func observeVisibilityChanges() {
        $isVisible
            .removeDuplicates()
            .sink { [weak self] visible in
                if visible {
                    self?.showWindow()
                } else {
                    self?.hideWindow()
                }
            }
            .store(in: &cancellables)
    }
    
    /// Show the spotlight window
    public func show(commandHandler: ((String) -> Void)? = nil) {
        self.commandHandler = commandHandler
        isVisible = true
    }
    
    /// Hide the spotlight window
    public func hide() {
        isVisible = false
    }
    
    /// Toggle the window visibility
    public func toggle(commandHandler: ((String) -> Void)? = nil) {
        if isVisible {
            hide()
        } else {
            show(commandHandler: commandHandler)
        }
    }
    
    /// Internal method to show the window
    private func showWindow() {
        guard let window = spotlightWindow else { return }
        
        // Ensure we're on the main thread
        DispatchQueue.main.async {
            // Make the app active
            NSApp.activate(ignoringOtherApps: true)
            
            // Show the window with animation
            window.showWindow { [weak self] in
                // Focus the window after animation
                window.makeFirstResponder(window.contentView)
                
                // Update the view to focus the text field
                self?.hostingController?.view.window?.makeFirstResponder(
                    self?.hostingController?.view.window?.contentView
                )
            }
        }
    }
    
    /// Internal method to hide the window
    private func hideWindow() {
        guard let window = spotlightWindow else { return }
        
        DispatchQueue.main.async {
            window.hideWindow()
        }
    }
    
    /// Handle command submission
    private func handleCommand(_ command: String) {
        print("Command received: \(command)")
        
        // Call the command handler if set
        commandHandler?(command)
        
        // Hide the window after command submission
        hide()
    }
    
    /// Clean up resources
    deinit {
        cancellables.removeAll()
        spotlightWindow?.close()
        spotlightWindow = nil
        hostingController = nil
    }
}

// MARK: - Global Functions

/// Show the spotlight window
public func showSpotlightWindow(commandHandler: ((String) -> Void)? = nil) {
    SpotlightWindowManager.shared.show(commandHandler: commandHandler)
}

/// Hide the spotlight window
public func hideSpotlightWindow() {
    SpotlightWindowManager.shared.hide()
}

/// Toggle the spotlight window
public func toggleSpotlightWindow(commandHandler: ((String) -> Void)? = nil) {
    SpotlightWindowManager.shared.toggle(commandHandler: commandHandler)
}
