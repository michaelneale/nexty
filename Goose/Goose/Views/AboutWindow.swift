//
//  AboutWindow.swift
//  Goose
//
//  Created on 2024-09-15
//

import SwiftUI

struct AboutWindow: View {
    @Environment(\.dismiss) private var dismiss
    
    var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }
    
    var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // App Icon and Name
            VStack(spacing: 10) {
                Image(systemName: "bird.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.accentColor)
                
                Text("Goose")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Version \(appVersion) (\(buildNumber))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Divider()
            
            // Description
            VStack(spacing: 10) {
                Text("A native macOS UI for the Goose CLI tool")
                    .font(.body)
                    .multilineTextAlignment(.center)
                
                Text("Crisp, clean, minimal interface with Spotlight-like quick access")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // Info Grid
            VStack(alignment: .leading, spacing: 8) {
                InfoRow(label: "Developer:", value: "Your Name")
                InfoRow(label: "Copyright:", value: "© 2024")
                InfoRow(label: "License:", value: "MIT License")
                InfoRow(label: "Website:", value: "github.com/yourusername/goose", isLink: true)
            }
            .padding(.horizontal)
            
            Divider()
            
            // System Info
            VStack(alignment: .leading, spacing: 8) {
                Text("System Information")
                    .font(.headline)
                    .padding(.bottom, 5)
                
                InfoRow(label: "macOS Version:", value: ProcessInfo.processInfo.operatingSystemVersionString)
                InfoRow(label: "Goose CLI:", value: getGooseVersion())
            }
            .padding(.horizontal)
            
            Divider()
            
            // Action Buttons
            HStack(spacing: 15) {
                Button("View on GitHub") {
                    if let url = URL(string: "https://github.com/yourusername/goose") {
                        NSWorkspace.shared.open(url)
                    }
                }
                
                Button("Check for Updates") {
                    checkForUpdates()
                }
                
                Button("Close") {
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
            
            // Keyboard Shortcuts
            DisclosureGroup("Keyboard Shortcuts") {
                VStack(alignment: .leading, spacing: 5) {
                    ShortcutRow(shortcut: "⌘K", description: "Quick Command (Spotlight)")
                    ShortcutRow(shortcut: "⌘1", description: "Show Command Center")
                    ShortcutRow(shortcut: "⌘,", description: "Preferences")
                    ShortcutRow(shortcut: "⌘Q", description: "Quit Goose")
                    ShortcutRow(shortcut: "⌘⌥1-9", description: "Execute Recent Command")
                }
                .padding(.vertical, 5)
            }
            .padding(.horizontal)
        }
        .padding(30)
        .frame(width: 450)
        .fixedSize()
    }
    
    private func getGooseVersion() -> String {
        let goosePath = UserDefaults.standard.string(forKey: "GoosePath") ?? "/usr/local/bin/goose"
        let task = Process()
        task.launchPath = goosePath
        task.arguments = ["--version"]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe
        
        do {
            try task.run()
            task.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) {
                return output.isEmpty ? "Not installed" : output
            }
        } catch {
            return "Not installed"
        }
        
        return "Not installed"
    }
    
    private func checkForUpdates() {
        // In a real app, this would check for updates
        // For now, just show an alert
        let alert = NSAlert()
        alert.messageText = "Check for Updates"
        alert.informativeText = "You have the latest version of Goose."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    var isLink: Bool = false
    
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Text(label)
                .fontWeight(.medium)
                .frame(width: 120, alignment: .trailing)
            
            if isLink {
                Button(action: {
                    if let url = URL(string: "https://\(value)") {
                        NSWorkspace.shared.open(url)
                    }
                }) {
                    Text(value)
                        .foregroundColor(.accentColor)
                        .underline()
                }
                .buttonStyle(PlainButtonStyle())
                .cursor(NSCursor.pointingHand)
            } else {
                Text(value)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

struct ShortcutRow: View {
    let shortcut: String
    let description: String
    
    var body: some View {
        HStack {
            Text(shortcut)
                .font(.system(.caption, design: .monospaced))
                .frame(width: 80, alignment: .leading)
            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
        }
    }
}

// Custom cursor modifier
extension View {
    func cursor(_ cursor: NSCursor) -> some View {
        self.onHover { inside in
            if inside {
                cursor.push()
            } else {
                NSCursor.pop()
            }
        }
    }
}
