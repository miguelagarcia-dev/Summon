# AI Avatar Overlay - MVP Implementation Guide

## 📦 Project Goal
Desktop companion that lives transparently on screen, watches activity via screen capture + OCR, and talks naturally.

## 🛠️ Tech Stack
- **Swift + AppKit** - Window management
- **Metal + MetalKit** - GPU rendering  
- **ScreenCaptureKit** - Screen watching
- **Vision Framework** - Text extraction
- **ElevenLabs API** - Voice synthesis
- **Claude API** - Conversational AI

---

## 📋 Current Status (Updated: Nov 9, 2025)

### ✅ Week 1 Complete (25%)
- Transparent overlay window (bottom-right, 300x400px)
- Metal rendering pipeline with depth testing
- 3D USDZ model loading (Poddy robot)
- PBR texturing (6 channels: base, emission, metallic, roughness, normal, occlusion)
- Multi-light setup (key, fill, rim, bottom)
- Permission configuration (Info.plist)

**Files:**
- `Summon/main.swift` ✅
- `Summon/SummonApp.swift` ✅
- `Summon/Window/OverlayWindowController.swift` ✅
- `Summon/Rendering/MetalView.swift` ✅
- `Summon/Rendering/ModelRenderer.swift` ✅
- `Summon/Rendering/Shaders.metal` ✅

### ⚠️ Deviations
- **3D model instead of 2D sprites** - More advanced than planned
- **No liquid background shader** - Could add later
- **Static model** - No animation yet

### ❌ Weeks 2-4 Not Started (75% remaining)

---

## 🎯 Remaining Work

### Week 2: Screen Capture + Context
**Files to create:**
```
Vision/
├── ScreenCaptureManager.swift      # ScreenCaptureKit, 2 FPS capture
├── WindowContextManager.swift      # Accessibility API, active window
├── OCRProcessor.swift              # Vision framework, text extraction
└── ContextAggregator.swift         # Combine data, build history
```

**Key implementation:**
```swift
// ScreenCaptureManager.swift
class ScreenCaptureManager {
    func requestPermissions() async -> Bool {
        try? await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
        return true
    }
    
    func startCapture() async {
        let config = SCStreamConfiguration()
        config.minimumFrameInterval = CMTime(value: 1, timescale: 2) // 2 FPS
        // ... setup stream
    }
}

// OCRProcessor.swift - VNRecognizeTextRequest
// WindowContextManager.swift - NSWorkspace.shared.frontmostApplication + AXUIElement
// ContextAggregator.swift - Store last 20 snapshots, generate summaries
```

---

### Week 3: Animation + Voice
**Files to create:**
```
Avatar/
└── AvatarAnimationController.swift  # State machine: idle/speaking/thinking
Speech/
└── ElevenLabsManager.swift         # TTS API integration
```

**Animation strategy for 3D model:**
- Option A: Skeletal animation (if USDZ has bones)
- Option B: Swap USDZ models for states
- Option C: Transform animations (scale breathing, bobbing) ← **Recommended start**

**Key implementation:**
```swift
// ElevenLabsManager.swift
class ElevenLabsManager {
    private let apiKey = "YOUR_KEY"
    private let voiceID = "21m00Tcm4TlvDq8ikWAM" // Rachel
    
    func speak(_ text: String) async {
        // POST to https://api.elevenlabs.io/v1/text-to-speech/{voiceID}
        // Save to temp .mp3, play with AVAudioPlayer
    }
}

// AvatarAnimationController.swift
enum State { case idle, speaking, thinking }
// Toggle state, sync with audio playback
```

---

### Week 4: AI Brain
**Files to create:**
```
AI/
├── ClaudeAPIManager.swift          # Anthropic API client
├── ConversationEngine.swift        # Prompt builder
├── ActivityMonitor.swift           # Trigger detection
└── ConversationMemory.swift        # Last 10 exchanges
Coordinator/
└── AICompanionCoordinator.swift    # Main loop orchestrator
```

**Key implementation:**
```swift
// ClaudeAPIManager.swift
class ClaudeAPIManager {
    func getResponse(system: String, user: String) async -> String? {
        // POST to https://api.anthropic.com/v1/messages
        // Model: claude-sonnet-4-20250514, max_tokens: 150
    }
}

// ActivityMonitor.swift - Detect triggers
enum Trigger {
    case longSession(app: String, duration: TimeInterval)
    case frequentSwitching, inactivity, newActivity(app: String)
}

// AICompanionCoordinator.swift - Main loop
func start() {
    Timer.scheduledTimer(interval: 10.0) {
        1. Capture context
        2. Check triggers
        3. Generate Claude response
        4. Speak with ElevenLabs
        5. Update animation state
    }
}
```

**System prompt:**
```
You are a friendly AI companion living in a small window. 
Keep responses SHORT (1-2 sentences). Be curious, supportive, 
notice patterns. Casual tone like a helpful friend.
```

---

## 📊 Critical Details

### Permissions (Info.plist)
```xml
<key>LSUIElement</key><true/>
<key>NSScreenCaptureDescription</key><string>To see what you're working on</string>
<key>NSMicrophoneUsageDescription</key><string>To listen to your voice</string>
```

### Window Setup
```swift
window.isOpaque = false
window.backgroundColor = .clear
window.level = .floating
window.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]
```

### API Keys Needed
- ElevenLabs (free: 10k chars/month)
- Anthropic Claude (pay-as-you-go)

### Common Pitfalls
1. **Permissions** - Test screen recording & accessibility access
2. **Rate limits** - Short responses only, limit frequency
3. **OCR accuracy** - Fast mode, accept imperfection
4. **Performance** - Context capture at 2 FPS, not 60 FPS
5. **Context size** - Send only 200 chars of OCR text to Claude

---

## ✅ Quick Checklist

**Week 1** (Done)
- [x] Transparent window
- [x] 3D model rendering
- [x] PBR textures & lighting
- [ ] Animation (static currently)

**Week 2** (TODO)
- [ ] Screen capture
- [ ] OCR text extraction
- [ ] Window/app detection
- [ ] Context aggregation

**Week 3** (TODO)
- [ ] Voice synthesis
- [ ] Audio playback
- [ ] Animation states
- [ ] Lip-sync

**Week 4** (TODO)
- [ ] Claude API
- [ ] Trigger system
- [ ] Conversation memory
- [ ] Main coordinator

---

## 🚀 Next Steps

1. Create `Vision/` directory
2. Implement `ScreenCaptureManager.swift` (see code above)
3. Test with console logging before building full pipeline
4. Get screen recording permission in System Settings

**Progress: 25% → Target: 100%**
