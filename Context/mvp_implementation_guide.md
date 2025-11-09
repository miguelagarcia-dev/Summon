3# 🧠 AI Avatar Overlay - Complete MVP Implementation Guide

---

## 📦 WHAT YOU'RE BUILDING

A desktop companion that:
1. **Lives transparently** on your screen
2. **Watches what you do** via screen capture + OCR
3. **Talks naturally** about your activity

---

## 🛠️ CORE TECH STACK

```
┌─────────────────────────────────────────┐
│ Swift + AppKit                          │  ← Window management
├─────────────────────────────────────────┤
│ Metal + MetalKit                        │  ← GPU rendering
├─────────────────────────────────────────┤
│ ScreenCaptureKit                        │  ← Screen watching
├─────────────────────────────────────────┤
│ Vision Framework                        │  ← Text extraction
├─────────────────────────────────────────┤
│ ElevenLabs API                          │  ← Natural voice
├─────────────────────────────────────────┤
│ Anthropic Claude API                    │  ← Conversational AI
└─────────────────────────────────────────┘
```

---

## 📁 PROJECT FILE STRUCTURE

```
AIAvatarOverlay/
├── AppDelegate.swift                    # Entry point
├── Window/
│   └── OverlayWindowController.swift   # Transparent window
├── Rendering/
│   ├── MetalView.swift                 # Metal viewport
│   ├── Renderer.swift                  # Main render loop
│   └── Shaders.metal                   # GPU shaders
├── Vision/
│   ├── ScreenCaptureManager.swift      # Screen recording
│   ├── WindowContextManager.swift      # Active app detection
│   ├── OCRProcessor.swift              # Text extraction
│   └── ContextAggregator.swift         # Data combining
├── Avatar/
│   ├── AvatarRenderer.swift            # Sprite rendering
│   ├── AvatarAnimationController.swift # Animation states
│   └── AvatarAssets.xcassets/          # Sprite images
├── Speech/
│   └── ElevenLabsManager.swift         # Voice synthesis
├── AI/
│   ├── ClaudeAPIManager.swift          # LLM client
│   ├── ConversationEngine.swift        # Prompt builder
│   └── ActivityMonitor.swift           # Trigger detection
└── Coordinator/
    └── AICompanionCoordinator.swift    # Main orchestrator
```

---

## 🎬 WEEK-BY-WEEK EXECUTION

---

## WEEK 1: TRANSPARENT WINDOW + LIQUID EFFECT

### Goal
Floating window with animated background

### What to Build

**1. Create Project**
- New macOS App in Xcode
- Swift + AppKit
- Remove storyboard

**2. Configure Permissions (Info.plist)**
```xml
<key>NSScreenCaptureDescription</key>
<string>To see what you're working on</string>
<key>LSUIElement</key>
<true/>
```

**3. Build Transparent Window**

Key concepts:
- Borderless window style
- Clear background color
- Floating window level
- Lives on all spaces

Example:
```swift
// OverlayWindowController.swift
class OverlayWindowController: NSWindowController {
    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 100, y: 100, width: 400, height: 500),
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
            .stationary,                      // Doesn't move between spaces
            .fullScreenAuxiliary              // Works in fullscreen mode
        ]
        window.hasShadow = true               // Subtle depth
        window.isMovableByWindowBackground = true
        
        self.init(window: window)
    }
}
```

**4. Setup Metal Pipeline**

Key concepts:
- MTKView with alpha channel
- Render loop at 60fps
- Shader compilation

Example:
```swift
// MetalView.swift
class MetalView: MTKView {
    required init(frame: CGRect) {
        super.init(frame: frame, device: MTLCreateSystemDefaultDevice())
        
        // Transparency configuration
        self.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
        self.colorPixelFormat = .bgra8Unorm
        self.layer?.isOpaque = false
        self.framebufferOnly = false
        
        renderer = Renderer(device: device!, view: self)
        self.delegate = renderer
    }
}
```

**5. Create Liquid Shader**

Effect: Flowing iridescent background

