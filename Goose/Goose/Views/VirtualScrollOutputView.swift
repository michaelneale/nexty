//
//  VirtualScrollOutputView.swift
//  Goose
//
//  High-performance virtual scrolling view for large command outputs
//

import SwiftUI
import AppKit

/// Virtual scrolling view that efficiently handles large outputs
struct VirtualScrollOutputView: NSViewRepresentable {
    @ObservedObject var bufferManager: OutputBufferManager
    let fontSize: CGFloat
    let searchText: String
    let isAutoScrollEnabled: Bool
    
    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        let textView = VirtualTextView()
        
        // Configure scroll view
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = false
        scrollView.borderType = .noBorder
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        
        // Configure text view
        textView.isEditable = false
        textView.isSelectable = true
        textView.isRichText = true
        textView.importsGraphics = false
        textView.allowsUndo = false
        textView.drawsBackground = true
        textView.backgroundColor = NSColor.textBackgroundColor
        textView.textColor = NSColor.labelColor
        textView.font = NSFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
        
        // Set up text container
        textView.textContainer?.containerSize = CGSize(width: scrollView.frame.width, height: CGFloat.greatestFiniteMagnitude)
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.lineFragmentPadding = 10
        
        // Set document view
        scrollView.documentView = textView
        
        // Store references in coordinator
        context.coordinator.scrollView = scrollView
        context.coordinator.textView = textView
        context.coordinator.bufferManager = bufferManager
        
        return scrollView
    }
    
    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? VirtualTextView else { return }
        
        // Update font size
        textView.font = NSFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
        
        // Update content efficiently
        context.coordinator.updateContent(searchText: searchText)
        
        // Auto-scroll if enabled
        if isAutoScrollEnabled && bufferManager.isStreaming {
            DispatchQueue.main.async {
                scrollView.documentView?.scroll(NSPoint(x: 0, y: textView.frame.height))
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(bufferManager: bufferManager)
    }
    
    class Coordinator: NSObject {
        weak var scrollView: NSScrollView?
        weak var textView: VirtualTextView?
        var bufferManager: OutputBufferManager
        private var lastUpdateTime = Date()
        private let updateThrottle: TimeInterval = 0.016 // ~60fps
        
        init(bufferManager: OutputBufferManager) {
            self.bufferManager = bufferManager
            super.init()
        }
        
        func updateContent(searchText: String) {
            guard let textView = textView else { return }
            
            // Throttle updates for performance
            let now = Date()
            
            // Check if we should throttle (only during streaming)
            Task { @MainActor in
                if now.timeIntervalSince(lastUpdateTime) < updateThrottle && bufferManager.isStreaming {
                    return
                }
            }
            
            lastUpdateTime = now
            
            // Get visible range
            guard let scrollView = scrollView else { return }
            let visibleRect = scrollView.contentView.visibleRect
            let textContainer = textView.textContainer!
            let glyphRange = textView.layoutManager!.glyphRange(forBoundingRect: visibleRect, in: textContainer)
            let characterRange = textView.layoutManager!.characterRange(forGlyphRange: glyphRange, actualGlyphRange: nil)
            
            // Calculate line range to fetch
            let text = textView.string as NSString
            var lineStart = 0
            var lineEnd = 0
            text.getLineStart(&lineStart, end: &lineEnd, contentsEnd: nil, for: characterRange)
            
            // Add buffer for smoother scrolling (fetch extra lines above and below)
            let bufferLines = 50
            let startLine = max(0, getLineNumber(for: lineStart, in: textView.string) - bufferLines)
            let endLine = min(bufferManager.lineCount, getLineNumber(for: lineEnd, in: textView.string) + bufferLines)
            
            // Fetch and update only the visible portion
            Task { @MainActor in
                let lines = await bufferManager.getLines(from: startLine, to: endLine)
                let content = lines.joined(separator: "\n")
                
                // Apply syntax highlighting and search highlighting
                let attributedString = NSMutableAttributedString(string: content)
                
                // Apply monospace font
                attributedString.addAttribute(.font, 
                                            value: textView.font ?? NSFont.monospacedSystemFont(ofSize: 12, weight: .regular),
                                            range: NSRange(location: 0, length: content.count))
                
                // Highlight search results
                if !searchText.isEmpty {
                    highlightSearchResults(in: attributedString, searchText: searchText)
                }
                
                // Update text view if content changed
                if textView.attributedString() != attributedString {
                    textView.textStorage?.setAttributedString(attributedString)
                }
            }
        }
        
        private func getLineNumber(for characterIndex: Int, in text: String) -> Int {
            let substring = String(text.prefix(characterIndex))
            return substring.components(separatedBy: .newlines).count - 1
        }
        
        private func highlightSearchResults(in attributedString: NSMutableAttributedString, searchText: String) {
            let text = attributedString.string
            let searchOptions: NSString.CompareOptions = [.caseInsensitive]
            
            var searchRange = NSRange(location: 0, length: text.count)
            while searchRange.location < text.count {
                let foundRange = (text as NSString).range(of: searchText, options: searchOptions, range: searchRange)
                if foundRange.location != NSNotFound {
                    attributedString.addAttribute(.backgroundColor, 
                                                 value: NSColor.yellow.withAlphaComponent(0.3),
                                                 range: foundRange)
                    searchRange = NSRange(location: foundRange.location + foundRange.length,
                                        length: text.count - (foundRange.location + foundRange.length))
                } else {
                    break
                }
            }
        }
    }
}

/// Custom NSTextView optimized for virtual scrolling
class VirtualTextView: NSTextView {
    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        // Allow standard keyboard shortcuts
        if event.modifierFlags.contains(.command) {
            switch event.charactersIgnoringModifiers {
            case "c": // Copy
                let selectedRange = self.selectedRange()
                if selectedRange.length > 0 {
                    self.copy(nil)
                    return true
                }
            case "a": // Select All
                self.selectAll(nil)
                return true
            default:
                break
            }
        }
        return super.performKeyEquivalent(with: event)
    }
    
    override func draw(_ dirtyRect: NSRect) {
        // Optimize drawing for performance
        NSGraphicsContext.current?.shouldAntialias = false
        super.draw(dirtyRect)
        NSGraphicsContext.current?.shouldAntialias = true
    }
}
