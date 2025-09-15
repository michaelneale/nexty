//
//  Theme.swift
//  Goose
//
//  Created on 2024-09-15
//  Design system for consistent colors, fonts, and spacing
//

import SwiftUI
import AppKit

// MARK: - Theme
/// The central design system for the Goose app, providing consistent colors, typography, spacing, and styling patterns
struct Theme {
    // MARK: - Colors
    struct Colors {
        // MARK: Semantic Colors
        
        /// Primary brand color - used for key actions and highlights
        static let primary = Color.accentColor
        
        /// Primary text color - main content
        static let primaryText = Color(NSColor.labelColor)
        
        /// Secondary text color - supporting content
        static let secondaryText = Color(NSColor.secondaryLabelColor)
        
        /// Tertiary text color - least important content
        static let tertiaryText = Color(NSColor.tertiaryLabelColor)
        
        /// Quaternary text color - disabled or placeholder content
        static let quaternaryText = Color(NSColor.quaternaryLabelColor)
        
        // MARK: Background Colors
        
        /// Main window background
        static let background = Color(NSColor.windowBackgroundColor)
        
        /// Secondary background for cards, sections
        static let secondaryBackground = Color(NSColor.controlBackgroundColor)
        
        /// Tertiary background for nested content
        static let tertiaryBackground = Color(NSColor.textBackgroundColor)
        
        /// Grouped background for table/list sections
        static let groupedBackground = Color(NSColor.underPageBackgroundColor)
        
        // MARK: Status Colors
        
        /// Success state - positive actions, confirmations
        static let success = Color(NSColor.systemGreen)
        
        /// Warning state - caution, non-critical issues
        static let warning = Color(NSColor.systemOrange)
        
        /// Error state - failures, critical issues
        static let error = Color(NSColor.systemRed)
        
        /// Info state - informational messages
        static let info = Color(NSColor.systemBlue)
        
        // MARK: Interactive State Colors
        
        /// Hover state overlay
        static let hover = Color(NSColor.selectedContentBackgroundColor).opacity(0.08)
        
        /// Pressed/active state overlay
        static let pressed = Color(NSColor.selectedContentBackgroundColor).opacity(0.12)
        
        /// Focus ring color
        static let focus = Color(NSColor.keyboardFocusIndicatorColor)
        
        /// Disabled state overlay
        static let disabled = Color(NSColor.quaternaryLabelColor).opacity(0.3)
        
        /// Selected item background
        static let selected = Color(NSColor.selectedContentBackgroundColor)
        
        // MARK: Accent Color Variations
        
        /// Light variant of accent color
        static let accentLight = Color.accentColor.opacity(0.8)
        
        /// Dark variant of accent color
        static let accentDark = Color.accentColor.opacity(1.0)
        
        /// Subtle accent for backgrounds
        static let accentSubtle = Color.accentColor.opacity(0.1)
        
        // MARK: UI Element Colors
        
        /// Divider/separator color
        static let divider = Color(NSColor.separatorColor)
        
        /// Border color for inputs and containers
        static let border = Color(NSColor.gridColor)
        
        /// Control tint color
        static let controlTint = Color(NSColor.controlAccentColor)
        
        // MARK: Terminal/Code Colors
        
        /// Terminal background
        static let terminalBackground = Color(NSColor.textBackgroundColor)
        
        /// Terminal text
        static let terminalText = Color(NSColor.labelColor)
        
        /// Terminal prompt/cursor
        static let terminalPrompt = Color.accentColor
        
        /// Code syntax - keywords
        static let codeKeyword = Color(NSColor.systemPurple)
        
        /// Code syntax - strings
        static let codeString = Color(NSColor.systemGreen)
        
        /// Code syntax - comments
        static let codeComment = Color(NSColor.tertiaryLabelColor)
        
        // MARK: Accessibility Colors
        
        /// High contrast border for increased contrast mode
        static var highContrastBorder: Color {
            NSWorkspace.shared.accessibilityDisplayShouldIncreaseContrast
                ? Color(NSColor.labelColor)
                : Color(NSColor.gridColor)
        }
        
        /// High contrast text for increased contrast mode
        static var highContrastText: Color {
            NSWorkspace.shared.accessibilityDisplayShouldIncreaseContrast
                ? Color(NSColor.labelColor)
                : Color(NSColor.secondaryLabelColor)
        }
    }
    
    // MARK: - Typography
    struct Typography {
        // MARK: Headers - Using SF Pro Rounded for personality
        