```metal
// Shaders.metal
fragment float4 liquidFragmentShader(
    VertexOut in [[stage_in]],
    constant float &time [[buffer(0)]]
) {
    float2 uv = in.texCoord;
    
    // Create flowing liquid effect
    float wave1 = sin(uv.x * 10.0 + time * 2.0) * 0.5;
    float wave2 = cos(uv.y * 10.0 + time * 1.5) * 0.5;
    float combined = wave1 + wave2;
    
    // Iridescent color
    float3 color1 = float3(0.3, 0.5, 0.9); // Blue
    float3 color2 = float3(0.6, 0.3, 0.8); // Purple
    float3 color = mix(color1, color2, combined);
    
    // Fade edges for smooth blending
    float alpha = smoothstep(0.0, 0.2, uv.x) * 
                  smoothstep(1.0, 0.8, uv.x) *
                  smoothstep(0.0, 0.2, uv.y) * 
                  smoothstep(1.0, 0.8, uv.y);
    
    return float4(color, alpha * 0.3); // Semi-transparent
}
```

**Testing Checkpoint**: You should see a draggable transparent window with animated liquid-like background flowing smoothly.

---

## WEEK 2: SCREEN WATCHING + CONTEXT

### Goal
Capture and understand what user is doing

### What to Build

**1. Request Screen Recording Permission**

Flow:
- App asks for permission
- User grants in System Settings
- Verify access granted

Example:
```swift
// ScreenCaptureManager.swift
class ScreenCaptureManager {
    func requestPermissions() async -> Bool {
        do {
            try await SCShareableContent.excludingDesktopWindows(
                false, 
                onScreenWindowsOnly: true
            )
            return true
        } catch {
            print("Screen recording permission denied")
            return false
        }
    }
}
```

**2. Setup ScreenCaptureKit**

Key concepts:
- Capture main display
- 2 FPS (enough for context)
- BGRA pixel format

Example:
```swift
func startCapture() async {
    let content = try? await SCShareableContent.current
    guard let display = content?.displays.first else { return }
    
    let filter = SCContentFilter(display: display, excludingWindows: [])
    
    let config = SCStreamConfiguration()
    config.width = 1920
    config.height = 1080
    config.minimumFrameInterval = CMTime(value: 1, timescale: 2) // 2 FPS
    config.pixelFormat = kCVPixelFormatType_32BGRA
    
    stream = SCStream(filter: filter, configuration: config, delegate: self)
    try? await stream?.startCapture()
}
```

**3. Detect Active Window**

Using Accessibility API:

```swift
// WindowContextManager.swift
class WindowContextManager {
    func getCurrentWindowInfo() -> WindowContext? {
        guard let app = NSWorkspace.shared.frontmostApplication else { return nil }
        
        let appName = app.localizedName ?? "Unknown"
        let bundleID = app.bundleIdentifier ?? ""
        
        // Get window title via Accessibility API
        let appRef = AXUIElementCreateApplication(app.processIdentifier)
        var windowTitle: AnyObject?
        
        AXUIElementCopyAttributeValue(
            appRef, 
            kAXFocusedWindowAttribute as CFString, 
            &windowTitle
        )
        
        if let window = windowTitle {
            var title: AnyObject?
            AXUIElementCopyAttributeValue(
                window as! AXUIElement,
                kAXTitleAttribute as CFString,
                &title
            )
            
            return WindowContext(
                appName: appName,
                bundleID: bundleID,
                windowTitle: title as? String ?? ""
            )
        }
        
        return WindowContext(appName: appName, bundleID: bundleID, windowTitle: "")
    }
}
```

**4. Extract Text via OCR**

Using Vision framework:

```swift
// OCRProcessor.swift
class OCRProcessor {
    func extractText(from image: CGImage) async -> String {
        return await withCheckedContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: "")
                    return
                }
                
                let text = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }.joined(separator: " ")
                
                continuation.resume(returning: text)
            }
            
            request.recognitionLevel = .fast
            request.usesLanguageCorrection = true
            
            let handler = VNImageRequestHandler(cgImage: image, options: [:])
            try? handler.perform([request])
        }
    }
}
```

**5. Build Context Aggregator**

Combines all data:

