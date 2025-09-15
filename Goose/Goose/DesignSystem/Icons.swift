//
//  Icons.swift
//  Goose
//
//  Created on 2024-09-15
//  Icon system utilities and guidelines for SF Symbols usage
//

import SwiftUI

// MARK: - Icon System
/// Centralized icon management for consistent SF Symbols usage throughout the app
struct Icon {
    
    // MARK: - Common Icons
    struct System {
        // Navigation
        static let chevronRight = "chevron.right"
        static let chevronLeft = "chevron.left"
        static let chevronDown = "chevron.down"
        static let chevronUp = "chevron.up"
        static let arrowRight = "arrow.right"
        static let arrowLeft = "arrow.left"
        
        // Actions
        static let plus = "plus"
        static let minus = "minus"
        static let close = "xmark"
        static let search = "magnifyingglass"
        static let filter = "line.3.horizontal.decrease.circle"
        static let sort = "arrow.up.arrow.down"
        static let refresh = "arrow.clockwise"
        static let share = "square.and.arrow.up"
        static let copy = "doc.on.doc"
        static let paste = "doc.on.clipboard"
        static let delete = "trash"
        static let edit = "pencil"
        
        // Status
        static let checkmark = "checkmark"
        static let checkmarkCircle = "checkmark.circle.fill"
        static let warning = "exclamationmark.triangle.fill"
        static let error = "xmark.circle.fill"
        static let info = "info.circle.fill"
        static let question = "questionmark.circle"
        
        // UI Elements
        static let menu = "line.3.horizontal"
        static let grid = "square.grid.3x3"
        static let list = "list.bullet"
        static let sidebar = "sidebar.left"
        static let settings = "gearshape"
        static let user = "person.circle"
        static let notification = "bell"
        static let bookmark = "bookmark"
        static let star = "star"
        static let heart = "heart"
        
        // File & Folder
        static let folder = "folder"
        static let folderOpen = "folder.fill"
        static let file = "doc"
        static let fileText = "doc.text"
        static let fileCode = "doc.text.magnifyingglass"
        
        // Terminal & Code
        static let terminal = "terminal"
        static let code = "chevron.left.slash.chevron.right"
        static let curlybraces = "curlybraces"
        static let function = "function"
        
        // System
        static let keyboard = "keyboard"
        static let mouse = "computermouse"
        static let display = "display"
        static let cpu = "cpu"
        static let memory = "memorychip"
        static let network = "network"
    }
    
    // MARK: - App Specific Icons
    struct App {
        static let goose = "bird"  // Placeholder - could use custom icon
        static let command = "command"
        static let output = "text.alignleft"
        static let history = "clock.arrow.circlepath"
        static let suggestion = "lightbulb"
        static let execute = "play.circle"
        static let stop = "stop.circle"
        static let clear = "clear"
    }
    
    // MARK: - Icon View Helper
    /// Creates a standardized icon view with consistent sizing and styling
    static func view(
        _ systemName: String,
        size: Theme.Icons.Size = .regular,
        weight: Theme.Icons.Weight = .regular,
        color: Color? = nil
    ) -> some View {
        Image(systemName: systemName)
            .font(.system(size: size.rawValue, weight: weight.fontWeight))
            .foregroundColor(color ?? Theme.Colors.primaryText)
            .accessibilityHidden(true)
    }
    
    // MARK: - Animated Icon View
    /// Creates an icon with optional animation effects
    static func animated(
        _ systemName: String,
        size: Theme.Icons.Size = .regular,
        weight: Theme.Icons.Weight = .regular,
        color: Color? = nil,
        animation: IconAnimation = .none
    ) -> some View {
        AnimatedIcon(
            systemName: systemName,
            size: size,
            weight: weight,
            color: color,
            animation: animation
        )
    }
}

// MARK: - Icon Animation Types
enum IconAnimation {
    case none
    case pulse
    case rotate
    case bounce
    case scale
}

// MARK: - Animated Icon View
private struct AnimatedIcon: View {
    let systemName: String
    let size: Theme.Icons.Size
    let weight: Theme.Icons.Weight
    let color: Color?
    let animation: IconAnimation
    
    @State private var isAnimating = false
    
    var body: some View {
        Icon.view(systemName, size: size, weight: weight, color: color)
            .scaleEffect(scaleAmount)
            .opacity(opacityAmount)
            .rotationEffect(rotationAmount)
            .offset(y: offsetAmount)
            .onAppear {
                if animation != .none {
                    startAnimation()
                }
            }
    }
    
    private var scaleAmount: CGFloat {
        switch animation {
        case .pulse:
            return isAnimating ? 1.2 : 1.0
        case .scale:
            return isAnimating ? 1.1 : 0.9
        default:
            return 1.0
        }
    }
    
