//
//  CommandOutputView.swift
//  Goose
//
//  View for displaying command output with formatting
//

import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct CommandOutputView: View {
    let command: GooseCommand
    let output: String
    let onStop: () -> Void
    let onCopy: () -> Void
    let onExport: () -> Void
    
    @State private var showingExportSheet = false
    @State private var isAutoScrollEnabled = true
    @State private var searchText = ""
    @State private var fontSize: CGFloat = 12
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
            
            Divider()
            
            // Output area
            outputScrollView
            
            // Status bar
            statusBar
        }
        .background(Color(NSColor.textBackgroundColor))
        .searchable(text: $searchText, placement: .toolbar, prompt: "Search output...")
    }
    
    private var headerView: some View {
        HStack {
            // Command info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    statusIcon
                    Text(command.fullCommand)
                        .font(.system(.title3, design: .monospaced))
                        .fontWeight(.medium)
                }
                
                Text("Started: \(command.timestamp, formatter: dateFormatter)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Actions
            HStack(spacing: 12) {
                if command.status == .running {
                    Button(action: onStop) {
                        Label("Stop", systemImage: "stop.circle.fill")
                            .foregroundColor(.orange)
                    }
                    .buttonStyle(.bordered)
                }
                
                Button(action: onCopy) {
                    Label("Copy", systemImage: "doc.on.doc")
                }
                .buttonStyle(.borderless)
                
                Button(action: { showingExportSheet = true }) {
                    Label("Export", systemImage: "square.and.arrow.up")
                }
                .buttonStyle(.borderless)
                .fileExporter(
                    isPresented: $showingExportSheet,
                    document: TextDocument(text: output),
                    contentType: .plainText,
                    defaultFilename: "goose-output-\(command.id.uuidString).txt"
                ) { result in
                    switch result {
                    case .success(let url):
                        print("Exported to: \(url)")
                    case .failure(let error):
                        print("Export failed: \(error)")
                    }
                }
                
                // Font size controls
                Divider()
                    .frame(height: 20)
                
                Button(action: { fontSize = max(8, fontSize - 1) }) {
                    Image(systemName: "textformat.size.smaller")
                }
                .buttonStyle(.borderless)
                
                Text("\(Int(fontSize))pt")
                    .font(.caption)
                    .monospacedDigit()
                    .frame(width: 35)
                
                Button(action: { fontSize = min(24, fontSize + 1) }) {
                    Image(systemName: "textformat.size.larger")
                }
                .buttonStyle(.borderless)
                
                Divider()
                    .frame(height: 20)
                
                Toggle(isOn: $isAutoScrollEnabled) {
                    Label("Auto-scroll", systemImage: "arrow.down.to.line")
                }
                .toggleStyle(.button)
            }
        }
        .padding()
    }
    
    private var outputScrollView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                FormattedOutputText(
                    text: highlightedOutput,
                    fontSize: fontSize
                )
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .textSelection(.enabled)
                .id("outputBottom")
            }
            .onChange(of: output) { _ in
                if isAutoScrollEnabled && command.status == .running {
                    withAnimation {
                        proxy.scrollTo("outputBottom", anchor: .bottom)
                    }
                }
            }
        }
    }
    
    private var statusBar: some View {
        HStack {
            // Status
            HStack(spacing: 4) {
                statusIcon
                Text(statusText)
                    .font(.caption)
            }
            
            Divider()
                .frame(height: 16)
            
            // Line count
            Label("\(lineCount) lines", systemImage: "number")
                .font(.caption)
            
            Divider()
                .frame(height: 16)
            
            // Character count
            Label("\(output.count) characters", systemImage: "textformat.characters")
                .font(.caption)
            
            Spacer()
            
            // Search matches
            if !searchText.isEmpty {
                let matches = countMatches(of: searchText, in: output)
                Label("\(matches) matches", systemImage: "magnifyingglass")
                    .font(.caption)
                    .foregroundColor(matches > 0 ? .accentColor : .secondary)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 6)
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    private var statusIcon: some View {
        Group {
            switch command.status {
            case .pending:
                Image(systemName: "clock")
                    .foregroundColor(.gray)
            case .running:
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(0.7)
            case .completed:
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            case .failed:
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red)
            case .cancelled:
                Image(systemName: "stop.circle.fill")
                    .foregroundColor(.orange)
            }
        }
    }
    
    private var statusText: String {
        switch command.status {
        case .pending:
            return "Pending"
        case .running:
            return "Running..."
        case .completed:
            return "Completed"
        case .failed:
            return "Failed"
        case .cancelled:
            return "Cancelled"
        }
    }
    
    private var lineCount: Int {
        output.components(separatedBy: .newlines).count
    }
    
    private var highlightedOutput: AttributedString {
        var attributedString = AttributedString(output)
        
        // Highlight search text
        if !searchText.isEmpty {
            let searchRange = output.ranges(of: searchText, options: .caseInsensitive)
            for range in searchRange {
                if let attributedRange = Range(range, in: attributedString) {
                    attributedString[attributedRange].backgroundColor = .yellow.opacity(0.3)
                }
            }
        }
        
        return attributedString
    }
    
    private func countMatches(of searchString: String, in text: String) -> Int {
        guard !searchString.isEmpty else { return 0 }
        return text.ranges(of: searchString, options: .caseInsensitive).count
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        return formatter
    }
}

// MARK: - Formatted Output Text View
struct FormattedOutputText: View {
    let text: AttributedString
    let fontSize: CGFloat
    
    var body: some View {
        Text(text)
            .font(.system(size: fontSize, design: .monospaced))
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Text Document for Export
struct TextDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.plainText] }
    
    var text: String
    
    init(text: String) {
        self.text = text
    }
    
    init(configuration: ReadConfiguration) throws {
        if let data = configuration.file.regularFileContents {
            text = String(decoding: data, as: UTF8.self)
        } else {
            text = ""
        }
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = text.data(using: .utf8) ?? Data()
        return FileWrapper(regularFileWithContents: data)
    }
}

// MARK: - String Extension for Range Finding
extension String {
    func ranges(of substring: String, options: String.CompareOptions = []) -> [Range<String.Index>] {
        var ranges: [Range<String.Index>] = []
        var searchStartIndex = self.startIndex
        
        while searchStartIndex < self.endIndex,
              let range = self.range(of: substring, options: options, range: searchStartIndex..<self.endIndex) {
            ranges.append(range)
            searchStartIndex = range.upperBound
        }
        
        return ranges
    }
}

// MARK: - Preview
struct CommandOutputView_Previews: PreviewProvider {
    static var previews: some View {
        CommandOutputView(
            command: {
                var cmd = GooseCommand(command: "session", arguments: ["start"])
                cmd.status = .running
                return cmd
            }(),
            output: """
            Starting Goose session...
            Initializing AI assistant...
            Ready for commands.
            
            > User: How do I create a SwiftUI view?
            
            Assistant: To create a SwiftUI view, you can start with a struct that conforms to the View protocol:
            
            ```swift
            struct MyView: View {
                var body: some View {
                    Text("Hello, World!")
                }
            }
            ```
            
            This is the basic structure for any SwiftUI view.
            """,
            onStop: {},
            onCopy: {},
            onExport: {}
        )
    }
}
