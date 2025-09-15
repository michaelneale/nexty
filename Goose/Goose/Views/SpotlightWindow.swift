//
//  SpotlightWindow.swift
//  Goose
//
//  Created on 2024-09-15
//

import Cocoa
import SwiftUI

/// Custom NSPanel subclass for the Spotlight-like popup window
class SpotlightWindow: NSPanel {
    
    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 680, height: 60),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        setupWindow()
    }
    
    private func setupWindow() {
        // Window configuration
        isFloatingPanel = true
        level = .floating
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        isMovableByWindowBackground = false
        backgroundColor = .clear
        hasShadow = true
        
        // Make window non-opaque for transparency
        isOpaque = false
        
        // Hide window from dock and app switcher
        hidesOnDeactivate = false
        
        // Animation behavior
        animationBehavior = .default
    }
    
    override var canBecomeKey: Bool {
        return true
    }
    
    override var canBecomeMain: Bool {
        return true
    }
    
    /// Center the window on the screen
    func centerOnScreen() {
        guard let screen = NSScreen.main else { return }
        
        let screenFrame = screen.visibleFrame
        let windowFrame = frame
        
        let x = (screenFrame.width - windowFrame.width) / 2 + screenFrame.origin.x
        let y = (screenFrame.height - windowFrame.height) * 0.75 + screenFrame.origin.y // Position slightly above center
        
        setFrameOrigin(NSPoint(x: x, y: y))
    }
    
    /// Show the window with animation
    func showWindow(completion: (() -> Void)? = nil) {
        centerOnScreen()
        
        // Set initial alpha for fade-in animation
        alphaValue = 0
        
        makeKeyAndOrderFront(nil)
        
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.25
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            animator().alphaValue = 1.0
        }, completionHandler: {
            completion?()
        })
    }
    
    /// Hide the window with animation
    func hideWindow(completion: (() -> Void)? = nil) {
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.2
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            animator().alphaValue = 0.0
        }, completionHandler: {
            self.orderOut(nil)
            completion?()
        })
    }
    
    override func resignKey() {
        super.resignKey()
        // Hide window when it loses key status (clicked outside)
        hideWindow()
    }
}