    private var opacityAmount: Double {
        switch animation {
        case .pulse:
            return isAnimating ? 0.8 : 1.0
        default:
            return 1.0
        }
    }
    
    private var rotationAmount: Angle {
        switch animation {
        case .rotate:
            return .degrees(isAnimating ? 360 : 0)
        default:
            return .degrees(0)
        }
    }
    
    private var offsetAmount: CGFloat {
        switch animation {
        case .bounce:
            return isAnimating ? -5 : 0
        default:
            return 0
        }
    }
    
    private func startAnimation() {
        let animationToUse: Animation? = {
            switch animation {
            case .none:
                return nil
            case .pulse:
                return Theme.Animation.appropriate(
                    .easeInOut(duration: 1.0).repeatForever(autoreverses: true)
                )
            case .rotate:
                return Theme.Animation.appropriate(
                    .linear(duration: 2.0).repeatForever(autoreverses: false)
                )
            case .bounce:
                return Theme.Animation.appropriate(
                    .easeInOut(duration: 0.6).repeatForever(autoreverses: true)
                )
            case .scale:
                return Theme.Animation.appropriate(
                    .easeInOut(duration: 0.8).repeatForever(autoreverses: true)
                )
            }
        }()
        
        if let animation = animationToUse {
            withAnimation(animation) {
                isAnimating = true
            }
        }
    }
}

// MARK: - Icon Button Style
/// A button style specifically designed for icon-only buttons
struct IconButtonStyle: ButtonStyle {
    var size: Theme.Icons.Size = .regular
    var color: Color = Theme.Colors.primary
    var hoverColor: Color? = nil
    
    @State private var isHovered = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(
                configuration.isPressed ? color.opacity(0.6) :
                isHovered ? (hoverColor ?? color.opacity(0.8)) : color
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(Theme.Animation.appropriate(Theme.Animation.quick), value: configuration.isPressed)
            .animation(Theme.Animation.appropriate(Theme.Animation.quick), value: isHovered)
            .onHover { hovering in
                isHovered = hovering
            }
    }
}

// MARK: - Icon Badge View
/// A view that displays an icon with an optional badge
struct IconBadge: View {
    let systemName: String
    let badgeCount: Int?
    let size: Theme.Icons.Size
    let color: Color
    
    init(
        systemName: String,
        badgeCount: Int? = nil,
        size: Theme.Icons.Size = .regular,
        color: Color = Theme.Colors.primaryText
    ) {
        self.systemName = systemName
        self.badgeCount = badgeCount
        self.size = size
        self.color = color
    }
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            Icon.view(systemName, size: size, color: color)
            
            if let count = badgeCount, count > 0 {
                Text(count > 99 ? "99+" : "\(count)")
                    .font(Theme.Typography.caption1)
                    .foregroundColor(.white)
                    .padding(.horizontal, Theme.Spacing.xSmall)
                    .padding(.vertical, Theme.Spacing.xxSmall)
                    .background(Theme.Colors.error)
                    .clipShape(Capsule())
                    .offset(x: size.rawValue * 0.3, y: -size.rawValue * 0.3)
            }
        }
    }
}

// MARK: - Icon List Item
/// A reusable component for list items with icons
struct IconListItem: View {
    let icon: String
    let title: String
    let subtitle: String?
    let iconColor: Color
    let action: () -> Void
    
    init(
        icon: String,
        title: String,
        subtitle: String? = nil,
        iconColor: Color = Theme.Colors.primary,
        action: @escaping () -> Void = {}
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.iconColor = iconColor
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.medium) {
                Icon.view(icon, size: .medium, color: iconColor)
                    .frame(width: 32, height: 32)
                    .background(iconColor.opacity(Theme.Opacity.verySubtle))
                    .cornerRadius(Theme.CornerRadius.small)
                
                VStack(alignment: .leading, spacing: Theme.Spacing.xxSmall) {
                    Text(title)
                        .font(Theme.Typography.body)
                        .foregroundColor(Theme.Colors.primaryText)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(Theme.Typography.caption1)
                            .foregroundColor(Theme.Colors.secondaryText)
                    }
                }
                
                Spacer()
                
                Icon.view(Icon.System.chevronRight, size: .small, color: Theme.Colors.tertiaryText)
            }
            .padding(Theme.Spacing.medium)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .hoverEffect(highlightColor: Theme.Colors.primary)
    }
}

// MARK: - View Extension for Icons
extension View {
    /// Applies icon button styling
    func iconButton(
        size: Theme.Icons.Size = .regular,
        color: Color = Theme.Colors.primary,
        hoverColor: Color? = nil
    ) -> some View {
        self.buttonStyle(IconButtonStyle(size: size, color: color, hoverColor: hoverColor))
    }
}