```swift
// ContextAggregator.swift
class ContextAggregator {
    private var contextHistory: [ContextSnapshot] = []
    private let maxHistorySize = 20
    
    func addSnapshot(_ snapshot: ContextSnapshot) {
        contextHistory.append(snapshot)
        if contextHistory.count > maxHistorySize {
            contextHistory.removeFirst()
        }
    }
    
    func generateSummary() -> String {
        let recentApps = contextHistory.suffix(5).map { $0.windowContext.appName }
        let mostUsedApp = Dictionary(grouping: recentApps, by: { $0 })
            .max(by: { $0.value.count < $1.value.count })?.key ?? "Unknown"
        
        let recentText = contextHistory.suffix(3)
            .compactMap { $0.ocrText }
            .joined(separator: " ")
        
        return """
        Current Activity:
        - App: \(mostUsedApp)
        - Recent text: \(recentText.prefix(200))
        """
    }
}

struct ContextSnapshot {
    let windowContext: WindowContext
    let ocrText: String?
    let screenshot: CGImage?
    let timestamp: Date
}
```

**Testing Checkpoint**: Every 10 seconds, print to console what app you're using and any visible text. Should accurately reflect your activity.

---

## WEEK 3: ANIMATED AVATAR + VOICE

### Goal
Character that speaks naturally

### What to Build

**1. Create Avatar Sprites**

Assets needed (512x512 PNG):
- `avatar_idle.png` - Default state
- `avatar_speaking_1.png` - Mouth open
- `avatar_speaking_2.png` - Mouth closed
- `avatar_thinking.png` - Optional
- `avatar_excited.png` - Optional

Can use:
- Adobe Illustrator/Photoshop
- Procreate
- Midjourney/DALL-E for generation
- Free sprite sites

**2. Render Sprite in Metal**

```swift
// AvatarRenderer.swift
class AvatarRenderer {
    var currentTexture: MTLTexture?
    var position: CGPoint = CGPoint(x: 200, y: 400)
    var scale: Float = 1.0
    
    func loadTextures(device: MTLDevice) {
        let textureLoader = MTKTextureLoader(device: device)
        
        guard let idleURL = Bundle.main.url(forResource: "avatar_idle", withExtension: "png"),
              let texture = try? textureLoader.newTexture(URL: idleURL)
        else { return }
        
        currentTexture = texture
    }
    
    func render(encoder: MTLRenderCommandEncoder, time: Float) {
        guard let texture = currentTexture else { return }
        
        // Animate idle breathing
        let breathe = sin(time * 2.0) * 0.05 + 1.0
        let animatedScale = scale * breathe
        
        encoder.setFragmentTexture(texture, index: 0)
        // ... draw textured quad
    }
}
```

**3. Add Idle Animation**

Simple breathing effect:
- Slight scale oscillation
- Slow vertical bob
- Makes character feel alive

**4. Setup ElevenLabs**

Steps:
- Create account (free tier: 10k chars/month)
- Get API key
- Choose voice (Rachel recommended)

```swift
// ElevenLabsManager.swift
class ElevenLabsManager {
    private let apiKey = "YOUR_API_KEY"
    private let voiceID = "21m00Tcm4TlvDq8ikWAM" // Rachel
    
    func speak(_ text: String, emotion: Emotion = .neutral) async {
        let url = URL(string: "https://api.elevenlabs.io/v1/text-to-speech/\(voiceID)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "xi-api-key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "text": text,
            "model_id": "eleven_monolingual_v1",
            "voice_settings": [
                "stability": emotion.stability,
                "similarity_boost": 0.75
            ]
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            playAudio(data: data)
        } catch {
            print("Speech synthesis failed: \(error)")
        }
    }
    
    private func playAudio(data: Data) {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("speech.mp3")
        try? data.write(to: tempURL)
        try? AVAudioPlayer(contentsOf: tempURL).play()
    }
}

enum Emotion {
    case neutral, excited, concerned, playful
    
    var stability: Float {
        switch self {
        case .neutral: return 0.5
        case .excited: return 0.3
        case .concerned: return 0.7
        case .playful: return 0.4
        }
    }
}
```

**5. Implement Lip-Sync**

```swift
// AvatarAnimationController.swift
class AvatarAnimationController {
    enum State {
        case idle, speaking, thinking, excited
    }
    
    private(set) var state: State = .idle
    private var mouthPhase: Float = 0
    
    func update(deltaTime: Float) -> String {
        switch state {
        case .idle:
            return "avatar_idle"
            
        case .speaking:
            mouthPhase += deltaTime * 15.0
            return mouthPhase.truncatingRemainder(dividingBy: 1.0) > 0.5 
                ? "avatar_speaking_1" 
                : "avatar_speaking_2"
            
        case .thinking:
            return "avatar_thinking"
            
        case .excited:
            return "avatar_excited"
        }
    }
}
```

