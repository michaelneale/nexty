//
//  DesignSystemPreview.swift
//  Goose
//
//  Created on 2024-09-15
//  Visual showcase of all design system elements for testing and documentation
//

import SwiftUI

// MARK: - Design System Preview
struct DesignSystemPreview: View {
    @State private var selectedTab = 0
    @State private var isLoading = false
    @State private var showNotification = false
    @State private var isDarkMode = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
            
            // Tab Selection
            tabSelector
            
            Divider()
            
            // Content
            ScrollView {
                VStack(spacing: Theme.Spacing.sectionGap) {
                    switch selectedTab {
                    case 0:
                        colorsSection
                    case 1:
                        typographySection
                    case 2:
                        spacingSection
                    case 3:
                        componentsSection
                    case 4:
                        iconsSection
                    case 5:
                        animationsSection
                    default:
                        EmptyView()
                    }
                }
                .padding(Theme.Spacing.windowMargin)
            }
        }
        .frame(width: 900, height: 700)
        .background(Theme.Colors.background)
        .preferredColorScheme(isDarkMode ? .dark : .light)
    }
    
    // MARK: - Header
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: Theme.Spacing.xSmall) {
                Text("Design System Preview")
                    .font(Theme.Typography.largeTitle)
                    .foregroundColor(Theme.Colors.primaryText)
                
                Text("Visual showcase of all design elements")
                    .font(Theme.Typography.body)
                    .foregroundColor(Theme.Colors.secondaryText)
            }
            
            Spacer()
            
            Toggle("Dark Mode", isOn: $isDarkMode)
                .toggleStyle(SwitchToggleStyle())
        }
        .padding(Theme.Spacing.windowMargin)
        .background(Theme.Colors.secondaryBackground)
    }
    
    // MARK: - Tab Selector
    private var tabSelector: some View {
        HStack(spacing: Theme.Spacing.large) {
            ForEach(0..<6) { index in
                Button(action: { selectedTab = index }) {
                    Text(tabTitle(for: index))
                        .font(Theme.Typography.bodyEmphasized)
                        .foregroundColor(selectedTab == index ? Theme.Colors.primary : Theme.Colors.secondaryText)
                        .padding(.vertical, Theme.Spacing.small)
                        .padding(.horizontal, Theme.Spacing.medium)
                        .background(
                            selectedTab == index ? Theme.Colors.accentSubtle : Color.clear
                        )
                        .cornerRadius(Theme.CornerRadius.small)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, Theme.Spacing.windowMargin)
        .padding(.vertical, Theme.Spacing.medium)
    }
    
    private func tabTitle(for index: Int) -> String {
        switch index {
        case 0: return "Colors"
        case 1: return "Typography"
        case 2: return "Spacing"
        case 3: return "Components"
        case 4: return "Icons"
        case 5: return "Animations"
        default: return ""
        }
    }
    
    // MARK: - Colors Section
    private var colorsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.large) {
            sectionHeader("Color Palette")
            
            // Semantic Colors
            Group {
                colorGroup("Text Colors", colors: [
                    ("Primary", Theme.Colors.primaryText),
                    ("Secondary", Theme.Colors.secondaryText),
                    ("Tertiary", Theme.Colors.tertiaryText),
                    ("Quaternary", Theme.Colors.quaternaryText)
                ])
                
                colorGroup("Background Colors", colors: [
                    ("Primary", Theme.Colors.background),
                    ("Secondary", Theme.Colors.secondaryBackground),
                    ("Tertiary", Theme.Colors.tertiaryBackground),
                    ("Grouped", Theme.Colors.groupedBackground)
                ])
                
                colorGroup("Status Colors", colors: [
                    ("Success", Theme.Colors.success),
                    ("Warning", Theme.Colors.warning),
                    ("Error", Theme.Colors.error),
                    ("Info", Theme.Colors.info)
                ])
                
                colorGroup("Interactive States", colors: [
                    ("Hover", Theme.Colors.hover),
                    ("Pressed", Theme.Colors.pressed),
                    ("Focus", Theme.Colors.focus),
                    ("Disabled", Theme.Colors.disabled),
                    ("Selected", Theme.Colors.selected)
                ])
                
                colorGroup("Accent Variations", colors: [
                    ("Primary", Theme.Colors.primary),
                    ("Light", Theme.Colors.accentLight),
                    ("Dark", Theme.Colors.accentDark),
                    ("Subtle", Theme.Colors.accentSubtle)
                ])
            }
        }
    }
    
    private func colorGroup(_ title: String, colors: [(String, Color)]) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.medium) {
            Text(title)
                .font(Theme.Typography.headline)
                .foregroundColor(Theme.Colors.primaryText)
            
            HStack(spacing: Theme.Spacing.medium) {
                ForEach(colors, id: \.0) { name, color in
                    VStack(spacing: Theme.Spacing.small) {
                        RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                            .fill(color)
                            .frame(width: 80, height: 60)
                            .overlay(
                                RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                                    .stroke(Theme.Colors.border, lineWidth: Theme.Borders.thin)
                            )
                        
                        Text(name)
                            .font(Theme.Typography.caption1)
                            .foregroundColor(Theme.Colors.secondaryText)
                    }
                }
            }
        }
    }
    
    // MARK: - Typography Section
    private var typographySection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.large) {
            sectionHeader("Typography Scale")
            
            VStack(alignment: .leading, spacing: Theme.Spacing.medium) {
                typographyExample("Large Title", Theme.Typography.largeTitle)
                typographyExample("Title 1", Theme.Typography.title1)
                typographyExample("Title 2", Theme.Typography.title2)
                typographyExample("Title 3", Theme.Typography.title3)
                typographyExample("Headline", Theme.Typography.headline)
                typographyExample("Body", Theme.Typography.body)
                typographyExample("Body Emphasized", Theme.Typography.bodyEmphasized)
                typographyExample("Callout", Theme.Typography.callout)
                typographyExample("Footnote", Theme.Typography.footnote)
                typographyExample("Caption 1", Theme.Typography.caption1)
                typographyExample("Caption 2", Theme.Typography.caption2)
                
                Divider().padding(.vertical, Theme.Spacing.small)
                
                typographyExample("Code", Theme.Typography.code)
                typographyExample("Code Emphasized", Theme.Typography.codeEmphasized)
                typographyExample("Code Small", Theme.Typography.codeSmall)
            }
        }
    }
    
    private func typographyExample(_ name: String, _ font: Font) -> some View {
        HStack {
            Text(name)
                .font(Theme.Typography.body)
                .foregroundColor(Theme.Colors.secondaryText)
                .frame(width: 150, alignment: .leading)
            
            Text("The quick brown fox jumps over the lazy dog")
                .font(font)
                .foregroundColor(Theme.Colors.primaryText)
            
            Spacer()
        }
    }
    
    // MARK: - Spacing Section
    private var spacingSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.large) {
            sectionHeader("Spacing System")
            
            VStack(alignment: .leading, spacing: Theme.Spacing.large) {
                spacingExample("xxSmall", Theme.Spacing.xxSmall, "2pt")
                spacingExample("xSmall", Theme.Spacing.xSmall, "4pt")
                spacingExample("Small", Theme.Spacing.small, "8pt")
                spacingExample("Medium", Theme.Spacing.medium, "12pt")
                spacingExample("Large", Theme.Spacing.large, "16pt")
                spacingExample("xLarge", Theme.Spacing.xLarge, "24pt")
                spacingExample("xxLarge", Theme.Spacing.xxLarge, "32pt")
                spacingExample("xxxLarge", Theme.Spacing.xxxLarge, "48pt")
            }
            
            Divider().padding(.vertical, Theme.Spacing.medium)
            
            sectionHeader("Layout Guides")
            
            VStack(alignment: .leading, spacing: Theme.Spacing.medium) {
                layoutGuideExample("Window Margin", Theme.Spacing.windowMargin)
                layoutGuideExample("Container Padding", Theme.Spacing.containerPadding)
                layoutGuideExample("Item Gap", Theme.Spacing.itemGap)
                layoutGuideExample("Section Gap", Theme.Spacing.sectionGap)
            }
        }
    }
    
    private func spacingExample(_ name: String, _ spacing: CGFloat, _ value: String) -> some View {
        HStack(spacing: Theme.Spacing.medium) {
            Text(name)
                .font(Theme.Typography.body)
                .foregroundColor(Theme.Colors.secondaryText)
                .frame(width: 100, alignment: .leading)
            
            Text(value)
                .font(Theme.Typography.caption1)
                .foregroundColor(Theme.Colors.tertiaryText)
                .frame(width: 40)
            
            Rectangle()
                .fill(Theme.Colors.primary)
                .frame(width: spacing, height: 20)
            
            Rectangle()
                .fill(Theme.Colors.accentSubtle)
                .frame(width: 200, height: 20)
        }
    }
    
    private func layoutGuideExample(_ name: String, _ spacing: CGFloat) -> some View {
        HStack {
            Text(name)
                .font(Theme.Typography.body)
                .foregroundColor(Theme.Colors.secondaryText)
                .frame(width: 150, alignment: .leading)
            
            Text("\(Int(spacing))pt")
                .font(Theme.Typography.code)
                .foregroundColor(Theme.Colors.primary)
        }
    }
    
    // MARK: - Components Section
    private var componentsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.large) {
            sectionHeader("Component Examples")
            
            // Cards
            VStack(alignment: .leading, spacing: Theme.Spacing.medium) {
                Text("Cards")
                    .font(Theme.Typography.headline)
                
                HStack(spacing: Theme.Spacing.medium) {
                    Text("Default Card")
                        .cardStyle()
                    
                    Text("Large Shadow Card")
                        .cardStyle(shadow: Theme.Shadows.large)
                    
                    Text("Custom Color Card")
                        .cardStyle(backgroundColor: Theme.Colors.accentSubtle)
                }
            }
            
            // Buttons
            VStack(alignment: .leading, spacing: Theme.Spacing.medium) {
                Text("Buttons")
                    .font(Theme.Typography.headline)
                
                HStack(spacing: Theme.Spacing.medium) {
                    Button("Primary Button") {}
                        .buttonStyle(.borderedProminent)
                    
                    Button("Secondary Button") {}
                        .buttonStyle(.bordered)
                    
                    Button("Plain Button") {}
                        .buttonStyle(.plain)
                        .foregroundColor(Theme.Colors.primary)
                }
            }
            
            // Badges
            VStack(alignment: .leading, spacing: Theme.Spacing.medium) {
                Text("Badges")
                    .font(Theme.Typography.headline)
                
                HStack(spacing: Theme.Spacing.medium) {
                    Text("Default")
                        .badge()
                    
                    Text("Success")
                        .badge(color: Theme.Colors.success)
                    
                    Text("Prominent")
                        .badge(color: Theme.Colors.error, isProminant: true)
                }
            }
            
            // Terminal Style
            VStack(alignment: .leading, spacing: Theme.Spacing.medium) {
                Text("Terminal Style")
                    .font(Theme.Typography.headline)
                
                Text("$ goose run --help")
                    .terminalStyle()
            }
            
            // Glass Morphism
            VStack(alignment: .leading, spacing: Theme.Spacing.medium) {
                Text("Glass Morphism")
                    .font(Theme.Typography.headline)
                
                Text("Glassmorphic Container")
                    .padding(Theme.Spacing.large)
                    .glassMorphism()
            }
        }
    }
    
    // MARK: - Icons Section
    private var iconsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.large) {
            sectionHeader("Icon System")
            
            // Icon Sizes
            VStack(alignment: .leading, spacing: Theme.Spacing.medium) {
                Text("Icon Sizes")
                    .font(Theme.Typography.headline)
                
                HStack(spacing: Theme.Spacing.large) {
                    iconSizeExample("Mini", .mini)
                    iconSizeExample("Small", .small)
                    iconSizeExample("Regular", .regular)
                    iconSizeExample("Medium", .medium)
                    iconSizeExample("Large", .large)
                    iconSizeExample("XLarge", .xLarge)
                }
            }
            
            // Common Icons
            VStack(alignment: .leading, spacing: Theme.Spacing.medium) {
                Text("Common Icons")
                    .font(Theme.Typography.headline)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: Theme.Spacing.medium) {
                    iconExample(Icon.System.search, "Search")
                    iconExample(Icon.System.settings, "Settings")
                    iconExample(Icon.System.user, "User")
                    iconExample(Icon.System.notification, "Bell")
                    iconExample(Icon.System.folder, "Folder")
                    iconExample(Icon.System.terminal, "Terminal")
                    iconExample(Icon.System.checkmarkCircle, "Success")
                    iconExample(Icon.System.warning, "Warning")
                }
            }
            
            // Icon Badges
            VStack(alignment: .leading, spacing: Theme.Spacing.medium) {
                Text("Icon Badges")
                    .font(Theme.Typography.headline)
                
                HStack(spacing: Theme.Spacing.large) {
                    IconBadge(systemName: Icon.System.notification, badgeCount: 3)
                    IconBadge(systemName: Icon.System.notification, badgeCount: 99)
                    IconBadge(systemName: Icon.System.notification, badgeCount: 150)
                }
            }
        }
    }
    
    private func iconSizeExample(_ name: String, _ size: Theme.Icons.Size) -> some View {
        VStack(spacing: Theme.Spacing.small) {
            Icon.view(Icon.System.star, size: size, color: Theme.Colors.primary)
            Text(name)
                .font(Theme.Typography.caption1)
                .foregroundColor(Theme.Colors.secondaryText)
        }
    }
    
    private func iconExample(_ icon: String, _ name: String) -> some View {
        VStack(spacing: Theme.Spacing.xSmall) {
            Icon.view(icon, size: .medium, color: Theme.Colors.primary)
            Text(name)
                .font(Theme.Typography.caption1)
                .foregroundColor(Theme.Colors.secondaryText)
        }
    }
    
    // MARK: - Animations Section
    private var animationsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.large) {
            sectionHeader("Animation Examples")
            
            VStack(alignment: .leading, spacing: Theme.Spacing.large) {
                // Animated Icons
                Text("Animated Icons")
                    .font(Theme.Typography.headline)
                
                HStack(spacing: Theme.Spacing.xLarge) {
                    VStack {
                        Icon.animated(Icon.System.refresh, animation: .rotate)
                        Text("Rotate")
                            .font(Theme.Typography.caption1)
                    }
                    
                    VStack {
                        Icon.animated(Icon.System.heart, animation: .pulse)
                        Text("Pulse")
                            .font(Theme.Typography.caption1)
                    }
                    
                    VStack {
                        Icon.animated(Icon.System.notification, animation: .bounce)
                        Text("Bounce")
                            .font(Theme.Typography.caption1)
                    }
                    
                    VStack {
                        Icon.animated(Icon.System.star, animation: .scale)
                        Text("Scale")
                            .font(Theme.Typography.caption1)
                    }
                }
                
                // Loading State
                Text("Loading Overlay")
                    .font(Theme.Typography.headline)
                
                Button("Toggle Loading") {
                    isLoading.toggle()
                }
                .buttonStyle(.borderedProminent)
                
                Text("This content will blur when loading")
                    .padding(Theme.Spacing.large)
                    .frame(width: 300, height: 100)
                    .background(Theme.Colors.secondaryBackground)
                    .cornerRadius(Theme.CornerRadius.medium)
                    .loadingOverlay(isLoading: isLoading, message: "Processing...")
            }
        }
    }
    
    // MARK: - Helpers
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(Theme.Typography.title2)
            .foregroundColor(Theme.Colors.primaryText)
    }
}

// MARK: - Preview Provider
struct DesignSystemPreview_Previews: PreviewProvider {
    static var previews: some View {
        DesignSystemPreview()
            .previewDisplayName("Light Mode")
        
        DesignSystemPreview()
            .preferredColorScheme(.dark)
            .previewDisplayName("Dark Mode")
    }
}