        /// Extra large title - 28pt bold
        static let largeTitle = Font.system(size: 28, weight: .bold, design: .rounded)
        
        /// Title 1 - 22pt semibold
        static let title1 = Font.system(size: 22, weight: .semibold, design: .rounded)
        
        /// Title 2 - 18pt semibold
        static let title2 = Font.system(size: 18, weight: .semibold, design: .rounded)
        
        /// Title 3 - 16pt medium
        static let title3 = Font.system(size: 16, weight: .medium, design: .rounded)
        
        /// Headline - 14pt semibold
        static let headline = Font.system(size: 14, weight: .semibold, design: .default)
        
        // MARK: Body Text - Using SF Pro for clarity
        
        /// Body text - 13pt regular (macOS standard)
        static let body = Font.system(size: 13, weight: .regular, design: .default)
        
        /// Body emphasis - 13pt medium
        static let bodyEmphasized = Font.system(size: 13, weight: .medium, design: .default)
        
        /// Callout text - 12pt regular
        static let callout = Font.system(size: 12, weight: .regular, design: .default)
        
        /// Footnote text - 11pt regular
        static let footnote = Font.system(size: 11, weight: .regular, design: .default)
        
        /// Caption text - 10pt regular
        static let caption1 = Font.system(size: 10, weight: .regular, design: .default)
        
        /// Small caption - 10pt light
        static let caption2 = Font.system(size: 10, weight: .light, design: .default)
        
        // MARK: Code/Monospace - Using SF Mono
        
        /// Code text - 12pt regular monospace
        static let code = Font.system(size: 12, weight: .regular, design: .monospaced)
        
        /// Code emphasized - 12pt semibold monospace
        static let codeEmphasized = Font.system(size: 12, weight: .semibold, design: .monospaced)
        
        /// Small code - 11pt regular monospace
        static let codeSmall = Font.system(size: 11, weight: .regular, design: .monospaced)
    }
    
    // MARK: - Spacing (4pt/8pt Grid System)
    struct Spacing {
        /// 2pt - Minimal spacing
        static let xxSmall: CGFloat = 2
        
        /// 4pt - Extra small spacing
        static let xSmall: CGFloat = 4
        
        /// 8pt - Small spacing (base unit)
        static let small: CGFloat = 8
        
        /// 12pt - Medium spacing
        static let medium: CGFloat = 12
        
        /// 16pt - Large spacing (2x base)
        static let large: CGFloat = 16
        
        /// 24pt - Extra large spacing (3x base)
        static let xLarge: CGFloat = 24
        
        /// 32pt - 2x large spacing (4x base)
        static let xxLarge: CGFloat = 32
        
        /// 48pt - 3x large spacing (6x base)
        static let xxxLarge: CGFloat = 48
        
        // MARK: Layout Guides
        
        /// Standard margin for window content
        static let windowMargin: CGFloat = 20
        
        /// Standard padding for containers
        static let containerPadding: CGFloat = 16
        
        /// Standard gap between related elements
        static let itemGap: CGFloat = 8
        
        /// Standard gap between sections
        static let sectionGap: CGFloat = 24
    }
    
    // MARK: - Corner Radius
    struct CornerRadius {
        /// 4pt - Small elements (buttons, tags)
        static let xSmall: CGFloat = 4
        
        /// 6pt - Small-medium elements
        static let small: CGFloat = 6
        
        /// 8pt - Medium elements (cards, inputs)
        static let medium: CGFloat = 8
        
        /// 10pt - Medium-large elements
        static let mediumLarge: CGFloat = 10
        
        /// 12pt - Large elements (modals, popovers)
        static let large: CGFloat = 12
        
        /// 16pt - Extra large elements (panels)
        static let xLarge: CGFloat = 16
        
        /// Full radius for circular elements
        static let full: CGFloat = 9999
    }
    
    // MARK: - Shadows
    struct Shadows {
        /// Subtle shadow for slight elevation
        static let subtle = ShadowStyle(
            color: Color.black.opacity(0.03),
            radius: 1,
            x: 0,
            y: 1
        )
        
        /// Small shadow for buttons, inputs
        static let small = ShadowStyle(
            color: Color.black.opacity(0.05),
            radius: 2,
            x: 0,
            y: 1
        )
        
        /// Medium shadow for cards, dropdowns
        static let medium = ShadowStyle(
            color: Color.black.opacity(0.08),
            radius: 4,
            x: 0,
            y: 2
        )
        
