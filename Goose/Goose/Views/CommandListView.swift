//
//  CommandListView.swift
//  Goose
//
//  Sidebar view showing list of commands
//

import SwiftUI

struct CommandListView: View {
    let commands: [GooseCommand]
    @Binding var selectedCommand: GooseCommand?
    let onStopCommand: (GooseCommand) -> Void
    let onDeleteCommand: (GooseCommand) -> Void
    
    var body: some View {
        List(selection: $selectedCommand) {
            if commands.isEmpty {
                if #available(macOS 14.0, *) {
                    ContentUnavailableView(
                        "No Commands",
                        systemImage: "terminal",
                        description: Text("Commands will appear here when executed")
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .listRowSeparator(.hidden)
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "terminal")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text("No Commands")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text("Commands will appear here when executed")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .listRowSeparator(.hidden)
                }
            } else {
                ForEach(commands) { command in
                    CommandCellView(
                        command: command,
                        isSelected: selectedCommand?.id == command.id,
                        onStop: { onStopCommand(command) },
                        onDelete: { onDeleteCommand(command) }
                    )
                    .tag(command)
                    .listRowInsets(EdgeInsets(top: 2, leading: 8, bottom: 2, trailing: 8))
                }
            }
        }
        .listStyle(.sidebar)
        .frame(minWidth: 280)
    }
}

// MARK: - Preview
struct CommandListView_Previews: PreviewProvider {
    @State static var selectedCommand: GooseCommand? = nil
    
    static var previews: some View {
        CommandListView(
            commands: [
                GooseCommand(command: "session", arguments: ["start"]),
                GooseCommand(command: "ask", arguments: ["How do I create a SwiftUI view?"]),
            ],
            selectedCommand: $selectedCommand,
            onStopCommand: { _ in },
            onDeleteCommand: { _ in }
        )
    }
}
