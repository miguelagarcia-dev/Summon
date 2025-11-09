# AI Avatar Overlay - MVP Implementation Guide

## 📦 Project Goal
Desktop companion that lives transparently on screen, watches activity via screen capture + OCR, and talks naturally.

## 🛠️ Tech Stack
- **Swift + AppKit** - Window management ✅
- **Metal + MetalKit** - GPU rendering ✅  
- **ScreenCaptureKit** - Screen watching ❌ (skipped)
- **Vision Framework** - Text extraction ❌ (skipped)
- **ElevenLabs API** - Voice synthesis ✅
- **Claude API** - Conversational AI ✅
- **Speech Framework** - Voice input ✅ (bonus!)

## 📊 Quick Status Table

| Component | Status | Completion |
|-----------|--------|------------|
| 🎨 **Rendering** (Week 1) | ✅ Complete | 100% |
| 📺 **Screen Monitoring** (Week 2) | ❌ Skipped | 0% |
| 🎤 **Voice & Audio** (Week 3) | ✅ Complete | 100% |
| 🧠 **AI Brain** (Week 4) | 🟡 Mostly Done | 80% |
| **Overall Voice Companion** | 🟢 Working | **70%** |

---

## 📋 Current Status (Updated: Nov 9, 2025)

### 🎉 Summary
**You have a working voice companion!** The project pivoted from a passive screen-watching assistant to an **interactive voice companion**. You can talk to it, it thinks with Claude AI, and responds with natural speech via ElevenLabs.

**What Works:**
- 🎨 3D avatar with PBR rendering & visual glow
- 🎤 Speech recognition (you talk to it)
- 🧠 Claude AI conversation with personality
- 🗣️ Natural voice responses (ElevenLabs)
- 🔄 Full conversation loop

**What's Missing:**
- 📺 Screen capture & OCR (Week 2 skipped entirely)
- 🤖 Proactive behavior (it only responds when you talk)
- 🎭 Rich animations (only basic glow effect)

---

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

### ❌ Week 2 Not Started (0%)
**Vision/Context system skipped** - Project pivoted to voice-only interaction

### ✅ Week 3 Complete (25%)
**Voice synthesis & audio working!**

**Files:**
- `Summon/Speech/ElevenLabsManager.swift` ✅
  - API integration with voice settings
  - Audio caching (20 entry limit)
  - Error handling & retry logic
- `Summon/Speech/AudioPlayer.swift` ✅
  - AVAudioPlayer queue system
  - Playback callbacks
  - macOS audio handling
- `Summon/Speech/SpeechRecognizer.swift` ✅ **BONUS!**
  - Real-time speech-to-text
  - Silence detection (1.5s threshold)
  - Permission handling

### ✅ Week 4 Mostly Complete (20%)
**AI brain working!**

**Files:**
- `Summon/AI/ClaudeAPIManager.swift` ✅
  - Anthropic API integration
  - Claude 3 Haiku model
  - Retry logic with exponential backoff
- `Summon/AI/ConversationEngine.swift` ✅
  - Conversation history (10 message pairs)
  - Custom system prompt (deadpan humor)
  - Voice-only output enforcement
- `Summon/Coordinator/VoiceCompanionCoordinator.swift` ✅
  - State machine (idle/listening/thinking/speaking)
  - Full conversation loop
  - Visual feedback via renderer
- `Summon/Config.swift` ✅
  - API key configuration

**Missing:**
- ❌ `ActivityMonitor.swift` - No screen watching/trigger detection
- ❌ Screen capture integration

### ⚠️ Major Deviations from Plan
- **🎤 Voice-driven instead of context-aware** - User talks TO the companion
- **No screen monitoring** - Week 2 (Vision/OCR) completely skipped
- **Interactive conversation** - Not proactive commentary on activity
- **Real working prototype** - Conversation loop fully functional

### ✨ Extras (Not in Original Plan)
- **Speech Recognition** - `SpeechRecognizer.swift` with silence detection
- **Audio Caching** - Smart caching in `ElevenLabsManager` to reduce API calls
- **Visual State Feedback** - `isSpeaking` glow effect synced with audio
- **Retry Logic** - Robust error handling in API managers
- **Config System** - Centralized API key management
- **State Machine** - Clean state transitions (idle/listening/thinking/speaking)
- **Conversation Personality** - Deadpan humor system prompt

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

**Week 1 - Rendering** ✅ (100%)
- [x] Transparent window
- [x] 3D model rendering
- [x] PBR textures & lighting
- [ ] Animation (static currently)

**Week 2 - Screen Monitoring** ❌ (0% - SKIPPED)
- [ ] Screen capture
- [ ] OCR text extraction
- [ ] Window/app detection
- [ ] Context aggregation

**Week 3 - Voice & Audio** ✅ (100%)
- [x] Voice synthesis (ElevenLabs)
- [x] Audio playback with queue
- [x] **BONUS:** Speech recognition input
- [ ] Animation states (basic glow implemented)
- [ ] Lip-sync

**Week 4 - AI Brain** 🟡 (80%)
- [x] Claude API integration
- [x] Conversation engine with history
- [x] Main coordinator (voice-based)
- [ ] Trigger system (screen activity)
- [ ] Proactive commentary

---

## 🚀 Next Steps

### 🎯 Current Plan: Add Vision System (Screen Monitoring)

**See detailed implementation plan:** [`vision_implementation_plan.md`](vision_implementation_plan.md)

Transform your companion from **reactive** (you talk, it responds) to **proactive** (it watches and comments).

**Quick Overview:**
1. **Phase 1:** ScreenCaptureManager (2 FPS capture)
2. **Phase 2:** OCRProcessor (text extraction)
3. **Phase 3:** WindowContextManager (app tracking)
4. **Phase 4:** ContextAggregator (combine data)
5. **Phase 5:** ActivityMonitor (trigger detection)
6. **Phase 6:** Integration (enhance coordinator)
7. **Phase 7:** Polish & tune

**Estimated time:** 3-4 days  
**Result:** Context-aware companion that makes timely observations

---

### Alternative: Polish Voice Companion First
1. ✅ Voice conversation loop working
2. Add visual animation states (breathing, speaking indicators)
3. Polish conversation personality
4. Add conversation starters / idle chatter

**Current Progress: 70% (Voice Companion MVP) → Target: 100%**  
**With Vision: 45% → Target: 100% (full original vision)**
