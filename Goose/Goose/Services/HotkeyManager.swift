//
//  HotkeyManager.swift
//  Goose
//
//  Created on 2024-09-15
//

import SwiftUI
import HotKey
import Carbon.HIToolbox

/// Manager class to handle global hotkey registration and management
class HotkeyManager: ObservableObject {
    
    // Singleton instance
    static let shared = HotkeyManager()
    
    // Published properties
    @Published var currentHotkey: KeyCombo?
    @Published var isListening = false
    @Published var lastConflict: String?
    
    // Hotkeys
    private var spotlightHotKey: HotKey?
    private var commandCenterHotKey: HotKey?
    
    // Default hotkeys  
    private lazy var defaultSpotlightCombo = KeyCombo(keyCode: UInt32(kVK_ANSI_G), modifierFlags: UInt32(cmdKey | shiftKey))
    private lazy var defaultCommandCenterCombo = KeyCombo(keyCode: UInt32(kVK_ANSI_G), modifierFlags: UInt32(cmdKey | optionKey))
    
    // User defaults keys
    private let spotlightHotkeyKey = "SpotlightHotkeyKey"
    private let spotlightHotkeyModifiersKey = "SpotlightHotkeyModifiers"
    private let commandCenterHotkeyKey = "CommandCenterHotkeyKey"
    private let commandCenterHotkeyModifiersKey = "CommandCenterHotkeyModifiers"
    
    private init() {
        loadHotkeys()
        registerHotkeys()
    }
    
    // MARK: - Public Methods
    
    /// Register all hotkeys
    func registerHotkeys() {
        registerSpotlightHotkey()
        registerCommandCenterHotkey()
    }
    
    /// Unregister all hotkeys
    func unregisterHotkeys() {
        spotlightHotKey = nil
        commandCenterHotKey = nil
    }
    
    /// Update the spotlight hotkey
    func updateSpotlightHotkey(_ keyCombo: KeyCombo) {
        // Save to UserDefaults
        UserDefaults.standard.set(keyCombo.keyCode, forKey: spotlightHotkeyKey)
        UserDefaults.standard.set(keyCombo.modifierFlags, forKey: spotlightHotkeyModifiersKey)
        
        // Re-register the hotkey
        registerSpotlightHotkey()
    }
    
    /// Update the command center hotkey
    func updateCommandCenterHotkey(_ keyCombo: KeyCombo) {
        // Save to UserDefaults
        UserDefaults.standard.set(keyCombo.keyCode, forKey: commandCenterHotkeyKey)
        UserDefaults.standard.set(keyCombo.modifierFlags, forKey: commandCenterHotkeyModifiersKey)
        
        // Re-register the hotkey
        registerCommandCenterHotkey()
    }
    
    /// Reset hotkeys to defaults
    func resetToDefaults() {
        UserDefaults.standard.removeObject(forKey: spotlightHotkeyKey)
        UserDefaults.standard.removeObject(forKey: spotlightHotkeyModifiersKey)
        UserDefaults.standard.removeObject(forKey: commandCenterHotkeyKey)
        UserDefaults.standard.removeObject(forKey: commandCenterHotkeyModifiersKey)
        
        registerHotkeys()
    }
    
    /// Check if a key combination conflicts with system shortcuts
    func checkForConflicts(_ keyCombo: KeyCombo) -> String? {
        // Common system shortcuts to check against
        let systemShortcuts: [(KeyCombo, String)] = [
            (KeyCombo(keyCode: UInt32(kVK_Space), modifierFlags: UInt32(cmdKey)), "Spotlight Search"),
            (KeyCombo(keyCode: UInt32(kVK_Tab), modifierFlags: UInt32(cmdKey)), "Application Switcher"),
            (KeyCombo(keyCode: UInt32(kVK_ANSI_Q), modifierFlags: UInt32(cmdKey)), "Quit Application"),
            (KeyCombo(keyCode: UInt32(kVK_ANSI_W), modifierFlags: UInt32(cmdKey)), "Close Window"),
            (KeyCombo(keyCode: UInt32(kVK_ANSI_M), modifierFlags: UInt32(cmdKey)), "Minimize Window"),
            (KeyCombo(keyCode: UInt32(kVK_ANSI_H), modifierFlags: UInt32(cmdKey)), "Hide Application"),
            (KeyCombo(keyCode: UInt32(kVK_ANSI_A), modifierFlags: UInt32(cmdKey)), "Select All"),
            (KeyCombo(keyCode: UInt32(kVK_ANSI_C), modifierFlags: UInt32(cmdKey)), "Copy"),
            (KeyCombo(keyCode: UInt32(kVK_ANSI_V), modifierFlags: UInt32(cmdKey)), "Paste"),
            (KeyCombo(keyCode: UInt32(kVK_ANSI_X), modifierFlags: UInt32(cmdKey)), "Cut"),
            (KeyCombo(keyCode: UInt32(kVK_ANSI_Z), modifierFlags: UInt32(cmdKey)), "Undo"),
            (KeyCombo(keyCode: UInt32(kVK_ANSI_S), modifierFlags: UInt32(cmdKey)), "Save"),
            (KeyCombo(keyCode: UInt32(kVK_ANSI_N), modifierFlags: UInt32(cmdKey)), "New"),
            (KeyCombo(keyCode: UInt32(kVK_ANSI_O), modifierFlags: UInt32(cmdKey)), "Open"),
        ]
        
        for (shortcut, description) in systemShortcuts {
            if shortcut == keyCombo {
                return description
            }
        }
        
        return nil
    }
    
