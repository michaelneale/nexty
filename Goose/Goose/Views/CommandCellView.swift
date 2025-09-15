//
//  CommandCellView.swift
//  Goose
//
//  Individual command cell in the list
//

import SwiftUI

struct CommandCellView: View {
    let command: GooseCommand
    let isSelected: Bool
    let onStop: () -> Void
    let onDelete: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 8) {
            // Status indicator
            statusIndicator
                .frame(width: 8, height: 8)
            
            // Command info
            VStack(alignment: .leading, spacing: 4) {
                Text(command.command)
                    .font(.system(.body, design: .monospaced))
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                if !command.arguments.isEmpty {
                    Text(command.arguments.joined(separator: " "))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption2)
                    Text(RelativeDateTimeFormatter().localizedString(for: command.timestamp, relativeTo: Date()))
                        .font(.caption2)
                }
                .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Action buttons (shown on hover or when running)
            if isHovered || command.status == .running {
                HStack(spacing: 4) {
                    if command.status == .running {
                        Button(action: onStop) {
                            Image(systemName: "stop.circle.fill")
                                .foregroundColor(.orange)
                        }
                        .buttonStyle(.plain)
                        .help("Stop Command")
                    }
                    
                    if command.status == .completed || command.status == .failed {
                        Button(action: onDelete) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                        .help("Remove")
                    }
                }
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(backgroundStyle)
        .cornerRadius(6)
        .onHover { hovering in
            isHovered = hovering
        }
    }
    
    private var statusIndicator: some View {
        Circle()
            .fill(statusColor)
            .overlay(
                Circle()
                    .fill(statusColor.opacity(0.3))
                    .scaleEffect(command.status == .running ? 1.5 : 1.0)
                    .animation(
                        command.status == .running ?
                            .easeInOut(duration: 1.0).repeatForever(autoreverses: true) :
                            .default,
                        value: command.status
                    )
            )
    }
    
    private var statusColor: Color {
        switch command.status {
        case .pending:
            return .gray
        case .running:
            return .blue
        case .completed:
            return .green
        case .failed:
            return .red
        case .cancelled:
            return .orange
        }
    }
    
    private var backgroundStyle: some ShapeStyle {
        if isSelected {
            return Color.accentColor.opacity(0.15)
        } else if isHovered {
            return Color.primary.opacity(0.05)
        } else {
            return Color.clear
        }
    }
}

// MARK: - Preview
struct CommandCellView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            CommandCellView(
                command: {
                    var cmd = GooseCommand(command: "session", arguments: ["start"])
                    cmd.status = .running
                    return cmd
                }(),
                isSelected: false,
                onStop: {},
                onDelete: {}
            )
            
            CommandCellView(
                command: {
                    var cmd = GooseCommand(command: "ask", arguments: ["How do I create a SwiftUI view?"])
                    cmd.status = .completed
                    return cmd
                }(),
                isSelected: true,
                onStop: {},
                onDelete: {}
            )
            
            CommandCellView(
                command: {
                    var cmd = GooseCommand(command: "run", arguments: ["build"])
                    cmd.status = .failed
                    return cmd
                }(),
                isSelected: false,
                onStop: {},
                onDelete: {}
            )
        }
        .padding()
        .frame(width: 300)
    }
}