        /// Large shadow for modals, popovers
        static let large = ShadowStyle(
            color: Color.black.opacity(0.12),
            radius: 8,
            x: 0,
            y: 4
        )
        
        /// Extra large shadow for floating elements
        static let xLarge = ShadowStyle(
            color: Color.black.opacity(0.16),
            radius: 16,
            x: 0,
            y: 8
        )
    }
    
    // MARK: - Borders
    struct Borders {
        /// Thin border - 0.5pt
        static let thin: CGFloat = 0.5
        
        /// Regular border - 1pt
        static let regular: CGFloat = 1.0
        
        /// Medium border - 1.5pt
        static let medium: CGFloat = 1.5
        
        /// Thick border - 2pt
        static let thick: CGFloat = 2.0
        
        /// Focus ring width
        static let focusRing: CGFloat = 2.0
    }
    
    // MARK: - Opacity
    struct Opacity {
        /// Barely visible - 5%
        static let barelyVisible: Double = 0.05
        
        /// Very subtle - 10%
        static let verySubtle: Double = 0.1
        
        /// Subtle - 20%
        static let subtle: Double = 0.2
        
        /// Light - 30%
        static let light: Double = 0.3
        
        /// Medium - 50%
        static let medium: Double = 0.5
        
        /// Strong - 70%
        static let strong: Double = 0.7
        
        /// Very strong - 90%
        static let veryStrong: Double = 0.9
        
        /// Disabled elements
        static let disabled: Double = 0.4
    }
    
    // MARK: - Blur Effects
    struct BlurEffects {
        /// Subtle blur for overlays
        static let subtle: CGFloat = 2
        
        /// Light blur for backgrounds
        static let light: CGFloat = 5
        
        /// Medium blur for modal backgrounds
        static let medium: CGFloat = 10
        
        /// Strong blur for frosted glass effects
        static let strong: CGFloat = 20
        
        /// Material blur radius
        static let material: CGFloat = 30
    }
    
    // MARK: - Animation
    struct Animation {
        /// Instant - 0.1s for immediate feedback
        static let instant = SwiftUI.Animation.easeInOut(duration: 0.1)
        
        /// Quick - 0.15s for micro-interactions
        static let quick = SwiftUI.Animation.easeInOut(duration: 0.15)
        
        /// Standard - 0.25s for most transitions
        static let standard = SwiftUI.Animation.easeInOut(duration: 0.25)
        
        /// Smooth - 0.35s for larger state changes
        static let smooth = SwiftUI.Animation.easeInOut(duration: 0.35)
        
        /// Slow - 0.5s for complex animations
        static let slow = SwiftUI.Animation.easeInOut(duration: 0.5)
        
        /// Spring animation for interactive elements
        static let spring = SwiftUI.Animation.spring(
            response: 0.35,
            dampingFraction: 0.8,
            blendDuration: 0
        )
        
        /// Bouncy spring for playful interactions
        static let bouncy = SwiftUI.Animation.spring(
            response: 0.4,
            dampingFraction: 0.6,
            blendDuration: 0
        )
        
        /// Gentle spring for subtle movements
        static let gentle = SwiftUI.Animation.spring(
            response: 0.5,
            dampingFraction: 0.9,
            blendDuration: 0
        )
        
        /// Check if reduce motion is enabled
        static var reduceMotion: Bool {
            NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
        }
        
        /// Get appropriate animation based on accessibility settings
        static func appropriate(_ animation: SwiftUI.Animation) -> SwiftUI.Animation {
            reduceMotion ? .linear(duration: 0) : animation
        }
    }
    
    // MARK: - Icons
    struct Icons {
        /// Icon sizes aligned to SF Symbols standards
        enum Size: CGFloat {
            case mini = 12      // Mini icons
            case small = 16     // Small icons (default for inline)
            case regular = 20   // Regular icons (default for UI)
            case medium = 24    // Medium icons
            case large = 32     // Large icons
            case xLarge = 48    // Extra large icons
        }
        
        /// Icon weights for SF Symbols
        enum Weight {
            case ultraLight
            case thin
            case light
            case regular
            case medium
            case semibold
            case bold
            case heavy
            case black
            
            var fontWeight: Font.Weight {
                switch self {
                case .ultraLight: return .ultraLight
                case .thin: return .thin
                case .light: return .light
                case .regular: return .regular
                case .medium: return .medium
                case .semibold: return .semibold
                case .bold: return .bold
                case .heavy: return .heavy
                case .black: return .black
                }
            }
        }
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
