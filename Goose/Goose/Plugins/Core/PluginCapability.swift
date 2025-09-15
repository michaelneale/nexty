//
//  PluginCapability.swift
//  Goose
//
//  Created by Goose on 15/09/2025.
//

import Foundation

/// Defines the capabilities that a plugin can provide
public enum PluginCapability: String, CaseIterable, Hashable, Codable {
    /// Plugin can process or modify commands before execution
    case commandProcessor = "commandProcessor"
    
    /// Plugin can format output from command execution
    case outputFormatter = "outputFormatter"
    
    /// Plugin provides UI components or views
    case uiExtension = "uiExtension"
    
    /// Plugin provides custom themes
    case themeProvider = "themeProvider"
    
    /// Plugin can chain commands or create workflows
    case workflowAutomation = "workflowAutomation"
    
    /// Plugin provides data, suggestions, or autocomplete
    case dataProvider = "dataProvider"
    
    /// Plugin can handle keyboard shortcuts
    case hotkeyHandler = "hotkeyHandler"
    
    /// Plugin can integrate with external services
    case externalIntegration = "externalIntegration"
    
    /// Plugin can provide custom settings or preferences
    case settingsProvider = "settingsProvider"
    
    /// Plugin can export or import data
    case dataExporter = "dataExporter"
    
    /// Plugin can provide analytics or monitoring
    case analyticsProvider = "analyticsProvider"
    
    /// Plugin can provide notifications
    case notificationProvider = "notificationProvider"
}

// MARK: - Capability Sets

extension Set where Element == PluginCapability {
    /// Common set of UI-related capabilities
    public static var uiCapabilities: Set<PluginCapability> {
        [.uiExtension, .themeProvider, .settingsProvider]
    }
    
    /// Common set of command-related capabilities
    public static var commandCapabilities: Set<PluginCapability> {
        [.commandProcessor, .outputFormatter, .workflowAutomation]
    }
    
    /// Common set of data-related capabilities
    public static var dataCapabilities: Set<PluginCapability> {
        [.dataProvider, .dataExporter, .analyticsProvider]
    }
}

// MARK: - Capability Requirements

/// Defines requirements for specific capabilities
public struct CapabilityRequirement {
    public let capability: PluginCapability
    public let requiredProtocol: Any.Type?
    public let requiredMethods: [String]
    
    public init(
        capability: PluginCapability,
        requiredProtocol: Any.Type? = nil,
        requiredMethods: [String] = []
    ) {
        self.capability = capability
        self.requiredProtocol = requiredProtocol
        self.requiredMethods = requiredMethods
    }
}

// MARK: - Capability Validation

public extension PluginCapability {
    /// Returns the requirement for this capability
    var requirement: CapabilityRequirement? {
        switch self {
        case .commandProcessor:
            return CapabilityRequirement(
                capability: self,
                requiredMethods: ["preprocessCommand", "postprocessCommand"]
            )
        case .outputFormatter:
            return CapabilityRequirement(
                capability: self,
                requiredMethods: ["formatOutput"]
            )
        case .uiExtension:
            return CapabilityRequirement(
                capability: self,
                requiredMethods: ["provideView"]
            )
        case .themeProvider:
            return CapabilityRequirement(
                capability: self,
                requiredMethods: ["provideTheme"]
            )
        case .workflowAutomation:
            return CapabilityRequirement(
                capability: self,
                requiredMethods: ["createWorkflow", "executeWorkflow"]
            )
        case .dataProvider:
            return CapabilityRequirement(
                capability: self,
                requiredMethods: ["provideData", "provideSuggestions"]
            )
        default:
            return nil
        }
    }
    
    /// Human-readable description of the capability
    var displayName: String {
        switch self {
        case .commandProcessor:
            return "Command Processor"
        case .outputFormatter:
            return "Output Formatter"
        case .uiExtension:
            return "UI Extension"
        case .themeProvider:
            return "Theme Provider"
        case .workflowAutomation:
            return "Workflow Automation"
        case .dataProvider:
            return "Data Provider"
        case .hotkeyHandler:
            return "Hotkey Handler"
        case .externalIntegration:
            return "External Integration"
        case .settingsProvider:
            return "Settings Provider"
        case .dataExporter:
            return "Data Exporter"
        case .analyticsProvider:
            return "Analytics Provider"
        case .notificationProvider:
            return "Notification Provider"
        }
    }
    
    /// Brief description of what the capability does
    var capabilityDescription: String {
        switch self {
        case .commandProcessor:
            return "Process and modify commands before and after execution"
        case .outputFormatter:
            return "Format and style command output"
        case .uiExtension:
            return "Provide custom UI components and views"
        case .themeProvider:
            return "Provide custom visual themes"
        case .workflowAutomation:
            return "Chain commands and create automated workflows"
        case .dataProvider:
            return "Provide data, suggestions, and autocomplete"
        case .hotkeyHandler:
            return "Handle custom keyboard shortcuts"
        case .externalIntegration:
            return "Integrate with external services and APIs"
        case .settingsProvider:
            return "Provide custom settings and preferences"
        case .dataExporter:
            return "Export and import data in various formats"
        case .analyticsProvider:
            return "Provide analytics and usage monitoring"
        case .notificationProvider:
            return "Send notifications to the user"
        }
    }
}
