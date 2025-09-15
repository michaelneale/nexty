//
//  PreferencesWindow.swift
//  Goose
//
//  Created on 2024-09-15
//

import SwiftUI

struct PreferencesWindow: View {
    @State private var selectedTab = 0
    @StateObject private var menuBarManager = MenuBarManager.shared
    @StateObject private var hotkeyManager = HotkeyManager.shared
    @AppStorage("CommandTimeout") private var commandTimeout: Double = 30.0
    @AppStorage("ShowLineNumbers") private var showLineNumbers: Bool = true
    @AppStorage("Theme") private var selectedTheme: String = "System"
    @AppStorage("FontSize") private var fontSize: Double = 13.0
    @AppStorage("MaxOutputLines") private var maxOutputLines: Int = 1000
    @AppStorage("SaveCommandHistory") private var saveCommandHistory: Bool = true
    @AppStorage("HistoryLimit") private var historyLimit: Int = 100
    
    var body: some View {
        TabView(selection: $selectedTab) {
            GeneralPreferences()
                .tabItem {
                    Label("General", systemImage: "gear")
                }
                .tag(0)
            
            AppearancePreferences()
                .tabItem {
                    Label("Appearance", systemImage: "paintbrush")
                }
                .tag(1)
            
            HotkeyPreferencesView()
                .tabItem {
                    Label("Hotkeys", systemImage: "keyboard")
                }
                .tag(2)
            
            AdvancedPreferences()
                .tabItem {
                    Label("Advanced", systemImage: "wrench.and.screwdriver")
                }
                .tag(3)
        }
        .frame(width: 600, height: 450)
        .navigationTitle("Preferences")
    }
}

struct GeneralPreferences: View {
    @StateObject private var menuBarManager = MenuBarManager.shared
    @AppStorage("LaunchAtLogin") private var launchAtLogin: Bool = false
    @AppStorage("ShowInDock") private var showInDock: Bool = true
    @AppStorage("ShowMenuBarIcon") private var showMenuBarIcon: Bool = true
    @AppStorage("SaveCommandHistory") private var saveCommandHistory: Bool = true
    @AppStorage("HistoryLimit") private var historyLimit: Int = 100
    
    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 20) {
                    // Startup
                    GroupBox(label: Label("Startup", systemImage: "power")) {
                        VStack(alignment: .leading, spacing: 10) {
                            Toggle("Launch at Login", isOn: $launchAtLogin)
                                .onChange(of: launchAtLogin) { newValue in
                                    menuBarManager.launchAtLogin = newValue
                                }
                        }
                        .padding(10)
                    }
                    
                    // Appearance
                    GroupBox(label: Label("System Integration", systemImage: "macwindow")) {
                        VStack(alignment: .leading, spacing: 10) {
                            Toggle("Show in Dock", isOn: $showInDock)
                                .onChange(of: showInDock) { newValue in
                                    menuBarManager.showInDock = newValue
                                }
                                .help("When disabled, Goose will only appear in the menu bar")
                            
                            Toggle("Show Menu Bar Icon", isOn: $showMenuBarIcon)
                                .help("Display Goose icon in the menu bar for quick access")
                        }
                        .padding(10)
                    }
                    
                    // History
                    GroupBox(label: Label("Command History", systemImage: "clock.arrow.circlepath")) {
                        VStack(alignment: .leading, spacing: 10) {
                            Toggle("Save Command History", isOn: $saveCommandHistory)
                            
                            HStack {
                                Text("History Limit:")
                                TextField("", value: $historyLimit, format: .number)
                                    .frame(width: 80)
                                Text("commands")
                                Spacer()
                            }
                            .disabled(!saveCommandHistory)
                            
                            HStack {
                                Button("Clear History") {
                                    UserDefaults.standard.removeObject(forKey: "RecentCommands")
                                    UserDefaults.standard.removeObject(forKey: "CommandHistory")
                                }
                                .disabled(!saveCommandHistory)
                                Spacer()
                            }
                        }
                        .padding(10)
                    }
                }
                .padding()
            }
        }
    }
}

struct AppearancePreferences: View {
    @AppStorage("Theme") private var selectedTheme: String = "System"
    @AppStorage("FontSize") private var fontSize: Double = 13.0
    @AppStorage("FontFamily") private var fontFamily: String = "SF Mono"
    @AppStorage("ShowLineNumbers") private var showLineNumbers: Bool = true
    @AppStorage("HighlightSyntax") private var highlightSyntax: Bool = true
    @AppStorage("WindowOpacity") private var windowOpacity: Double = 1.0
    