**Testing Checkpoint**: Click avatar → speaks "Hello! I'm watching you code!" with natural voice and mouth moving.

---

## WEEK 4: AI CONVERSATION BRAIN

### Goal
Natural, context-aware interactions

### What to Build

**1. Setup Claude API**

```swift
// ClaudeAPIManager.swift
class ClaudeAPIManager {
    private let apiKey = "YOUR_ANTHROPIC_KEY"
    private let model = "claude-sonnet-4-20250514"
    
    func getResponse(systemPrompt: String, userMessage: String) async -> String? {
        let url = URL(string: "https://api.anthropic.com/v1/messages")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        
        let body: [String: Any] = [
            "model": model,
            "max_tokens": 150,
            "system": systemPrompt,
            "messages": [
                ["role": "user", "content": userMessage]
            ]
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            let content = json?["content"] as? [[String: Any]]
            return content?.first?["text"] as? String
        } catch {
            return nil
        }
    }
}
```

**2. Design System Prompt**

```swift
let systemPrompt = """
You are a friendly AI companion avatar named Aria. You live in a small window 
on the user's screen and can see what they're working on.

Personality:
- Curious and supportive
- Makes lighthearted jokes occasionally
- Asks thoughtful questions about their work
- Notices patterns (like working late, switching apps frequently)
- Keeps responses SHORT (1-2 sentences max)

Tone: Casual, warm, like a helpful friend checking in.
"""
```

**3. Build Prompt Constructor**

```swift
// ConversationEngine.swift
class ConversationEngine {
    private let claude = ClaudeAPIManager()
    
    func generateComment(context: ContextSnapshot) async -> String? {
        let prompt = buildPrompt(from: context)
        return await claude.getResponse(
            systemPrompt: systemPrompt,
            userMessage: prompt
        )
    }
    
    private func buildPrompt(from context: ContextSnapshot) -> String {
        let timeOfDay = Calendar.current.component(.hour, from: Date())
        let greeting = timeOfDay < 12 ? "morning" : timeOfDay < 18 ? "afternoon" : "evening"
        
        return """
        Current context:
        - Time: \(greeting)
        - App: \(context.windowContext.appName)
        - Window title: \(context.windowContext.windowTitle)
        - Visible text: \(context.ocrText?.prefix(200) ?? "")
        
        Based on this, make a SHORT, natural comment or ask a question. 
        Be specific about what you notice.
        """
    }
}
```

**4. Create Activity Monitor**

```swift
// ActivityMonitor.swift
class ActivityMonitor {
    enum Trigger {
        case longSession(app: String, duration: TimeInterval)
        case frequentSwitching
        case inactivity
        case newActivity(app: String)
        case timeOfDay
    }
    
    func checkForTriggers(context: ContextSnapshot) -> Trigger? {
        // Long coding session
        if context.windowContext.appName == "Xcode" && currentAppDuration > 3600 {
            return .longSession(app: "Xcode", duration: currentAppDuration)
        }
        
        // User idle
        if Date().timeIntervalSince(lastActivityCheck) > 600 {
            return .inactivity
        }
        
        // New app opened
        if hasAppChanged(context) {
            return .newActivity(app: context.windowContext.appName)
        }
        
        return nil
    }
}
```

**5. Implement Conversation Loop**

```swift
// AICompanionCoordinator.swift
class AICompanionCoordinator {
    private let monitor = ActivityMonitor()
    private let conversation = ConversationEngine()
    private let avatar = AvatarAnimationController()
    
    func start() async {
        Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { _ in
            Task { await self.updateCycle() }
        }
    }
    
    private func updateCycle() async {
        // 1. Capture context
        let snapshot = captureCurrentContext()
        
        // 2. Check for triggers
        if let trigger = monitor.checkForTriggers(context: snapshot) {
            await handleInteraction(trigger: trigger, context: snapshot)
        }
    }
    
    private func handleInteraction(trigger: ActivityMonitor.Trigger, context: ContextSnapshot) async {
        guard let response = await conversation.generateComment(context: context) else { return }
        
        avatar.state = .speaking
        await elevenLabs.speak(response)
        avatar.state = .idle
    }
}
```

**6. Add Conversation Memory**

