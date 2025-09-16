//
//  MenuBarManager.swift
//  Goose
//
//  Created on 2024-09-15
//

import SwiftUI
import AppKit

class MenuBarManager: NSObject, ObservableObject {
    static let shared = MenuBarManager()
    
    private var statusItem: NSStatusItem?
    private var menu: NSMenu?
    @Published var showInDock: Bool = UserDefaults.standard.bool(forKey: "ShowInDock") {
        didSet {
            UserDefaults.standard.set(showInDock, forKey: "ShowInDock")
            updateDockVisibility()
        }
    }
    
    @Published var launchAtLogin: Bool = UserDefaults.standard.bool(forKey: "LaunchAtLogin") {
        didSet {
            UserDefaults.standard.set(launchAtLogin, forKey: "LaunchAtLogin")
            updateLaunchAtLogin()
        }
    }
    
    private override init() {
        super.init()
        setupMenuBar()
    }
    
    func setupMenuBar() {
        // Create status item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        // Set icon
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "bird", accessibilityDescription: "Goose")
            button.image?.size = NSSize(width: 18, height: 18)
            button.image?.isTemplate = true
        }
        
        // Create menu
        menu = NSMenu()
        
        // Quick command
        let quickCommandItem = NSMenuItem(title: "Quick Command", action: #selector(showSpotlight), keyEquivalent: "k")
        quickCommandItem.keyEquivalentModifierMask = [.command]
        quickCommandItem.target = self
        menu?.addItem(quickCommandItem)
        
        // Show main window
        let showMainWindowItem = NSMenuItem(title: "Show Command Center", action: #selector(showCommandCenter), keyEquivalent: "1")
        showMainWindowItem.keyEquivalentModifierMask = [.command]
        showMainWindowItem.target = self
        menu?.addItem(showMainWindowItem)
        
        menu?.addItem(NSMenuItem.separator())
        
        // Recent commands submenu
        let recentMenu = NSMenu()
        let recentItem = NSMenuItem(title: "Recent Commands", action: nil, keyEquivalent: "")
        recentItem.submenu = recentMenu
        menu?.addItem(recentItem)
        
        updateRecentCommands()
        
        menu?.addItem(NSMenuItem.separator())
        
        // Show in Dock toggle
        let dockItem = NSMenuItem(title: "Show in Dock", action: #selector(toggleDock), keyEquivalent: "")
        dockItem.state = showInDock ? .on : .off
        dockItem.target = self
        menu?.addItem(dockItem)
        
        // Launch at Login toggle
        let launchItem = NSMenuItem(title: "Launch at Login", action: #selector(toggleLaunchAtLogin), keyEquivalent: "")
        launchItem.state = launchAtLogin ? .on : .off
        launchItem.target = self
        menu?.addItem(launchItem)
        
        menu?.addItem(NSMenuItem.separator())
        
        // Preferences
        let preferencesItem = NSMenuItem(title: "Preferences...", action: #selector(showPreferences), keyEquivalent: ",")
        preferencesItem.keyEquivalentModifierMask = [.command]
        preferencesItem.target = self
        menu?.addItem(preferencesItem)
        
        // About
        let aboutItem = NSMenuItem(title: "About Goose", action: #selector(showAbout), keyEquivalent: "")
        aboutItem.target = self
        menu?.addItem(aboutItem)
        
        menu?.addItem(NSMenuItem.separator())
        
        // Quit
        let quitItem = NSMenuItem(title: "Quit Goose", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.keyEquivalentModifierMask = [.command]
        quitItem.target = self
        menu?.addItem(quitItem)
        
        statusItem?.menu = menu
    }
    
    func updateRecentCommands() {
        guard let recentSubmenu = menu?.item(withTitle: "Recent Commands")?.submenu else { return }
        
        recentSubmenu.removeAllItems()
        
        // Get recent commands from UserDefaults or storage
        let recentCommands = UserDefaults.standard.array(forKey: "RecentCommands") as? [String] ?? []
        
        if recentCommands.isEmpty {
            let emptyItem = NSMenuItem(title: "No Recent Commands", action: nil, keyEquivalent: "")
            emptyItem.isEnabled = false
            recentSubmenu.addItem(emptyItem)
        } else {
            for (index, command) in recentCommands.prefix(10).enumerated() {
                let item = NSMenuItem(title: command, action: #selector(executeRecentCommand(_:)), keyEquivalent: "")
                if index < 9 {
                    item.keyEquivalent = "\(index + 1)"
                    item.keyEquivalentModifierMask = [.option, .command]
                }
                item.target = self
                item.representedObject = command
                recentSubmenu.addItem(item)
            }
            
            recentSubmenu.addItem(NSMenuItem.separator())
            let clearItem = NSMenuItem(title: "Clear Recent Commands", action: #selector(clearRecentCommands), keyEquivalent: "")
            clearItem.target = self
            recentSubmenu.addItem(clearItem)
        }
    }
    
    @objc private func showSpotlight() {
        SpotlightWindowManager.shared.show { command, output in
            NotificationCenter.default.post(
                name: Notification.Name("ShowCommandOutput"),
                object: nil,
                userInfo: ["command": command, "output": output]
            )
        }
    }
    
    @objc private func showCommandCenter() {
        NotificationCenter.default.post(name: Notification.Name("OpenCommandCenter"), object: nil)
    }
    
    @objc private func toggleDock() {
        showInDock.toggle()
        
        // Update menu item state
        if let dockItem = menu?.item(withTitle: "Show in Dock") {
            dockItem.state = showInDock ? .on : .off
        }
    }
    
    @objc private func toggleLaunchAtLogin() {
        launchAtLogin.toggle()
        
        // Update menu item state
        if let launchItem = menu?.item(withTitle: "Launch at Login") {
            launchItem.state = launchAtLogin ? .on : .off
        }
    }
    
    @objc private func showPreferences() {
        // Use NotificationCenter to trigger preferences window, similar to About window
        NotificationCenter.default.post(name: Notification.Name("ShowPreferencesWindow"), object: nil)
    }
    
    @objc private func showAbout() {
        NotificationCenter.default.post(name: Notification.Name("ShowAboutWindow"), object: nil)
    }
    
    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
    
    @objc private func executeRecentCommand(_ sender: NSMenuItem) {
        guard let command = sender.representedObject as? String else { return }
        
        // Show spotlight with pre-filled command
        SpotlightWindowManager.shared.show(prefilledCommand: command) { command, output in
            NotificationCenter.default.post(
                name: Notification.Name("ShowCommandOutput"),
                object: nil,
                userInfo: ["command": command, "output": output]
            )
        }
    }
    
    @objc private func clearRecentCommands() {
        UserDefaults.standard.removeObject(forKey: "RecentCommands")
        updateRecentCommands()
    }
    
    private func updateDockVisibility() {
        if showInDock {
            NSApplication.shared.setActivationPolicy(.regular)
        } else {
            NSApplication.shared.setActivationPolicy(.accessory)
        }
    }
    
    private func updateLaunchAtLogin() {
        // This would typically use SMLoginItemSetEnabled or the newer SMAppService
        // For now, we'll just store the preference
        // In a real implementation, you'd need to configure a login item
    }
    
    func addRecentCommand(_ command: String) {
        var recentCommands = UserDefaults.standard.array(forKey: "RecentCommands") as? [String] ?? []
        
        // Remove if already exists
        recentCommands.removeAll { $0 == command }
        
        // Add at beginning
        recentCommands.insert(command, at: 0)
        
        // Keep only last 10
        if recentCommands.count > 10 {
            recentCommands = Array(recentCommands.prefix(10))
        }
        
        UserDefaults.standard.set(recentCommands, forKey: "RecentCommands")
        updateRecentCommands()
    }
}
