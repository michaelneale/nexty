//
//  ViewModifiers.swift
//  Goose
//
//  Created on 2024-09-15
//  Reusable view modifiers for consistent styling
//

import SwiftUI

// MARK: - Card Style
/// A view modifier that applies a card-like appearance with background, padding, corner radius, and shadow
struct CardStyle: ViewModifier {
    var cornerRadius: CGFloat = Theme.CornerRadius.medium
    var padding: CGFloat = Theme.Spacing.medium
    var shadow: ShadowStyle = Theme.Shadows.small
    var backgroundColor: Color = Theme.Colors.secondaryBackground
    
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(backgroundColor)
            .cornerRadius(cornerRadius)
            .shadow(color: shadow.color, radius: shadow.radius, x: shadow.x, y: shadow.y)
    }
}

// MARK: - Hover Effect
/// Adds a hover effect that scales content when mouse hovers over it
struct HoverEffect: ViewModifier {
    @State private var isHovered = false
    var scaleAmount: CGFloat = 1.02
    var highlightColor: Color? = nil
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isHovered ? scaleAmount : 1.0)
            .background(
                highlightColor != nil && isHovered 
                    ? highlightColor!.opacity(Theme.Opacity.verySubtle)
                    : Color.clear
            )
            .animation(Theme.Animation.appropriate(Theme.Animation.quick), value: isHovered)
            .onHover { hovering in
                isHovered = hovering
            }
    }
}

// MARK: - Pressed Effect
/// Applies a pressed/active state visual effect
struct PressedEffect: ViewModifier {
    var isPressed: Bool
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .opacity(isPressed ? 0.9 : 1.0)
            .animation(Theme.Animation.appropriate(Theme.Animation.quick), value: isPressed)
    }
}

// MARK: - Focus Ring
/// Adds a focus ring around the content when it receives keyboard focus
struct FocusRing: ViewModifier {
    @FocusState private var isFocused: Bool
    var color: Color = Theme.Colors.focus
    var cornerRadius: CGFloat = Theme.CornerRadius.small
    
    func body(content: Content) -> some View {
        content
            .focused($isFocused)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(isFocused ? color : Color.clear, lineWidth: Theme.Borders.focusRing)
                    .animation(Theme.Animation.appropriate(Theme.Animation.quick), value: isFocused)
            )
    }
}

// MARK: - Loading Overlay
/// Shows a loading overlay with progress indicator and optional message
struct LoadingOverlay: ViewModifier {
    var isLoading: Bool
    var message: String = "Loading..."
    
    func body(content: Content) -> some View {
        ZStack {
            content
                .disabled(isLoading)
                .blur(radius: isLoading ? Theme.BlurEffects.subtle : 0)
            
            if isLoading {
                VStack(spacing: Theme.Spacing.medium) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(1.2)
                    
                    Text(message)
                        .font(Theme.Typography.caption1)
                        .foregroundColor(Theme.Colors.secondaryText)
                }
                .padding(Theme.Spacing.xLarge)
                .background(Theme.Colors.background.opacity(0.95))
                .cornerRadius(Theme.CornerRadius.large)
                .shadow(color: Theme.Shadows.large.color, radius: Theme.Shadows.large.radius)
                .transition(.asymmetric(
                    insertion: .scale.combined(with: .opacity),
                    removal: .scale.combined(with: .opacity)
                ))
            }
        }
        .animation(Theme.Animation.appropriate(Theme.Animation.spring), value: isLoading)
    }
}

// MARK: - Shake Effect
/// Adds a horizontal shake animation effect
struct ShakeEffect: GeometryEffect {
    var amount: CGFloat = 10
    var shakesPerUnit = 3
    var animatableData: CGFloat
    
    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX:
            amount * sin(animatableData * .pi * CGFloat(shakesPerUnit)),
            y: 0))
    }
}

// MARK: - Empty State
/// Shows an empty state view when content is empty
struct EmptyStateModifier: ViewModifier {
    var isEmpty: Bool
    var title: String
    var message: String
    var systemImage: String
    
    func body(content: Content) -> some View {
        ZStack {
            content
                .opacity(isEmpty ? 0 : 1)
            
            if isEmpty {
                VStack(spacing: Theme.Spacing.large) {
                    Image(systemName: systemImage)
                        .font(.system(size: 48))
                        .foregroundColor(Theme.Colors.tertiaryText)
                    
                    VStack(spacing: Theme.Spacing.small) {
                        Text(title)
                            .font(Theme.Typography.title3)
                            .foregroundColor(Theme.Colors.primaryText)
                        
                        Text(message)
                            .font(Theme.Typography.body)
                            .foregroundColor(Theme.Colors.secondaryText)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(Theme.Spacing.xxLarge)
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.9).combined(with: .opacity),
                    removal: .scale(scale: 1.1).combined(with: .opacity)
                ))
            }
        }
        .animation(Theme.Animation.appropriate(Theme.Animation.smooth), value: isEmpty)
    }
}

