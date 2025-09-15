//
//  ConfigurationManager.swift
//  Goose
//
//  Created on 2024-09-15
//

import Foundation
import Yams
import Combine

class ConfigurationManager: ObservableObject {
    static let shared = ConfigurationManager()
    
    @Published var configuration: GooseConfiguration?
    @Published var rawYaml: String = ""
    @Published var isLoading = false
    @Published var error: ConfigError?
    
    private let configPath: URL
    private var fileWatcher: DispatchSourceFileSystemObject?
    
    enum ConfigError: LocalizedError {
        case fileNotFound
        case invalidYaml(String)
        case parseError(String)
        case permissionDenied
        
        var errorDescription: String? {
            switch self {
            case .fileNotFound:
                return "Configuration file not found at ~/.config/goose/config.yaml"
            case .invalidYaml(let message):
                return "Invalid YAML format: \(message)"
            case .parseError(let message):
                return "Failed to parse configuration: \(message)"
            case .permissionDenied:
                return "Permission denied accessing configuration file"
            }
        }
    }
    
    private init() {
        // Get the path to ~/.config/goose/config.yaml
        let homeDirectory = FileManager.default.homeDirectoryForCurrentUser
        self.configPath = homeDirectory
            .appendingPathComponent(".config")
            .appendingPathComponent("goose")
            .appendingPathComponent("config.yaml")
    }
    
    // MARK: - Public Methods
    
    func loadConfiguration() {
        isLoading = true
        error = nil
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            do {
                // Check if file exists
                guard FileManager.default.fileExists(atPath: self.configPath.path) else {
                    DispatchQueue.main.async {
                        self.error = .fileNotFound
                        self.isLoading = false
                    }
                    return
                }
                
                // Read the YAML file
                let yamlString = try String(contentsOf: self.configPath, encoding: .utf8)
                
                // Parse YAML to dictionary
                let yamlObject = try Yams.load(yaml: yamlString)
                
                // Convert to JSON for Codable parsing
                if let yamlDict = yamlObject as? [String: Any] {
                    let jsonData = try JSONSerialization.data(withJSONObject: yamlDict)
                    let decoder = JSONDecoder()
                    let config = try decoder.decode(GooseConfiguration.self, from: jsonData)
                    
                    DispatchQueue.main.async {
                        self.configuration = config
                        self.rawYaml = yamlString
                        self.isLoading = false
                        self.setupFileWatcher()
                    }
                } else {
                    throw ConfigError.invalidYaml("Failed to parse YAML structure")
                }
                
            } catch let error as ConfigError {
                DispatchQueue.main.async {
                    self.error = error
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.error = .parseError(error.localizedDescription)
                    self.isLoading = false
                }
            }
        }
    }
    
    func refreshConfiguration() {
        loadConfiguration()
    }
    
    // MARK: - File Watching
    
    private func setupFileWatcher() {
        // Clean up existing watcher
        fileWatcher?.cancel()
        
        let fileDescriptor = open(configPath.path, O_EVTONLY)
        guard fileDescriptor >= 0 else { return }
        
        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fileDescriptor,
            eventMask: [.write, .rename],
            queue: DispatchQueue.global(qos: .background)
        )
        
        source.setEventHandler { [weak self] in
            self?.loadConfiguration()
        }
        
        source.setCancelHandler {
            close(fileDescriptor)
        }
        
        source.resume()
        self.fileWatcher = source
    }
    
    deinit {
        fileWatcher?.cancel()
    }
    
    // MARK: - Helper Methods
    
    func getEnabledExtensions() -> [String] {
        guard let extensions = configuration?.extensions else { return [] }
        return extensions.compactMap { (key, value) in
            value.enabled == true ? key : nil
        }
    }
    
    func getDisabledExtensions() -> [String] {
        guard let extensions = configuration?.extensions else { return [] }
        return extensions.compactMap { (key, value) in
            value.enabled == false ? key : nil
        }
    }
    
    func searchConfiguration(query: String) -> [ConfigSearchResult] {
        guard !query.isEmpty else { return [] }
        
        var results: [ConfigSearchResult] = []
        let lowercasedQuery = query.lowercased()
        
        // Search in provider
        if let provider = configuration?.provider {
            if let name = provider.name, name.lowercased().contains(lowercasedQuery) {
                results.append(ConfigSearchResult(
                    section: .provider,
                    key: "name",
                    value: name,
                    path: "provider.name"
                ))
            }
            if let model = provider.model, model.lowercased().contains(lowercasedQuery) {
                results.append(ConfigSearchResult(
                    section: .provider,
                    key: "model",
                    value: model,
                    path: "provider.model"
                ))
            }
        }
        
        // Search in profiles
        if let profiles = configuration?.profiles {
            for (profileName, _) in profiles {
                if profileName.lowercased().contains(lowercasedQuery) {
                    results.append(ConfigSearchResult(
                        section: .profiles,
                        key: profileName,
                        value: "Profile",
                        path: "profiles.\(profileName)"
                    ))
                }
            }
        }
        
        // Search in extensions
        if let extensions = configuration?.extensions {
            for (extName, ext) in extensions {
                if extName.lowercased().contains(lowercasedQuery) ||
                   (ext.name?.lowercased().contains(lowercasedQuery) ?? false) ||
                   (ext.description?.lowercased().contains(lowercasedQuery) ?? false) {
                    results.append(ConfigSearchResult(
                        section: .extensions,
                        key: extName,
                        value: ext.name ?? extName,
                        path: "extensions.\(extName)"
                    ))
                }
            }
        }
        
        return results
    }
}

struct ConfigSearchResult: Identifiable {
    let id = UUID()
    let section: ConfigSection
    let key: String
    let value: String
    let path: String
}
