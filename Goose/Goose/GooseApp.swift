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
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unified(showsTitle: false))
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
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // Keep app running even when windows are closed (for hotkey activation)
        return false
    }
}