// MARK: - Accessibility Label
/// Adds accessibility labels and hints to make content more accessible
struct AccessibilityLabel: ViewModifier {
    var label: String
    var hint: String?
    var traits: AccessibilityTraits = []
    
    func body(content: Content) -> some View {
        content
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
            .accessibilityAddTraits(traits)
    }
}

// MARK: - Material Background
/// Applies a macOS-style material background effect
struct MaterialBackground: ViewModifier {
    var material: NSVisualEffectView.Material = .contentBackground
    var blendingMode: NSVisualEffectView.BlendingMode = .behindWindow
    var cornerRadius: CGFloat = Theme.CornerRadius.medium
    
    func body(content: Content) -> some View {
        content
            .background(
                VisualEffectBackground(
                    material: material,
                    blendingMode: blendingMode
                )
            )
            .cornerRadius(cornerRadius)
    }
}

// MARK: - Visual Effect Background
/// Helper view for creating macOS visual effect backgrounds
struct VisualEffectBackground: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}

// MARK: - Glow Effect
/// Adds a glow effect around the content
struct GlowEffect: ViewModifier {
    var color: Color = Theme.Colors.primary
    var radius: CGFloat = 10
    var isActive: Bool = true
    
    func body(content: Content) -> some View {
        content
            .shadow(color: isActive ? color.opacity(0.6) : Color.clear, radius: radius)
            .shadow(color: isActive ? color.opacity(0.3) : Color.clear, radius: radius * 2)
            .animation(Theme.Animation.appropriate(Theme.Animation.smooth), value: isActive)
    }
}

// MARK: - Disabled State
/// Applies a disabled visual state to content
struct DisabledState: ViewModifier {
    var isDisabled: Bool
    
    func body(content: Content) -> some View {
        content
            .opacity(isDisabled ? Theme.Opacity.disabled : 1.0)
            .allowsHitTesting(!isDisabled)
            .animation(Theme.Animation.appropriate(Theme.Animation.quick), value: isDisabled)
    }
}

// MARK: - Terminal Style
/// Applies terminal/code styling to text content
struct TerminalStyle: ViewModifier {
    var backgroundColor: Color = Theme.Colors.terminalBackground
    var textColor: Color = Theme.Colors.terminalText
    
    func body(content: Content) -> some View {
        content
            .font(Theme.Typography.code)
            .foregroundColor(textColor)
            .padding(Theme.Spacing.small)
            .background(backgroundColor)
            .cornerRadius(Theme.CornerRadius.small)
    }
}

// MARK: - Badge Style
/// Creates a badge-like appearance for labels and indicators
struct BadgeStyle: ViewModifier {
    var color: Color = Theme.Colors.primary
    var isProminant: Bool = false
    
    func body(content: Content) -> some View {
        content
            .font(Theme.Typography.caption1)
            .foregroundColor(isProminant ? .white : color)
            .padding(.horizontal, Theme.Spacing.small)
            .padding(.vertical, Theme.Spacing.xxSmall)
            .background(
                isProminant ? color : color.opacity(Theme.Opacity.verySubtle)
            )
            .cornerRadius(Theme.CornerRadius.full)
    }
}

// MARK: - Glass Morphism
/// Applies a glass morphism effect with blur and transparency
struct GlassMorphism: ViewModifier {
    var cornerRadius: CGFloat = Theme.CornerRadius.large
    var shadowRadius: CGFloat = Theme.Shadows.medium.radius
    
    func body(content: Content) -> some View {
        content
            .background(
                Theme.Colors.background
                    .opacity(Theme.Opacity.strong)
                    .blur(radius: Theme.BlurEffects.material)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Theme.Colors.border.opacity(Theme.Opacity.light), lineWidth: Theme.Borders.thin)
            )
            .cornerRadius(cornerRadius)
            .shadow(
                color: Theme.Shadows.medium.color,
                radius: shadowRadius,
                x: 0,
                y: 2
            )
    }
}

