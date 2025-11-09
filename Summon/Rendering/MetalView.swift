//
//  MetalView.swift
//  Summon
//
//  Created by Miguel Garcia on 11/8/25.
//

import MetalKit

class MetalView: MTKView {
    
    var renderer: ModelRenderer?
    
    required init(frame: CGRect) {
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("Metal is not supported on this device")
        }
        
        super.init(frame: frame, device: device)
        
        // Transparency configuration
        self.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
        self.colorPixelFormat = .bgra8Unorm
        self.depthStencilPixelFormat = .depth32Float  // ← ADD THIS LINE
        
        self.layer?.isOpaque = false
        self.framebufferOnly = false
        
        // Enable drawing - critical for rendering
        self.isPaused = false
        self.enableSetNeedsDisplay = false  // Use delegate-driven rendering
        
        // Create renderer
        renderer = ModelRenderer(device: device, view: self)
        self.delegate = renderer
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
