//
//  GooseApp.swift
//  Goose
//
//  Created on 2024-09-15
//

import SwiftUI

@main
struct GooseApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var spotlightManager = SpotlightWindowManager.shared
    @StateObject private var hotkeyManager = HotkeyManager.shared
    @State private var showMainWindow = false
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unified(showsTitle: false))
        
        WindowGroup("Command Center", id: "command-center") {
            MainWindow()
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
        .defaultSize(width: 1000, height: 700)
        
        // Preferences Window
        Settings {
            HotkeyPreferencesView()
        }
        
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("About Goose") {
                    NSApplication.shared.orderFrontStandardAboutPanel(
                        options: [
                            .applicationName: "Goose",
                            .applicationVersion: "1.0.0"
                        ]
                    )
                }
            }
            
            CommandGroup(after: .newItem) {
                Button("Show Command Center") {
                    self.openCommandCenter()
                }
                .keyboardShortcut("1", modifiers: [.command])
                
                Divider()
                
                Button("Show Spotlight") {
                    SpotlightWindowManager.shared.show(
                        mainWindowHandler: { command, output in
                            // Open main window with command output
                            self.openMainWindow(with: command, output: output)
                        }
                    )
                }
                .keyboardShortcut("K", modifiers: [.command])
            }
        }
    }
    
    private func openCommandCenter() {
        // Focus the app and open command center window
        NSApplication.shared.activate(ignoringOtherApps: true)
        
        // Open the Command Center window
        if let commandCenterWindow = NSApplication.shared.windows.first(where: { $0.title == "Command Center" }) {
            commandCenterWindow.makeKeyAndOrderFront(nil)
        } else {
            // Create new window by opening URL
            NSWorkspace.shared.open(URL(string: "goose://command-center")!)
        }
    }
    
    private func openMainWindow(with command: GooseCommand, output: String) {
        // Focus the app
        NSApplication.shared.activate(ignoringOtherApps: true)
        
        // Find or create a window
        if let window = NSApplication.shared.windows.first {
            window.makeKeyAndOrderFront(nil)
            
            // TODO: Update ContentView to display the command and output
            // This will be handled in ContentView
            NotificationCenter.default.post(
                name: Notification.Name("ShowCommandOutput"),
                object: nil,
                userInfo: [
                    "command": command,
                    "output": output
                ]
            )
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Set up any app-wide configurations
        NSApplication.shared.setActivationPolicy(.regular)
        
        // Initialize the spotlight window manager
        _ = SpotlightWindowManager.shared
        
        // Initialize the hotkey manager to register global hotkeys
        _ = HotkeyManager.shared
        
        // Register notification handler for opening command center
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(openCommandCenter),
            name: Notification.Name("OpenCommandCenter"),
            object: nil
        )
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // Keep app running even when windows are closed (for hotkey activation)
        return false
    }
    
    @objc private func openCommandCenter() {
        // Focus the app and open command center window
        NSApplication.shared.activate(ignoringOtherApps: true)
        
        // Open the Command Center window
        if let commandCenterWindow = NSApplication.shared.windows.first(where: { $0.title == "Command Center" }) {
            commandCenterWindow.makeKeyAndOrderFront(nil)
        } else {
            // Create new window by opening URL
            NSWorkspace.shared.open(URL(string: "goose://command-center")!)
        }
    }
}
