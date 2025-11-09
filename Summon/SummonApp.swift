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
    var voiceCompanion: VoiceCompanionCoordinator?
    
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
        
        // Initialize voice companion with API keys from Config
        voiceCompanion = VoiceCompanionCoordinator(
            claudeAPIKey: Config.claudeAPIKey,
            elevenLabsAPIKey: Config.elevenLabsAPIKey,
            elevenLabsVoiceID: Config.elevenLabsVoiceID
        )
        
        // Connect renderer for visual feedback (glow effect)
        if let overlayController = windowController as? OverlayWindowController {
            voiceCompanion?.renderer = overlayController.renderer
            if let renderer = overlayController.renderer {
                print("✅ Renderer connected to VoiceCompanion")
            } else {
                print("⚠️ Warning: Renderer is nil!")
            }
        } else {
            print("⚠️ Warning: Could not cast windowController to OverlayWindowController")
        }
        
        // Start the voice companion after a short delay to ensure window is ready
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.voiceCompanion?.start()
            print("✨ Summon is ready! Start speaking to interact.")
        }
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        // Stop voice companion
        voiceCompanion?.stop()
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}