    let themes = ["System", "Light", "Dark"]
    let fonts = ["SF Mono", "Menlo", "Monaco", "Courier New", "Fira Code"]
    
    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 20) {
                    // Theme
                    GroupBox(label: Label("Theme", systemImage: "moon.circle")) {
                        VStack(alignment: .leading, spacing: 10) {
                            Picker("Color Theme:", selection: $selectedTheme) {
                                ForEach(themes, id: \.self) { theme in
                                    Text(theme).tag(theme)
                                }
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            
                            HStack {
                                Text("Window Opacity:")
                                Slider(value: $windowOpacity, in: 0.5...1.0, step: 0.05)
                                Text("\(Int(windowOpacity * 100))%")
                                    .frame(width: 50)
                            }
                        }
                        .padding(10)
                    }
                    
                    // Font
                    GroupBox(label: Label("Font", systemImage: "textformat")) {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("Font Family:")
                                Picker("", selection: $fontFamily) {
                                    ForEach(fonts, id: \.self) { font in
                                        Text(font).tag(font)
                                    }
                                }
                                .labelsHidden()
                            }
                            
                            HStack {
                                Text("Font Size:")
                                Slider(value: $fontSize, in: 10...20, step: 1)
                                Text("\(Int(fontSize))pt")
                                    .frame(width: 50)
                            }
                            
                            // Preview
                            GroupBox(label: Text("Preview")) {
                                Text("goose run \"example command\"")
                                    .font(.custom(fontFamily, size: CGFloat(fontSize)))
                                    .padding(10)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(5)
                            }
                        }
                        .padding(10)
                    }
                    
                    // Output Display
                    GroupBox(label: Label("Output Display", systemImage: "text.alignleft")) {
                        VStack(alignment: .leading, spacing: 10) {
                            Toggle("Show Line Numbers", isOn: $showLineNumbers)
                            Toggle("Syntax Highlighting", isOn: $highlightSyntax)
                        }
                        .padding(10)
                    }
                }
                .padding()
            }
        }
    }
}

struct AdvancedPreferences: View {
    @AppStorage("CommandTimeout") private var commandTimeout: Double = 30.0
    @AppStorage("MaxOutputLines") private var maxOutputLines: Int = 1000
    @AppStorage("BufferSize") private var bufferSize: Int = 4096
    @AppStorage("EnableLogging") private var enableLogging: Bool = false
    @AppStorage("LogLevel") private var logLevel: String = "Info"
    @AppStorage("GoosePath") private var goosePath: String = "/usr/local/bin/goose"
    
    let logLevels = ["Debug", "Info", "Warning", "Error"]
    
    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 20) {
                    // Command Execution
                    GroupBox(label: Label("Command Execution", systemImage: "terminal")) {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("Command Timeout:")
                                TextField("", value: $commandTimeout, format: .number)
                                    .frame(width: 80)
                                Text("seconds")
                                Spacer()
                            }
                            
                            HStack {
                                Text("Max Output Lines:")
                                TextField("", value: $maxOutputLines, format: .number)
                                    .frame(width: 80)
                                Text("lines")
                                Spacer()
                            }
                            
                            HStack {
                                Text("Buffer Size:")
                                TextField("", value: $bufferSize, format: .number)
                                    .frame(width: 80)
                                Text("bytes")
                                Spacer()
                            }
                        }
                        .padding(10)
                    }
                    
                    // Goose CLI Path
                    GroupBox(label: Label("Goose CLI", systemImage: "arrow.right.circle")) {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("Goose Path:")
                                TextField("", text: $goosePath)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                Button("Browse...") {
                                    let panel = NSOpenPanel()
                                    panel.allowsMultipleSelection = false
                                    panel.canChooseDirectories = false
                                    panel.canChooseFiles = true
                                    
                                    if panel.runModal() == .OK {
                                        goosePath = panel.url?.path ?? goosePath
                                    }
                                }
                            }
                            
                            Button("Test Connection") {
                                // Test goose CLI connection
                                testGooseConnection()
                            }
                        }
                        .padding(10)
                    }
                    
                    // Logging
                    GroupBox(label: Label("Logging", systemImage: "doc.text")) {
                        VStack(alignment: .leading, spacing: 10) {
                            Toggle("Enable Logging", isOn: $enableLogging)
                            
                            HStack {
                                Text("Log Level:")
                                Picker("", selection: $logLevel) {
                                    ForEach(logLevels, id: \.self) { level in
                                        Text(level).tag(level)
                                    }
                                }
                                .labelsHidden()
                                .frame(width: 150)
                                Spacer()
                            }
                            .disabled(!enableLogging)
                            
                            HStack {
                                Button("Open Log Folder") {
                                    openLogFolder()
                                }
                                .disabled(!enableLogging)
                                
                                Button("Clear Logs") {
                                    clearLogs()
                                }
                                .disabled(!enableLogging)
                                
                                Spacer()
                            }
                        }
                        .padding(10)
                    }
                    
                    // Reset
                    GroupBox(label: Label("Reset", systemImage: "arrow.counterclockwise")) {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Reset all preferences to their default values")
                                .foregroundColor(.secondary)
                            
                            Button("Reset to Defaults") {
                                resetToDefaults()
                            }
                            .foregroundColor(.red)
                        }
                        .padding(10)
                    }
                }
                .padding()
            }
        }
    }
    
    private func testGooseConnection() {
        // Test if goose CLI is accessible at the specified path
        let task = Process()
        task.launchPath = goosePath
        task.arguments = ["--version"]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        
        do {
            try task.run()
            task.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                // Show success alert
                showAlert(title: "Connection Successful", message: "Goose CLI version: \(output)")
            }
        } catch {
            // Show error alert
            showAlert(title: "Connection Failed", message: error.localizedDescription)
        }
    }
    
    private func openLogFolder() {
        let logPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?
            .appendingPathComponent("Goose/Logs")
        
        if let path = logPath {
            NSWorkspace.shared.open(path)
        }
    }
    
    private func clearLogs() {
        let logPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?
            .appendingPathComponent("Goose/Logs")
        
        if let path = logPath {
            try? FileManager.default.removeItem(at: path)
            try? FileManager.default.createDirectory(at: path, withIntermediateDirectories: true)
        }
    }
    
    private func resetToDefaults() {
        // Reset all UserDefaults for the app
        if let bundleID = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleID)
            UserDefaults.standard.synchronize()
        }
    }
    
    private func showAlert(title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = title.contains("Failed") ? .warning : .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}
