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
    @StateObject private var menuBarManager = MenuBarManager.shared
    @State private var showMainWindow = false
    @State private var showAboutWindow = false
    
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
            PreferencesWindow()
        }
        
        // About Window
        Window("About Goose", id: "about-window") {
            AboutWindow()
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("About Goose") {
                    showAboutWindow = true
                    openAboutWindow()
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
    
    private func openAboutWindow() {
        NSApplication.shared.activate(ignoringOtherApps: true)
        
        if let url = URL(string: "goose://about") {
            NSWorkspace.shared.open(url)
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Set up any app-wide configurations
        let showInDock = UserDefaults.standard.bool(forKey: "ShowInDock")
        NSApplication.shared.setActivationPolicy(showInDock ? .regular : .accessory)
        
        // Initialize the menu bar manager
        _ = MenuBarManager.shared
        
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
        
        // Register notification handler for showing about window
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(showAboutWindow),
            name: Notification.Name("ShowAboutWindow"),
            object: nil
        )
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        // Perform cleanup
        saveApplicationState()
        
        // Remove notification observers
        NotificationCenter.default.removeObserver(self)
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
    
    @objc private func showAboutWindow() {
        NSApplication.shared.activate(ignoringOtherApps: true)
        
        if let url = URL(string: "goose://about") {
            NSWorkspace.shared.open(url)
        }
    }
    
    private func saveApplicationState() {
        // Save any pending state or preferences
        UserDefaults.standard.synchronize()
        
        // Save command history if needed
        if let recentCommands = UserDefaults.standard.array(forKey: "RecentCommands") {
            // Already saved to UserDefaults
        }
        
        // Log application termination if logging is enabled
        if UserDefaults.standard.bool(forKey: "EnableLogging") {
            logMessage("Application terminating", level: .info)
        }
    }
    
    private func logMessage(_ message: String, level: LogLevel) {
        guard UserDefaults.standard.bool(forKey: "EnableLogging") else { return }
        
        let logPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?
            .appendingPathComponent("Goose/Logs/app.log")
        
        guard let path = logPath else { return }
        
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .medium)
        let logEntry = "[\(timestamp)] [\(level.rawValue)] \(message)\n"
        
        if let data = logEntry.data(using: .utf8) {
            if FileManager.default.fileExists(atPath: path.path) {
                if let fileHandle = try? FileHandle(forWritingTo: path) {
                    fileHandle.seekToEndOfFile()
                    fileHandle.write(data)
                    fileHandle.closeFile()
                }
            } else {
                try? FileManager.default.createDirectory(at: path.deletingLastPathComponent(), withIntermediateDirectories: true)
                try? data.write(to: path)
            }
        }
    }
    
    enum LogLevel: String {
        case debug = "DEBUG"
        case info = "INFO"
        case warning = "WARNING"
        case error = "ERROR"
    }
}