    // MARK: - Private Methods
    
    private func loadHotkeys() {
        // Load saved hotkeys from UserDefaults or use defaults
        let spotlightKey = UserDefaults.standard.object(forKey: spotlightHotkeyKey) as? UInt32
        let spotlightModifiers = UserDefaults.standard.object(forKey: spotlightHotkeyModifiersKey) as? UInt32
        
        if let key = spotlightKey, let modifiers = spotlightModifiers {
            currentHotkey = KeyCombo(keyCode: key, modifierFlags: modifiers)
        } else {
            currentHotkey = defaultSpotlightCombo
        }
    }
    
    private func registerSpotlightHotkey() {
        // Unregister existing hotkey
        spotlightHotKey = nil
        
        // Get the key combination
        let keyCode = UserDefaults.standard.object(forKey: spotlightHotkeyKey) as? UInt32 ?? defaultSpotlightCombo.keyCode
        let modifiers = UserDefaults.standard.object(forKey: spotlightHotkeyModifiersKey) as? UInt32 ?? defaultSpotlightCombo.modifierFlags
        
        // Create and register the hotkey
        if let key = Key(carbonKeyCode: keyCode) {
            spotlightHotKey = HotKey(
                key: key,
                modifiers: NSEvent.ModifierFlags(carbonFlags: modifiers)
            )
            
            spotlightHotKey?.keyDownHandler = { [weak self] in
                self?.handleSpotlightHotkey()
            }
        }
    }
    
    private func registerCommandCenterHotkey() {
        // Unregister existing hotkey
        commandCenterHotKey = nil
        
        // Get the key combination
        let keyCode = UserDefaults.standard.object(forKey: commandCenterHotkeyKey) as? UInt32 ?? defaultCommandCenterCombo.keyCode
        let modifiers = UserDefaults.standard.object(forKey: commandCenterHotkeyModifiersKey) as? UInt32 ?? defaultCommandCenterCombo.modifierFlags
        
        // Create and register the hotkey
        if let key = Key(carbonKeyCode: keyCode) {
            commandCenterHotKey = HotKey(
                key: key,
                modifiers: NSEvent.ModifierFlags(carbonFlags: modifiers)
            )
            
            commandCenterHotKey?.keyDownHandler = { [weak self] in
                self?.handleCommandCenterHotkey()
            }
        }
    }
    
    private func handleSpotlightHotkey() {
        // Show visual/audio feedback
        provideFeedback()
        
        // Toggle spotlight window
        SpotlightWindowManager.shared.toggle { command in
            print("Executing command: \(command)")
        }
    }
    
    private func handleCommandCenterHotkey() {
        // Show visual/audio feedback
        provideFeedback()
        
        // Open command center window
        NSApplication.shared.activate(ignoringOtherApps: true)
        
        // Send notification to open command center
        NotificationCenter.default.post(name: Notification.Name("OpenCommandCenter"), object: nil)
    }
    
    private func provideFeedback() {
        // Play system sound for feedback
        NSSound.beep()
        
        // Could also add visual feedback here if needed
    }
}

// MARK: - KeyCombo struct

struct KeyCombo: Equatable, Codable {
    let keyCode: UInt32
    let modifierFlags: UInt32
    
    init(keyCode: UInt32, modifierFlags: UInt32) {
        self.keyCode = keyCode
        self.modifierFlags = modifierFlags
    }
    
    init(key: Key, modifiers: [NSEvent.ModifierFlags]) {
        self.keyCode = key.carbonKeyCode
        self.modifierFlags = modifiers.reduce(0) { result, modifier in
            result | modifier.carbonFlags
        }
    }
    
    var displayString: String {
        var result = ""
        
        // Add modifiers
        if modifierFlags & UInt32(cmdKey) != 0 {
            result += "⌘"
        }
        if modifierFlags & UInt32(shiftKey) != 0 {
            result += "⇧"
        }
        if modifierFlags & UInt32(optionKey) != 0 {
            result += "⌥"
        }
        if modifierFlags & UInt32(controlKey) != 0 {
            result += "⌃"
        }
        
        // Add key
        if let key = Key(carbonKeyCode: keyCode) {
            result += key.description
        }
        
        return result
    }
}

// MARK: - Extensions

