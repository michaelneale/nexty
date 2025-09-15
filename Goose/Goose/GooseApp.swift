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
                    showSpotlightWindow { command in
                        print("Executing command: \(command)")
                        // TODO: Execute actual Goose CLI command
                    }
                }
                .keyboardShortcut("K", modifiers: [.command])
            }
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
