//
//  HotkeyPreferencesView.swift
//  Goose
//
//  Created on 2024-09-15
//

import SwiftUI
import Carbon.HIToolbox

struct HotkeyPreferencesView: View {
    @StateObject private var hotkeyManager = HotkeyManager.shared
    @State private var isRecordingSpotlight = false
    @State private var isRecordingCommandCenter = false
    @State private var spotlightKeyCombo: KeyCombo?
    @State private var commandCenterKeyCombo: KeyCombo?
    @State private var showConflictAlert = false
    @State private var conflictMessage = ""
    @State private var showAccessibilityAlert = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Title
            Text("Hotkey Preferences")
                .font(.largeTitle)
                .fontWeight(.semibold)
                .padding(.bottom, 10)
            
            // Accessibility Permission Status
            AccessibilityPermissionView(showAlert: $showAccessibilityAlert)
            
            Divider()
            
            // Spotlight Hotkey
            VStack(alignment: .leading, spacing: 10) {
                Text("Spotlight Window")
                    .font(.headline)
                
                Text("Press this hotkey to show the Spotlight-like command window")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack {
                    HotkeyRecorderView(
                        keyCombo: $spotlightKeyCombo,
                        isRecording: $isRecordingSpotlight,
                        placeholder: hotkeyManager.currentHotkey?.displayString ?? "⌘⇧G",
                        onRecord: {
                            if !isRecordingCommandCenter {
                                isRecordingSpotlight.toggle()
                            }
                        }
                    )
                    
                    if spotlightKeyCombo != nil {
                        Button("Apply") {
                            applySpotlightHotkey()
                        }
                        .buttonStyle(.borderedProminent)
                        
                        Button("Cancel") {
                            spotlightKeyCombo = nil
                            isRecordingSpotlight = false
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
            
            Divider()
            
            // Command Center Hotkey
            VStack(alignment: .leading, spacing: 10) {
                Text("Command Center")
                    .font(.headline)
                
                Text("Press this hotkey to show the main Command Center window")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack {
                    HotkeyRecorderView(
                        keyCombo: $commandCenterKeyCombo,
                        isRecording: $isRecordingCommandCenter,
                        placeholder: "⌘⌥G",
                        onRecord: {
                            if !isRecordingSpotlight {
                                isRecordingCommandCenter.toggle()
                            }
                        }
                    )
                    
                    if commandCenterKeyCombo != nil {
                        Button("Apply") {
                            applyCommandCenterHotkey()
                        }
                        .buttonStyle(.borderedProminent)
                        
                        Button("Cancel") {
                            commandCenterKeyCombo = nil
                            isRecordingCommandCenter = false
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
            
            Divider()
            
            // Reset Button
            HStack {
                Button("Reset to Defaults") {
                    resetToDefaults()
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Text("Default: ⌘⇧G for Spotlight, ⌘⌥G for Command Center")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(30)
        .frame(width: 600, height: 500)
        .alert("Hotkey Conflict", isPresented: $showConflictAlert) {
            Button("OK") {
                showConflictAlert = false
            }
        } message: {
            Text(conflictMessage)
        }
        .alert("Accessibility Permission Required", isPresented: $showAccessibilityAlert) {
            Button("Open System Preferences") {
                openAccessibilityPreferences()
            }
            Button("Cancel") {
                showAccessibilityAlert = false
            }
        } message: {
            Text("Goose needs accessibility permissions to register global hotkeys. Please grant permission in System Preferences > Security & Privacy > Privacy > Accessibility.")
        }
    }
    
    private func applySpotlightHotkey() {
        guard let keyCombo = spotlightKeyCombo else { return }
        
        // Check for conflicts
        if let conflict = hotkeyManager.checkForConflicts(keyCombo) {
            conflictMessage = "This hotkey conflicts with: \(conflict)"
            showConflictAlert = true
            return
        }
        
        // Apply the hotkey
        hotkeyManager.updateSpotlightHotkey(keyCombo)
        
        // Reset state
        spotlightKeyCombo = nil
        isRecordingSpotlight = false
        
        // Provide feedback
        NSSound.beep()
    }
    
    private func applyCommandCenterHotkey() {
        guard let keyCombo = commandCenterKeyCombo else { return }
        
        // Check for conflicts
        if let conflict = hotkeyManager.checkForConflicts(keyCombo) {
            conflictMessage = "This hotkey conflicts with: \(conflict)"
            showConflictAlert = true
            return
        }
        
        // Apply the hotkey
        hotkeyManager.updateCommandCenterHotkey(keyCombo)
        
        // Reset state
        commandCenterKeyCombo = nil
        isRecordingCommandCenter = false
        
        // Provide feedback
        NSSound.beep()
    }
    
    private func resetToDefaults() {
        hotkeyManager.resetToDefaults()
        spotlightKeyCombo = nil
        commandCenterKeyCombo = nil
        isRecordingSpotlight = false
        isRecordingCommandCenter = false
        NSSound.beep()
    }
    
    private func openAccessibilityPreferences() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }
}

// MARK: - Hotkey Recorder View

struct HotkeyRecorderView: View {
    @Binding var keyCombo: KeyCombo?
    @Binding var isRecording: Bool
    let placeholder: String
    let onRecord: () -> Void
    
    var body: some View {
        Button(action: onRecord) {
            HStack {
                if isRecording {
                    Text("Press keys...")
                        .foregroundColor(.secondary)
                } else {
                    Text(keyCombo?.displayString ?? placeholder)
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                if isRecording {
                    Image(systemName: "record.circle.fill")
                        .foregroundColor(.red)
                        .animation(.easeInOut(duration: 0.5).repeatForever(), value: isRecording)
                } else {
                    Image(systemName: "keyboard")
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(width: 200)
        }
        .buttonStyle(.bordered)
        .onAppear {
            if isRecording {
                NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                    self.handleKeyDown(event)
                    return nil
                }
            }
        }
    }
    
    private func handleKeyDown(_ event: NSEvent) {
        guard isRecording else { return }
        
        // Get the modifiers
        var modifierFlags: UInt32 = 0
        
        if event.modifierFlags.contains(.command) {
            modifierFlags |= UInt32(cmdKey)
        }
        if event.modifierFlags.contains(.shift) {
            modifierFlags |= UInt32(shiftKey)
        }
        if event.modifierFlags.contains(.option) {
            modifierFlags |= UInt32(optionKey)
        }
        if event.modifierFlags.contains(.control) {
            modifierFlags |= UInt32(controlKey)
        }
        
        // Get the key code
        let keyCode = UInt32(event.keyCode)
        
        // Create the key combo
        keyCombo = KeyCombo(
            keyCode: keyCode,
            modifierFlags: modifierFlags
        )
        isRecording = false
    }
    
    private func mapKeyToCarbonCode(_ character: String) -> UInt32? {
        guard let firstChar = character.lowercased().first else { return nil }
        
        switch firstChar {
        case "a": return UInt32(kVK_ANSI_A)
        case "b": return UInt32(kVK_ANSI_B)
        case "c": return UInt32(kVK_ANSI_C)
        case "d": return UInt32(kVK_ANSI_D)
        case "e": return UInt32(kVK_ANSI_E)
        case "f": return UInt32(kVK_ANSI_F)
        case "g": return UInt32(kVK_ANSI_G)
        case "h": return UInt32(kVK_ANSI_H)
        case "i": return UInt32(kVK_ANSI_I)
        case "j": return UInt32(kVK_ANSI_J)
        case "k": return UInt32(kVK_ANSI_K)
        case "l": return UInt32(kVK_ANSI_L)
        case "m": return UInt32(kVK_ANSI_M)
        case "n": return UInt32(kVK_ANSI_N)
        case "o": return UInt32(kVK_ANSI_O)
        case "p": return UInt32(kVK_ANSI_P)
        case "q": return UInt32(kVK_ANSI_Q)
        case "r": return UInt32(kVK_ANSI_R)
        case "s": return UInt32(kVK_ANSI_S)
        case "t": return UInt32(kVK_ANSI_T)
        case "u": return UInt32(kVK_ANSI_U)
        case "v": return UInt32(kVK_ANSI_V)
        case "w": return UInt32(kVK_ANSI_W)
        case "x": return UInt32(kVK_ANSI_X)
        case "y": return UInt32(kVK_ANSI_Y)
        case "z": return UInt32(kVK_ANSI_Z)
        case " ": return UInt32(kVK_Space)
        case "\t": return UInt32(kVK_Tab)
        case "1": return UInt32(kVK_ANSI_1)
        case "2": return UInt32(kVK_ANSI_2)
        case "3": return UInt32(kVK_ANSI_3)
        case "4": return UInt32(kVK_ANSI_4)
        case "5": return UInt32(kVK_ANSI_5)
        case "6": return UInt32(kVK_ANSI_6)
        case "7": return UInt32(kVK_ANSI_7)
        case "8": return UInt32(kVK_ANSI_8)
        case "9": return UInt32(kVK_ANSI_9)
        case "0": return UInt32(kVK_ANSI_0)
        default: return nil
        }
    }
}

// MARK: - Accessibility Permission View

struct AccessibilityPermissionView: View {
    @Binding var showAlert: Bool
    @State private var hasPermission = false
    
    var body: some View {
        HStack {
            Image(systemName: hasPermission ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .foregroundColor(hasPermission ? .green : .orange)
            
            Text(hasPermission ? "Accessibility permission granted" : "Accessibility permission required for global hotkeys")
                .font(.caption)
            
            Spacer()
            
            if !hasPermission {
                Button("Grant Permission") {
                    showAlert = true
                }
                .buttonStyle(.link)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(hasPermission ? Color.green.opacity(0.1) : Color.orange.opacity(0.1))
        .cornerRadius(8)
        .onAppear {
            checkAccessibilityPermission()
        }
    }
    
    private func checkAccessibilityPermission() {
        // Check if we have accessibility permissions
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as NSString: false]
        hasPermission = AXIsProcessTrustedWithOptions(options)
    }
}

// MARK: - Preview

struct HotkeyPreferencesView_Previews: PreviewProvider {
    static var previews: some View {
        HotkeyPreferencesView()
    }
}