extension Key {
    static let a = Key(carbonKeyCode: UInt32(kVK_ANSI_A))!
    static let b = Key(carbonKeyCode: UInt32(kVK_ANSI_B))!
    static let c = Key(carbonKeyCode: UInt32(kVK_ANSI_C))!
    static let d = Key(carbonKeyCode: UInt32(kVK_ANSI_D))!
    static let e = Key(carbonKeyCode: UInt32(kVK_ANSI_E))!
    static let f = Key(carbonKeyCode: UInt32(kVK_ANSI_F))!
    static let g = Key(carbonKeyCode: UInt32(kVK_ANSI_G))!
    static let h = Key(carbonKeyCode: UInt32(kVK_ANSI_H))!
    static let i = Key(carbonKeyCode: UInt32(kVK_ANSI_I))!
    static let j = Key(carbonKeyCode: UInt32(kVK_ANSI_J))!
    static let k = Key(carbonKeyCode: UInt32(kVK_ANSI_K))!
    static let l = Key(carbonKeyCode: UInt32(kVK_ANSI_L))!
    static let m = Key(carbonKeyCode: UInt32(kVK_ANSI_M))!
    static let n = Key(carbonKeyCode: UInt32(kVK_ANSI_N))!
    static let o = Key(carbonKeyCode: UInt32(kVK_ANSI_O))!
    static let p = Key(carbonKeyCode: UInt32(kVK_ANSI_P))!
    static let q = Key(carbonKeyCode: UInt32(kVK_ANSI_Q))!
    static let r = Key(carbonKeyCode: UInt32(kVK_ANSI_R))!
    static let s = Key(carbonKeyCode: UInt32(kVK_ANSI_S))!
    static let t = Key(carbonKeyCode: UInt32(kVK_ANSI_T))!
    static let u = Key(carbonKeyCode: UInt32(kVK_ANSI_U))!
    static let v = Key(carbonKeyCode: UInt32(kVK_ANSI_V))!
    static let w = Key(carbonKeyCode: UInt32(kVK_ANSI_W))!
    static let x = Key(carbonKeyCode: UInt32(kVK_ANSI_X))!
    static let y = Key(carbonKeyCode: UInt32(kVK_ANSI_Y))!
    static let z = Key(carbonKeyCode: UInt32(kVK_ANSI_Z))!
    static let space = Key(carbonKeyCode: UInt32(kVK_Space))!
    static let tab = Key(carbonKeyCode: UInt32(kVK_Tab))!
    
    var description: String {
        switch self.carbonKeyCode {
        case UInt32(kVK_ANSI_A): return "A"
        case UInt32(kVK_ANSI_B): return "B"
        case UInt32(kVK_ANSI_C): return "C"
        case UInt32(kVK_ANSI_D): return "D"
        case UInt32(kVK_ANSI_E): return "E"
        case UInt32(kVK_ANSI_F): return "F"
        case UInt32(kVK_ANSI_G): return "G"
        case UInt32(kVK_ANSI_H): return "H"
        case UInt32(kVK_ANSI_I): return "I"
        case UInt32(kVK_ANSI_J): return "J"
        case UInt32(kVK_ANSI_K): return "K"
        case UInt32(kVK_ANSI_L): return "L"
        case UInt32(kVK_ANSI_M): return "M"
        case UInt32(kVK_ANSI_N): return "N"
        case UInt32(kVK_ANSI_O): return "O"
        case UInt32(kVK_ANSI_P): return "P"
        case UInt32(kVK_ANSI_Q): return "Q"
        case UInt32(kVK_ANSI_R): return "R"
        case UInt32(kVK_ANSI_S): return "S"
        case UInt32(kVK_ANSI_T): return "T"
        case UInt32(kVK_ANSI_U): return "U"
        case UInt32(kVK_ANSI_V): return "V"
        case UInt32(kVK_ANSI_W): return "W"
        case UInt32(kVK_ANSI_X): return "X"
        case UInt32(kVK_ANSI_Y): return "Y"
        case UInt32(kVK_ANSI_Z): return "Z"
        case UInt32(kVK_Space): return "Space"
        case UInt32(kVK_Tab): return "Tab"
        default: return "?"
        }
    }
}

extension NSEvent.ModifierFlags {
    init(carbonFlags: UInt32) {
        var flags: NSEvent.ModifierFlags = []
        
        if carbonFlags & UInt32(cmdKey) != 0 {
            flags.insert(.command)
        }
        if carbonFlags & UInt32(shiftKey) != 0 {
            flags.insert(.shift)
        }
        if carbonFlags & UInt32(optionKey) != 0 {
            flags.insert(.option)
        }
        if carbonFlags & UInt32(controlKey) != 0 {
            flags.insert(.control)
        }
        
        self = flags
    }
    
    var carbonFlags: UInt32 {
        var flags: UInt32 = 0
        
        if contains(.command) {
            flags |= UInt32(cmdKey)
        }
        if contains(.shift) {
            flags |= UInt32(shiftKey)
        }
        if contains(.option) {
            flags |= UInt32(optionKey)
        }
        if contains(.control) {
            flags |= UInt32(controlKey)
        }
        
        return flags
    }
}