```swift
// ConversationMemory.swift
class ConversationMemory {
    private var exchanges: [Exchange] = []
    private let maxMemory = 10
    
    struct Exchange {
        let context: String
        let avatarSaid: String
        let timestamp: Date
    }
    
    func addExchange(context: String, response: String) {
        exchanges.append(Exchange(
            context: context,
            avatarSaid: response,
            timestamp: Date()
        ))
        
        if exchanges.count > maxMemory {
            exchanges.removeFirst()
        }
    }
    
    func getRecentHistory() -> String {
        exchanges.suffix(3).map { exchange in
            "[\(exchange.timestamp.formatted(.dateTime.hour().minute()))] Aria: \(exchange.avatarSaid)"
        }.joined(separator: "\n")
    }
}
```

**Testing Checkpoint**: Open Xcode → Avatar comments. Switch to browser → Avatar notices. Code for 30 minutes → Avatar suggests break.

---

## 🧩 KEY INTEGRATION POINTS

### Main App Loop (runs continuously)

```
┌─────────────────────────────────────────┐
│ 1. Metal Render Loop (60 FPS)          │
│    - Draw liquid background             │
│    - Render avatar sprite               │
│    - Animate current state              │
└─────────────────────────────────────────┘
           ↓
┌─────────────────────────────────────────┐
│ 2. Context Capture (every 10 sec)      │
│    - Screenshot active window           │
│    - Run OCR on text                    │
│    - Get app/window info                │
│    - Store in context buffer            │
└─────────────────────────────────────────┘
           ↓
┌─────────────────────────────────────────┐
│ 3. Activity Analysis (every 10 sec)    │
│    - Check for interaction triggers     │
│    - Compare with previous state        │
│    - Detect patterns                    │
└─────────────────────────────────────────┘
           ↓
┌─────────────────────────────────────────┐
│ 4. AI Response (when triggered)        │
│    - Build context prompt               │
│    - Send to Claude API                 │
│    - Get natural response               │
└─────────────────────────────────────────┘
           ↓
┌─────────────────────────────────────────┐
│ 5. Speech + Animation (async)          │
│    - Change avatar state to "speaking"  │
│    - Send text to ElevenLabs            │
│    - Stream audio response              │
│    - Sync lip animation                 │
│    - Return to idle when done           │
└─────────────────────────────────────────┘
```

---

## 🎯 MINIMUM VIABLE FEATURE SET

By end of Week 4, must have:

**Visual**
- ✅ Transparent floating window
- ✅ Animated liquid background
- ✅ 2D avatar sprite visible
- ✅ Smooth 60 FPS rendering

**Awareness**
- ✅ Captures screen every 10 seconds
- ✅ Reads active app name
- ✅ Extracts visible text via OCR
- ✅ Tracks activity patterns

**Interaction**
- ✅ Speaks with natural voice (ElevenLabs)
- ✅ Lip-syncs to speech
- ✅ Generates contextual comments
- ✅ Initiates conversation proactively

**Intelligence**
- ✅ Uses Claude API for responses
- ✅ Responds to triggers (app switches, long sessions)
- ✅ Remembers recent conversation
- ✅ Makes relevant observations

---

## 💡 EXAMPLE INTERACTION FLOWS

### Scenario 1: Coding Session
```
9:00 AM - User opens Xcode
Avatar: "Morning! Starting early today?"

10:30 AM - Still in Xcode, OCR detects "bug fix"
Avatar: "Hunting bugs? The best developers spend more time debugging than writing! 🐛"

12:00 PM - Still coding
Avatar: "You've been at it for 3 hours. Maybe grab lunch?"
```

### Scenario 2: Context Switch
```
User switches: Xcode → Safari → YouTube
Avatar: "From code to cat videos? I respect the break strategy 😸"
```

### Scenario 3: Late Night
```
2:00 AM - Still active
Avatar: "Still up? Either you're on a roll or stuck on something..."
```

### Scenario 4: Pattern Recognition
```
User opens Twitter 5 times in 10 minutes
Avatar: "That's the 5th time you've checked Twitter... procrastinating or waiting for news?"
```

---

## 🔑 CRITICAL SUCCESS FACTORS

### 1. Window Transparency
Must be truly transparent, not just black background. Users should see through to their desktop/apps.

### 2. Non-Intrusive
- Small window (400x500px)
- Positioned in corner
- Doesn't block work
- Can be dragged if needed

