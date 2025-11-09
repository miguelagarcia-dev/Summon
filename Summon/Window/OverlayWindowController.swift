//
//  OverlayWindowController.swift
//  Summon
//
//  Created by Miguel Garcia on 11/8/25.
//

import AppKit
import MetalKit

class OverlayWindowController: NSWindowController {
    
    var renderer: ModelRenderer? {
        return (window?.contentView as? MetalView)?.renderer
    }
    
    convenience init() {
        // Window size to fit the model
        let windowWidth: CGFloat = 300
        let windowHeight: CGFloat = 400
        
        // Position at bottom-right corner of screen
        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let xPos = screenFrame.maxX - windowWidth - 20  // 20pt margin from right
            let yPos = screenFrame.minY + 20  // 20pt margin from bottom
            
            // Create transparent, borderless window
            let window = NSWindow(
                contentRect: NSRect(x: xPos, y: yPos, width: windowWidth, height: windowHeight),
                styleMask: [.borderless, .fullSizeContentView],
                backing: .buffered,
                defer: false
            )
            
            // Critical transparency settings
            window.isOpaque = false
            window.backgroundColor = .clear
            window.level = .floating              // Always on top
            window.collectionBehavior = [
                .canJoinAllSpaces,                // Visible on all desktops
                .stationary,                       // Doesn't move between spaces
                .fullScreenAuxiliary               // Works in fullscreen mode
            ]
            window.hasShadow = true               // Subtle depth
            window.isMovableByWindowBackground = true
            
            // Create Metal view with explicit frame
            let metalView = MetalView(frame: NSRect(x: 0, y: 0, width: windowWidth, height: windowHeight))
            metalView.autoresizingMask = [.width, .height]
            window.contentView = metalView
            
            self.init(window: window)
        } else {
            // Fallback if no screen available
            let window = NSWindow(
                contentRect: NSRect(x: 100, y: 100, width: windowWidth, height: windowHeight),
                styleMask: [.borderless, .fullSizeContentView],
                backing: .buffered,
                defer: false
            )
            
            window.isOpaque = false
            window.backgroundColor = .clear
            window.level = .floating
            window.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]
            window.hasShadow = true
            window.isMovableByWindowBackground = true
            
            let metalView = MetalView(frame: NSRect(x: 0, y: 0, width: windowWidth, height: windowHeight))
            metalView.autoresizingMask = [.width, .height]
            window.contentView = metalView
            
            self.init(window: window)
        }
    }
}

