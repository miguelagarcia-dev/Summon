//
//  WindowContextManager.swift
//  Summon
//
//  Track active window and application
//

import AppKit
import ApplicationServices

struct WindowContext {
    let appName: String
    let appBundleID: String
    let windowTitle: String?
    let timestamp: Date
}

class WindowContextManager {
    private var lastContext: WindowContext?
    
    // Get current window context
    func getCurrentContext() -> WindowContext? {
        // Get frontmost app
        guard let frontApp = NSWorkspace.shared.frontmostApplication else {
            return nil
        }
        
        let appName = frontApp.localizedName ?? "Unknown"
        let bundleID = frontApp.bundleIdentifier ?? ""
        
        // Try to get window title via Accessibility API
        let windowTitle = getActiveWindowTitle()
        
        let context = WindowContext(
            appName: appName,
            appBundleID: bundleID,
            windowTitle: windowTitle,
            timestamp: Date()
        )
        
        lastContext = context
        return context
    }
    
    // Check if context changed
    func hasContextChanged(from previous: WindowContext?) -> Bool {
        guard let current = getCurrentContext(),
              let previous = previous else {
            return true
        }
        
        return current.appName != previous.appName ||
               current.windowTitle != previous.windowTitle
    }
    
    private func getActiveWindowTitle() -> String? {
        // Note: This requires Accessibility permissions
        guard let app = NSWorkspace.shared.frontmostApplication else {
            return nil
        }
        
        let pid = app.processIdentifier
        let appRef = AXUIElementCreateApplication(pid)
        
        var window: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(
            appRef,
            kAXFocusedWindowAttribute as CFString,
            &window
        )
        
        guard result == .success,
              let windowRef = window else {
            return nil
        }
        
        var title: CFTypeRef?
        let titleResult = AXUIElementCopyAttributeValue(
            windowRef as! AXUIElement,
            kAXTitleAttribute as CFString,
            &title
        )
        
        guard titleResult == .success,
              let titleString = title as? String else {
            return nil
        }
        
        return titleString
    }
}