### 3. Context Accuracy
OCR must reliably extract text from active window. Test with various apps (Xcode, browser, terminal).

### 4. Natural Speech
ElevenLabs quality is key. Voice must sound human, not robotic. Short responses only (1-2 sentences).

### 5. Smart Triggers
Don't speak too often (annoying) or too rarely (useless). Find balance: every 10-30 minutes unless something notable happens.

### 6. Relevant Responses
Claude must generate contextual comments, not generic ones. Pass specific details in prompts.

---

## 🎨 DESIGN CONSIDERATIONS

### Avatar Character Design
- Simple, friendly appearance
- Readable at 256x256px size
- Distinctive silhouette
- Expressive face/eyes
- Fits "helpful companion" vibe

### Voice Selection (ElevenLabs)
Recommended voices:
- **Rachel** - Warm, friendly female
- **Adam** - Casual, relatable male
- **Bella** - Energetic, younger
- **Antoni** - Deep, reassuring

Test with your content before committing.

### Liquid Background
- Subtle, not distracting
- Complements avatar colors
- Smooth animation
- Low opacity (20-30%)

---

## 🚨 COMMON PITFALLS TO AVOID

### 1. Permission Hell
macOS is strict. Must request:
- Screen Recording (ScreenCaptureKit)
- Accessibility (for window info)

Test permissions flow thoroughly.

### 2. API Rate Limits
- ElevenLabs free tier: 10k characters/month
- Claude API: Pay per token

Solution: Limit interactions, short responses.

### 3. OCR Accuracy
Vision framework struggles with:
- Small text
- Low contrast
- Code syntax

Solution: Use fast recognition, accept imperfection.

### 4. Performance
Rendering + screen capture + OCR + API calls = resource intensive

Solution: Run CV layer at low FPS (2 Hz), not render rate (60 Hz).

### 5. Context Overload
Sending entire screen text to Claude = expensive + slow

Solution: Send only last 200 chars of OCR text.

---

## 📝 WEEK 4 FINAL CHECKLIST

Before calling MVP complete:

**Functional**
- [ ] Window appears on launch
- [ ] Window stays transparent
- [ ] Avatar animates smoothly
- [ ] Screen capture works
- [ ] OCR extracts text
- [ ] App detection works
- [ ] Speech plays correctly
- [ ] Lip-sync matches audio
- [ ] Claude responds contextually
- [ ] Triggers fire appropriately

**User Experience**
- [ ] Avatar speaks naturally
- [ ] Comments are relevant
- [ ] Not too chatty
- [ ] Not too quiet
- [ ] Can be dragged/repositioned
- [ ] Doesn't crash or freeze

**Polish**
- [ ] Initial greeting works
- [ ] At least 3 different trigger types
- [ ] Conversation doesn't repeat
- [ ] Voice sounds good
- [ ] Avatar looks appealing

---

## 🚀 LAUNCH SEQUENCE

When ready to demo:

1. **Start app** → Window appears, avatar greets you
2. **Open Xcode** → Avatar comments on coding
3. **Switch to browser** → Avatar notices change
4. **Code for 30 min** → Avatar suggests break
5. **Open documentation** → Avatar asks what you're learning

If all work, **MVP is complete**.

---

## 🎓 WHAT YOU'LL LEARN

- **Metal** - GPU rendering, shaders, textures
- **Computer Vision** - Screen capture, OCR, pattern detection
- **API Integration** - ElevenLabs, Claude, async networking
- **macOS Development** - AppKit, permissions, window management
- **AI Prompting** - Context engineering, conversation design
- **Animation** - State machines, sprite systems, lip-sync

This is a **real, shippable project** that showcases advanced skills.

---

## ✨ STRETCH GOALS (Post-MVP)

If you finish early or want to continue:

- **3D Avatar** - Use ModelIO for depth
- **Voice Input** - You talk back to avatar
- **Keyboard Shortcuts** - Global hotkey to summon
- **Emotion Detection** - React to your facial expressions
- **Custom Personalities** - Multiple avatar characters
- **Activity Reports** - "You coded 6 hours today!"
- **Focus Mode** - Silences during deep work
- **Particle Effects** - Hearts, sparkles when happy

---

## 🎯 YOUR ACTUAL STEPS

1. **Week 1**: Build window + liquid shader → Test transparency
2. **Week