// MARK: - Pulsating Effect
/// Adds a pulsating animation effect
struct PulsatingEffect: ViewModifier {
    @State private var isPulsating = false
    var minScale: CGFloat = 0.95
    var maxScale: CGFloat = 1.05
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isPulsating ? maxScale : minScale)
            .onAppear {
                withAnimation(
                    Theme.Animation.appropriate(
                        .easeInOut(duration: 1.0).repeatForever(autoreverses: true)
                    )
                ) {
                    isPulsating = true
                }
            }
    }
}

// MARK: - View Extensions
extension View {
    /// Applies card styling with customizable options
    func cardStyle(
        cornerRadius: CGFloat = Theme.CornerRadius.medium,
        padding: CGFloat = Theme.Spacing.medium,
        shadow: ShadowStyle = Theme.Shadows.small,
        backgroundColor: Color = Theme.Colors.secondaryBackground
    ) -> some View {
        modifier(CardStyle(
            cornerRadius: cornerRadius,
            padding: padding,
            shadow: shadow,
            backgroundColor: backgroundColor
        ))
    }
    
    /// Adds hover effect with optional highlight color
    func hoverEffect(scaleAmount: CGFloat = 1.02, highlightColor: Color? = nil) -> some View {
        modifier(HoverEffect(scaleAmount: scaleAmount, highlightColor: highlightColor))
    }
    
    /// Applies pressed state effect
    func pressedEffect(isPressed: Bool) -> some View {
        modifier(PressedEffect(isPressed: isPressed))
    }
    
    /// Adds focus ring with customizable color
    func focusRing(color: Color = Theme.Colors.focus, cornerRadius: CGFloat = Theme.CornerRadius.small) -> some View {
        modifier(FocusRing(color: color, cornerRadius: cornerRadius))
    }
    
    /// Shows loading overlay
    func loadingOverlay(isLoading: Bool, message: String = "Loading...") -> some View {
        modifier(LoadingOverlay(isLoading: isLoading, message: message))
    }
    
    /// Adds shake animation
    func shake(animatableData: CGFloat) -> some View {
        modifier(ShakeEffect(animatableData: animatableData))
    }
    
    /// Shows empty state when content is empty
    func emptyState(isEmpty: Bool, title: String, message: String, systemImage: String) -> some View {
        modifier(EmptyStateModifier(
            isEmpty: isEmpty,
            title: title,
            message: message,
            systemImage: systemImage
        ))
    }
    
    /// Adds accessibility labels and hints
    func accessibilitySetup(label: String, hint: String? = nil, traits: AccessibilityTraits = []) -> some View {
        modifier(AccessibilityLabel(label: label, hint: hint, traits: traits))
    }
    
    /// Applies material background effect
    func materialBackground(
        material: NSVisualEffectView.Material = .contentBackground,
        blendingMode: NSVisualEffectView.BlendingMode = .behindWindow,
        cornerRadius: CGFloat = Theme.CornerRadius.medium
    ) -> some View {
        modifier(MaterialBackground(
            material: material,
            blendingMode: blendingMode,
            cornerRadius: cornerRadius
        ))
    }
    
    /// Adds glow effect
    func glow(color: Color = Theme.Colors.primary, radius: CGFloat = 10, isActive: Bool = true) -> some View {
        modifier(GlowEffect(color: color, radius: radius, isActive: isActive))
    }
    
    /// Applies disabled state
    func disabledState(_ isDisabled: Bool) -> some View {
        modifier(DisabledState(isDisabled: isDisabled))
    }
    
    /// Applies terminal/code styling
    func terminalStyle(
        backgroundColor: Color = Theme.Colors.terminalBackground,
        textColor: Color = Theme.Colors.terminalText
    ) -> some View {
        modifier(TerminalStyle(backgroundColor: backgroundColor, textColor: textColor))
    }
    
    /// Applies badge styling
    func badge(color: Color = Theme.Colors.primary, isProminant: Bool = false) -> some View {
        modifier(BadgeStyle(color: color, isProminant: isProminant))
    }
    
    /// Applies glass morphism effect
    func glassMorphism(
        cornerRadius: CGFloat = Theme.CornerRadius.large,
        shadowRadius: CGFloat = Theme.Shadows.medium.radius
    ) -> some View {
        modifier(GlassMorphism(cornerRadius: cornerRadius, shadowRadius: shadowRadius))
    }
    
    /// Adds pulsating animation
    func pulsating(minScale: CGFloat = 0.95, maxScale: CGFloat = 1.05) -> some View {
        modifier(PulsatingEffect(minScale: minScale, maxScale: maxScale))
    }
}
