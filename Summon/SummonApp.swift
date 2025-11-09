//
//  SummonApp.swift
//  Summon
//
//  Created by Miguel Garcia on 11/8/25.
//

import AppKit
import MetalKit
import ModelIO

// Using custom main.swift - no @main here
class AppDelegate: NSObject, NSApplicationDelegate {
    var windowController: NSWindowController?
    
    override init() {
        super.init()
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Create and show transparent window
        windowController = OverlayWindowController()
        windowController?.showWindow(nil)
        
        // Activate the app and force window to front
        NSApp.activate(ignoringOtherApps: true)
        windowController?.window?.makeKeyAndOrderFront(nil)
        windowController?.window?.orderFrontRegardless()
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        // Cleanup if needed
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}
