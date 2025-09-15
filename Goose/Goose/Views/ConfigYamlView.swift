//
//  ConfigYamlView.swift
//  Goose
//
//  Created on 2024-09-15
//

import SwiftUI

struct ConfigYamlView: View {
    @StateObject private var configManager = ConfigurationManager.shared
    @State private var selectedSection: ConfigSection = .extensions
    @State private var searchText = ""
    @State private var expandedSections = Set<String>()
    @State private var showRawYaml = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with search and controls
            headerView
            
            Divider()
            
            if configManager.isLoading {
                loadingView
            } else if let error = configManager.error {
                errorView(error)
            } else if showRawYaml {
                rawYamlView
            } else {
                configurationView
            }
        }
        .onAppear {
            configManager.loadConfiguration()
        }
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        HStack(spacing: 12) {
            // Search field
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search configuration...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(8)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
            
            // View toggle
            Picker("View Mode", selection: $showRawYaml) {
                Label("Structured", systemImage: "list.bullet.indent")
                    .tag(false)
                Label("Raw YAML", systemImage: "doc.text")
                    .tag(true)
            }
            .pickerStyle(SegmentedPickerStyle())
            .frame(width: 200)
            
            // Refresh button
            Button(action: { configManager.refreshConfiguration() }) {
                Image(systemName: "arrow.clockwise")
            }
            .help("Refresh configuration")
        }
        .padding()
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading configuration...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Error View
    
    private func errorView(_ error: ConfigurationManager.ConfigError) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(.orange)
            
            Text("Configuration Error")
                .font(.headline)
            
            Text(error.localizedDescription)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("Retry") {
                configManager.loadConfiguration()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Raw YAML View
    
    private var rawYamlView: some View {
        ScrollView {
            Text(configManager.rawYaml)
                .font(.custom("SF Mono", size: 12))
                .foregroundColor(.primary)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
        }
        .background(Color(NSColor.textBackgroundColor))
    }
    
    // MARK: - Configuration View
    
    private var configurationView: some View {
        HSplitView {
            // Sidebar with sections
            sidebarView
                .frame(minWidth: 200, idealWidth: 250)
            
            // Content area
            contentView
        }
    }
    
    // MARK: - Sidebar
    
    private var sidebarView: some View {
        List(selection: $selectedSection) {
            ForEach(ConfigSection.allCases, id: \.self) { section in
                HStack {
                    Image(systemName: section.icon)
                        .frame(width: 20)
                    Text(section.rawValue)
                    Spacer()
                    if section == .extensions,
                       let count = configManager.configuration?.extensions?.count {
                        Text("\(count)")
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.accentColor.opacity(0.2))
                            .cornerRadius(4)
                    }
                }
                .tag(section)
            }
        }
        .listStyle(SidebarListStyle())
    }
    
    // MARK: - Content View
    
    private var contentView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if !searchText.isEmpty {
                    searchResultsView
                } else {
                    switch selectedSection {
                    case .provider:
                        providerView
                    case .profiles:
                        profilesView
                    case .extensions:
                        extensionsView
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    // MARK: - Search Results
    
    private var searchResultsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            let results = configManager.searchConfiguration(query: searchText)
            
            if results.isEmpty {
                Text("No results found for '\(searchText)'")
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                ForEach(results) { result in
                    ConfigSearchResultView(result: result)
                }
            }
        }
    }
    
    // MARK: - Provider View
    
    private var providerView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Provider Configuration")
                .font(.title2)
                .fontWeight(.semibold)
            
            if let provider = configManager.configuration?.provider {
                GroupBox {
                    VStack(alignment: .leading, spacing: 12) {
                        if let name = provider.name {
                            ConfigItemView(label: "Name", value: name)
                        }
                        if let model = provider.model {
                            ConfigItemView(label: "Model", value: model)
                        }
                        if let temperature = provider.temperature {
                            ConfigItemView(label: "Temperature", value: String(format: "%.2f", temperature))
                        }
                        if provider.apiKey != nil {
                            ConfigItemView(label: "API Key", value: "••••••••", isSecret: true)
                        }
                    }
                    .padding(8)
                }
            } else {
                Text("No provider configuration found")
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Profiles View
    
    private var profilesView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Profiles")
                .font(.title2)
                .fontWeight(.semibold)
            
            if let profiles = configManager.configuration?.profiles {
                ForEach(Array(profiles.keys.sorted()), id: \.self) { profileName in
                    if let profile = profiles[profileName] {
                        ProfileItemView(name: profileName, profile: profile)
                    }
                }
            } else {
                Text("No profiles configured")
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Extensions View
    
    private var extensionsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with stats
            HStack {
                Text("Extensions")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                HStack(spacing: 20) {
                    Label("\(configManager.getEnabledExtensions().count) enabled", 
                          systemImage: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    
                    Label("\(configManager.getDisabledExtensions().count) disabled", 
                          systemImage: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .font(.caption)
            }
            
            if let extensions = configManager.configuration?.extensions {
                let sortedExtensions = extensions.keys.sorted()
                
                ForEach(sortedExtensions, id: \.self) { extensionName in
                    if let ext = extensions[extensionName] {
                        ExtensionItemView(
                            name: extensionName,
                            extension: ext,
                            isExpanded: expandedSections.contains(extensionName)
                        ) {
                            toggleExpanded(extensionName)
                        }
                    }
                }
            } else {
                Text("No extensions configured")
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private func toggleExpanded(_ section: String) {
        if expandedSections.contains(section) {
            expandedSections.remove(section)
        } else {
            expandedSections.insert(section)
        }
    }
}

// MARK: - Supporting Views

struct ConfigItemView: View {
    let label: String
    let value: String
    var isSecret: Bool = false
    
    var body: some View {
        HStack(alignment: .top) {
            Text(label + ":")
                .fontWeight(.medium)
                .frame(width: 120, alignment: .leading)
            
            if isSecret {
                HStack {
                    Text(value)
                        .font(.custom("SF Mono", size: 12))
                    Image(systemName: "lock.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else {
                Text(value)
                    .font(.custom("SF Mono", size: 12))
                    .textSelection(.enabled)
            }
            
            Spacer()
        }
    }
}

struct ProfileItemView: View {
    let name: String
    let profile: ProfileConfig
    
    var body: some View {
        GroupBox(label: Label(name, systemImage: "person.circle")) {
            VStack(alignment: .leading, spacing: 8) {
                if let provider = profile.provider {
                    ConfigItemView(label: "Provider", value: provider)
                }
                if let processor = profile.processor {
                    ConfigItemView(label: "Processor", value: processor)
                }
                if let accelerator = profile.accelerator {
                    ConfigItemView(label: "Accelerator", value: accelerator)
                }
                if let moderator = profile.moderator {
                    ConfigItemView(label: "Moderator", value: moderator)
                }
            }
            .padding(8)
        }
    }
}

struct ExtensionItemView: View {
    let name: String
    let `extension`: ExtensionConfig
    let isExpanded: Bool
    let onToggle: () -> Void
    
    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    Button(action: onToggle) {
                        HStack {
                            Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                                .frame(width: 12)
                            
                            HStack(spacing: 8) {
                                Text(`extension`.name ?? name)
                                    .fontWeight(.medium)
                                
                                if let enabled = `extension`.enabled {
                                    Image(systemName: enabled ? "checkmark.circle.fill" : "xmark.circle.fill")
                                        .foregroundColor(enabled ? .green : .secondary)
                                }
                                
                                if let type = `extension`.type {
                                    Text(type)
                                        .font(.caption)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.blue.opacity(0.1))
                                        .cornerRadius(4)
                                }
                            }
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Spacer()
                }
                
                if let description = `extension`.description {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Expanded content
                if isExpanded {
                    Divider()
                    
                    // Commands
                    if let commands = `extension`.commands, !commands.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Commands")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                            
                            ForEach(Array(commands.keys.sorted()), id: \.self) { cmdName in
                                if let cmd = commands[cmdName] {
                                    HStack {
                                        Text("• \(cmdName)")
                                            .font(.custom("SF Mono", size: 11))
                                        if let desc = cmd.description {
                                            Text("- \(desc)")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        Spacer()
                                    }
                                }
                            }
                        }
                    }
                    
                    // Environment variables
                    if let environment = `extension`.environment, !environment.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Environment Variables")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                            
                            ForEach(Array(environment.keys.sorted()), id: \.self) { key in
                                HStack {
                                    Text("\(key)=\(environment[key] ?? "")")
                                        .font(.custom("SF Mono", size: 11))
                                    Spacer()
                                }
                            }
                        }
                    }
                    
                    // Configuration
                    if let configuration = `extension`.configuration, !configuration.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Configuration")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                            
                            ForEach(Array(configuration.keys.sorted()), id: \.self) { key in
                                HStack {
                                    Text("\(key):")
                                        .font(.custom("SF Mono", size: 11))
                                    Text("\(String(describing: configuration[key] ?? ""))")
                                        .font(.custom("SF Mono", size: 11))
                                        .foregroundColor(.secondary)
                                    Spacer()
                                }
                            }
                        }
                    }
                }
            }
            .padding(8)
        }
    }
}

struct ConfigSearchResultView: View {
    let result: ConfigSearchResult
    
    var body: some View {
        GroupBox {
            HStack {
                Image(systemName: result.section.icon)
                    .frame(width: 20)
                
                VStack(alignment: .leading) {
                    Text(result.path)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(result.key): \(result.value)")
                        .font(.custom("SF Mono", size: 12))
                }
                
                Spacer()
            }
            .padding(8)
        }
    }
}
