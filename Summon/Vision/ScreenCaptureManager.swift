import ScreenCaptureKit
import CoreMedia
import CoreImage
import AppKit

/// Production-ready screen capture manager with proper memory management and error handling
class ScreenCaptureManager: NSObject, SCStreamDelegate, SCStreamOutput {
    
    // MARK: - Properties
    
    private var stream: SCStream?
    private var filter: SCContentFilter?
    private var isCapturing = false
    
    // Reuse CIContext - creating it every frame is a memory disaster
    private let ciContext = CIContext(options: [
        .useSoftwareRenderer: false,
        .cacheIntermediates: true
    ])
    
    // Frame processing control
    private var frameCounter: UInt64 = 0
    private let processEveryNthFrame: UInt64 = 5  // Process 1 out of 5 frames (0.4 FPS for OCR)
    
    // Callbacks
    var onFrameCaptured: ((CGImage) -> Void)?
    var onError: ((Error) -> Void)?
    
    // MARK: - Permission Management
    
    /// Request screen recording permission with proper error handling
    func requestPermission() async throws -> Bool {
        do {
            // This triggers the permission dialog if needed
            let content = try await SCShareableContent.excludingDesktopWindows(
                false,
                onScreenWindowsOnly: true
            )
            
            // Verify we have at least one display
            guard !content.displays.isEmpty else {
                throw ScreenCaptureError.noDisplaysAvailable
            }
            
            print("✅ Screen recording permission granted")
            return true
            
        } catch {
            print("❌ Screen recording permission error: \(error.localizedDescription)")
            throw ScreenCaptureError.permissionDenied(underlying: error)
        }
    }
    
    // MARK: - Capture Control
    
    /// Start capturing screen at 2 FPS (but only process every 5th frame for OCR)
    func startCapture() async throws {
        guard !isCapturing else {
            print("⚠️ Screen capture already running")
            return
        }
        
        // Get shareable content
        let content = try await SCShareableContent.excludingDesktopWindows(
            false,
            onScreenWindowsOnly: true
        )
        
        // Get main display
        guard let display = content.displays.first else {
            throw ScreenCaptureError.noDisplaysAvailable
        }
        
        print("📺 Using display: \(display.width)x\(display.height)")
        
        // Create filter for entire display (excluding nothing)
        filter = SCContentFilter(display: display, excludingWindows: [])
        
        // Configure stream for efficiency
        let config = SCStreamConfiguration()
        
        // Lower resolution = faster OCR, less memory
        config.width = 1280
        config.height = 720
        
        // 2 FPS capture rate
        config.minimumFrameInterval = CMTime(value: 1, timescale: 2)
        
        // Smaller queue depth for lower latency
        config.queueDepth = 3
        
        // Don't capture cursor or window list changes (we don't need them)
        config.showsCursor = false
        
        // Create stream
        guard let filter = filter else {
            throw ScreenCaptureError.filterCreationFailed
        }
        
        stream = SCStream(
            filter: filter,
            configuration: config,
            delegate: self
        )
        
        guard let stream = stream else {
            throw ScreenCaptureError.streamCreationFailed
        }
        
        // Add output handler with dedicated queue
        let outputQueue = DispatchQueue(
            label: "com.summon.screencapture.output",
            qos: .userInitiated
        )
        
        try stream.addStreamOutput(
            self,
            type: .screen,
            sampleHandlerQueue: outputQueue
        )
        
        // Start capture
        try await stream.startCapture()
        isCapturing = true
        frameCounter = 0
        
        print("✅ Screen capture started (2 FPS, processing every 5th frame)")
    }
    
    /// Stop capturing with proper cleanup
    func stopCapture() async {
        guard isCapturing else {
            print("⚠️ Screen capture not running")
            return
        }
        
        do {
            try await stream?.stopCapture()
            stream = nil
            filter = nil
            isCapturing = false
            frameCounter = 0
            print("🛑 Screen capture stopped")
            
        } catch {
            print("❌ Error stopping capture: \(error.localizedDescription)")
            onError?(error)
        }
    }
    
    // MARK: - SCStreamOutput
    
    func stream(
        _ stream: SCStream,
        didOutputSampleBuffer sampleBuffer: CMSampleBuffer,
        of type: SCStreamOutputType
    ) {
        // Increment frame counter
        frameCounter += 1
        
        // Only process every Nth frame to avoid OCR performance hit
        // 2 FPS capture, process every 5th = 0.4 FPS OCR
        guard frameCounter % processEveryNthFrame == 0 else {
            return
        }
        
        // Extract image buffer
        guard let imageBuffer = sampleBuffer.imageBuffer else {
            print("⚠️ No image buffer in sample")
            return
        }
        
        // Convert to CGImage efficiently
        let ciImage = CIImage(cvPixelBuffer: imageBuffer)
        
        // Reuse the same CIContext instance
        guard let cgImage = ciContext.createCGImage(
            ciImage,
            from: ciImage.extent
        ) else {
            print("⚠️ Failed to create CGImage")
            return
        }
        
        // Deliver frame on main thread
        DispatchQueue.main.async { [weak self] in
            self?.onFrameCaptured?(cgImage)
        }
    }
    
    // MARK: - SCStreamDelegate
    
    func stream(_ stream: SCStream, didStopWithError error: Error) {
        print("❌ Stream stopped with error: \(error.localizedDescription)")
        isCapturing = false
        
        DispatchQueue.main.async { [weak self] in
            self?.onError?(error)
        }
    }
}

// MARK: - Error Types

enum ScreenCaptureError: LocalizedError {
    case permissionDenied(underlying: Error)
    case noDisplaysAvailable
    case filterCreationFailed
    case streamCreationFailed
    
    var errorDescription: String? {
        switch self {
        case .permissionDenied(let error):
            return "Screen recording permission denied: \(error.localizedDescription)"
        case .noDisplaysAvailable:
            return "No displays available for capture"
        case .filterCreationFailed:
            return "Failed to create screen capture filter"
        case .streamCreationFailed:
            return "Failed to create screen capture stream"
        }
    }
}

