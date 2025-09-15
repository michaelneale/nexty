//
//  ViewModifiers.swift
//  Goose
//
//  Created on 2024-09-15
//  Reusable view modifiers for consistent styling
//

import SwiftUI

// MARK: - Card Style
struct CardStyle: ViewModifier {
    var cornerRadius: CGFloat = Theme.CornerRadius.medium
    var padding: CGFloat = Theme.Spacing.medium
    var shadow: ShadowStyle = Theme.Shadows.small
    
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(Theme.Colors.secondaryBackground)
            .cornerRadius(cornerRadius)
            .shadow(color: shadow.color, radius: shadow.radius, x: shadow.x, y: shadow.y)
    }
}

// MARK: - Hover Effect
struct HoverEffect: ViewModifier {
    @State private var isHovered = false
    var scaleAmount: CGFloat = 1.02
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isHovered ? scaleAmount : 1.0)
            .animation(Theme.Animation.quick, value: isHovered)
            .onHover { hovering in
                isHovered = hovering
            }
    }
}

// MARK: - Pressed Effect
struct PressedEffect: ViewModifier {
    var isPressed: Bool
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .opacity(isPressed ? 0.9 : 1.0)
            .animation(Theme.Animation.quick, value: isPressed)
    }
}

// MARK: - Focus Ring
struct FocusRing: ViewModifier {
    @FocusState private var isFocused: Bool
    var color: Color = Theme.Colors.primary
    
    func body(content: Content) -> some View {
        content
            .focused($isFocused)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.small)
                    .stroke(isFocused ? color : Color.clear, lineWidth: 2)
                    .animation(Theme.Animation.quick, value: isFocused)
            )
    }
}

// MARK: - Loading Overlay
struct LoadingOverlay: ViewModifier {
    var isLoading: Bool
    var message: String = "Loading..."
    
    func body(content: Content) -> some View {
        ZStack {
            content
                .disabled(isLoading)
                .blur(radius: isLoading ? 2 : 0)
            
            if isLoading {
                VStack(spacing: Theme.Spacing.medium) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(1.2)
                    
                    Text(message)
                        .font(Theme.Typography.caption)
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
        .animation(Theme.Animation.spring, value: isLoading)
    }
}

// MARK: - Shake Effect
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
                        .foregroundColor(Theme.Colors.secondaryText.opacity(0.5))
                    
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
        .animation(Theme.Animation.smooth, value: isEmpty)
    }
}

// MARK: - Accessibility Label
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

// MARK: - View Extensions
extension View {
    func cardStyle(cornerRadius: CGFloat = Theme.CornerRadius.medium,
                   padding: CGFloat = Theme.Spacing.medium,
                   shadow: ShadowStyle = Theme.Shadows.small) -> some View {
        modifier(CardStyle(cornerRadius: cornerRadius, padding: padding, shadow: shadow))
    }
    
    func hoverEffect(scaleAmount: CGFloat = 1.02) -> some View {
        modifier(HoverEffect(scaleAmount: scaleAmount))
    }
    
    func pressedEffect(isPressed: Bool) -> some View {
        modifier(PressedEffect(isPressed: isPressed))
    }
    
    func focusRing(color: Color = Theme.Colors.primary) -> some View {
        modifier(FocusRing(color: color))
    }
    
    func loadingOverlay(isLoading: Bool, message: String = "Loading...") -> some View {
        modifier(LoadingOverlay(isLoading: isLoading, message: message))
    }
    
    func shake(animatableData: CGFloat) -> some View {
        modifier(ShakeEffect(animatableData: animatableData))
    }
    
    func emptyState(isEmpty: Bool, title: String, message: String, systemImage: String) -> some View {
        modifier(EmptyStateModifier(isEmpty: isEmpty, title: title, message: message, systemImage: systemImage))
    }
    
    func accessibilitySetup(label: String, hint: String? = nil, traits: AccessibilityTraits = []) -> some View {
        modifier(AccessibilityLabel(label: label, hint: hint, traits: traits))
    }
}
