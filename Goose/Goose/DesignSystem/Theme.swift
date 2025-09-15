//
//  Theme.swift
//  Goose
//
//  Created on 2024-09-15
//  Design system for consistent colors, fonts, and spacing
//

import SwiftUI

// MARK: - Theme
struct Theme {
    // MARK: - Colors
    struct Colors {
        // Primary colors
        static let primary = Color.accentColor
        static let primaryText = Color.primary
        static let secondaryText = Color.secondary
        
        // Background colors
        static let background = Color(NSColor.windowBackgroundColor)
        static let secondaryBackground = Color(NSColor.controlBackgroundColor)
        static let tertiaryBackground = Color(NSColor.textBackgroundColor)
        
        // Status colors
        static let success = Color.green
        static let warning = Color.orange
        static let error = Color.red
        static let info = Color.blue
        
        // Interactive colors
        static let hover = Color.accentColor.opacity(0.1)
        static let pressed = Color.accentColor.opacity(0.2)
        static let focus = Color.accentColor.opacity(0.3)
        
        // Divider
        static let divider = Color(NSColor.separatorColor)
        
        // Terminal colors
        static let terminalBackground = Color(NSColor.textBackgroundColor)
        static let terminalText = Color(NSColor.labelColor)
        static let terminalPrompt = Color.accentColor
    }
    
    // MARK: - Typography
    struct Typography {
        // Headers
        static let largeTitle = Font.system(size: 26, weight: .bold, design: .rounded)
        static let title = Font.system(size: 22, weight: .semibold, design: .rounded)
        static let title2 = Font.system(size: 18, weight: .semibold, design: .rounded)
        static let title3 = Font.system(size: 16, weight: .medium, design: .rounded)
        
        // Body
        static let body = Font.system(size: 13, weight: .regular, design: .default)
        static let bodyMedium = Font.system(size: 13, weight: .medium, design: .default)
        static let caption = Font.system(size: 11, weight: .regular, design: .default)
        
        // Code
        static let code = Font.system(size: 12, weight: .regular, design: .monospaced)
        static let codeBold = Font.system(size: 12, weight: .semibold, design: .monospaced)
    }
    
    // MARK: - Spacing
    struct Spacing {
        static let xxSmall: CGFloat = 2
        static let xSmall: CGFloat = 4
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let xLarge: CGFloat = 24
        static let xxLarge: CGFloat = 32
    }
    
    // MARK: - Corner Radius
    struct CornerRadius {
        static let small: CGFloat = 4
        static let medium: CGFloat = 8
        static let large: CGFloat = 12
        static let xLarge: CGFloat = 16
    }
    
    // MARK: - Shadows
    struct Shadows {
        static let small = ShadowStyle(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        static let medium = ShadowStyle(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        static let large = ShadowStyle(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
    }
    
    // MARK: - Animation
    struct Animation {
        static let quick = SwiftUI.Animation.easeInOut(duration: 0.15)
        static let standard = SwiftUI.Animation.easeInOut(duration: 0.25)
        static let smooth = SwiftUI.Animation.easeInOut(duration: 0.35)
        static let spring = SwiftUI.Animation.spring(response: 0.35, dampingFraction: 0.8, blendDuration: 0)
        static let bouncy = SwiftUI.Animation.spring(response: 0.4, dampingFraction: 0.6, blendDuration: 0)
    }
}

// MARK: - Shadow Style
struct ShadowStyle {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
    
    init(color: Color, radius: CGFloat, x: CGFloat = 0, y: CGFloat = 0) {
        self.color = color
        self.radius = radius
        self.x = x
        self.y = y
    }
}

// MARK: - Theme Environment Key
struct ThemeEnvironmentKey: EnvironmentKey {
    static let defaultValue = Theme()
}

extension EnvironmentValues {
    var theme: Theme {
        get { self[ThemeEnvironmentKey.self] }
        set { self[ThemeEnvironmentKey.self] = newValue }
    }
}
