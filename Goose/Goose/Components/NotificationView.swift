//
//  NotificationView.swift
//  Goose
//
//  Created on 2024-09-15
//  User-friendly notification and alert system
//

import SwiftUI

// MARK: - Notification Type
enum NotificationType {
    case success
    case warning
    case error
    case info
    
    var color: Color {
        switch self {
        case .success: return Theme.Colors.success
        case .warning: return Theme.Colors.warning
        case .error: return Theme.Colors.error
        case .info: return Theme.Colors.info
        }
    }
    
    var icon: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .error: return "xmark.circle.fill"
        case .info: return "info.circle.fill"
        }
    }
}

// MARK: - Notification Model
struct NotificationItem: Identifiable, Equatable {
    let id = UUID()
    let type: NotificationType
    let title: String
    let message: String?
    let duration: TimeInterval
    
    init(type: NotificationType, title: String, message: String? = nil, duration: TimeInterval = 3.0) {
        self.type = type
        self.title = title
        self.message = message
        self.duration = duration
    }
}

// MARK: - Notification View
struct NotificationView: View {
    let notification: NotificationItem
    let onDismiss: () -> Void
    
    @State private var isShowing = false
    @State private var isDragging = false
    @State private var dragOffset: CGSize = .zero
    
    var body: some View {
        HStack(spacing: Theme.Spacing.medium) {
            Image(systemName: notification.type.icon)
                .font(.title3)
                .foregroundColor(notification.type.color)
                .accessibilityHidden(true)
            
            VStack(alignment: .leading, spacing: Theme.Spacing.xSmall) {
                Text(notification.title)
                    .font(Theme.Typography.bodyMedium)
                    .foregroundColor(Theme.Colors.primaryText)
                
                if let message = notification.message {
                    Text(message)
                        .font(Theme.Typography.caption)
                        .foregroundColor(Theme.Colors.secondaryText)
                        .lineLimit(2)
                }
            }
            
            Spacer()
            
            Button(action: dismiss) {
                Image(systemName: "xmark")
                    .font(.caption)
                    .foregroundColor(Theme.Colors.secondaryText)
            }
            .buttonStyle(.plain)
            .hoverEffect(scaleAmount: 1.1)
            .accessibilityLabel("Dismiss notification")
        }
        .padding(Theme.Spacing.medium)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                .fill(Theme.Colors.background)
                .shadow(color: Theme.Shadows.large.color, radius: Theme.Shadows.large.radius)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                .stroke(notification.type.color.opacity(0.3), lineWidth: 1)
        )
        .offset(x: dragOffset.width, y: 0)
        .opacity(isShowing ? 1 : 0)
        .scaleEffect(isShowing ? 1 : 0.8)
        .animation(Theme.Animation.spring, value: isShowing)
        .animation(Theme.Animation.quick, value: dragOffset)
        .gesture(
            DragGesture()
                .onChanged { value in
                    isDragging = true
                    dragOffset = value.translation
                }
                .onEnded { value in
                    if abs(value.translation.width) > 100 {
                        dismiss()
                    } else {
                        withAnimation(Theme.Animation.spring) {
                            dragOffset = .zero
                        }
                    }
                    isDragging = false
                }
        )
        .onAppear {
            withAnimation {
                isShowing = true
            }
            
            if !isDragging {
                DispatchQueue.main.asyncAfter(deadline: .now() + notification.duration) {
                    if !isDragging {
                        dismiss()
                    }
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(notification.type) notification: \(notification.title). \(notification.message ?? "")")
        .accessibilityAction(named: "Dismiss") {
            dismiss()
        }
    }
    
    private func dismiss() {
        withAnimation(Theme.Animation.quick) {
            isShowing = false
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            onDismiss()
        }
    }
}

// MARK: - Notification Manager
class NotificationManager: ObservableObject {
    @Published var notifications: [NotificationItem] = []
    
    func show(_ notification: NotificationItem) {
        withAnimation(Theme.Animation.spring) {
            notifications.append(notification)
        }
    }
    
    func show(type: NotificationType, title: String, message: String? = nil, duration: TimeInterval = 3.0) {
        let notification = NotificationItem(type: type, title: title, message: message, duration: duration)
        show(notification)
    }
    
    func dismiss(_ notification: NotificationItem) {
        withAnimation(Theme.Animation.quick) {
            notifications.removeAll { $0.id == notification.id }
        }
    }
    
    func dismissAll() {
        withAnimation(Theme.Animation.quick) {
            notifications.removeAll()
        }
    }
}

// MARK: - Notification Container View
struct NotificationContainer: View {
    @StateObject private var manager = NotificationManager()
    
    var body: some View {
        VStack(spacing: Theme.Spacing.small) {
            ForEach(manager.notifications) { notification in
                NotificationView(notification: notification) {
                    manager.dismiss(notification)
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity),
                    removal: .move(edge: .trailing).combined(with: .opacity)
                ))
            }
        }
        .padding(Theme.Spacing.large)
        .frame(maxWidth: 400)
        .environmentObject(manager)
    }
}

// MARK: - View Extension for Notifications
extension View {
    func withNotifications() -> some View {
        ZStack(alignment: .topTrailing) {
            self
            NotificationContainer()
        }
    }
}
