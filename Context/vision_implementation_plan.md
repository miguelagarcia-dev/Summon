# Vision & Context System Implementation Plan

## 🎯 Goal
Add screen monitoring, OCR, and context awareness to the existing voice companion, enabling it to proactively comment on your activity instead of just responding when you speak to it.

## ✨ What's Already Provided

**You have production-ready code for:**

1. **✅ ScreenCaptureManager.swift** - Complete, optimized implementation
   - Memory-efficient (reused CIContext)
   - Frame throttling (processes every 5th frame = 0.4 FPS OCR)
   - Proper error handling
   - Permission management
   - Clean callbacks

2. **✅ coordinator_integration.md** - Complete integration guide
   - Full VoiceCompanionCoordinator enhancements
   - CompanionMode enum (reactive/proactive/hybrid)
   - Activity trigger handling
   - Prompt building strategies
   - Testing checklist
   - Performance optimization guide
   - User controls (settings UI)

**What you need to implement:** OCRProcessor, WindowContextManager, ContextAggregator, ActivityMonitor (reference implementations provided below)

## 📊 Progress Summary

| Component | Status | Lines of Code | Time Estimate |
|-----------|--------|---------------|---------------|
| ScreenCaptureManager | ✅ **Done** | 224 lines | 0 hours |
| Info.plist permissions | ✅ **Done** | N/A | 0 hours |
| Coordinator integration | ✅ **Done** | ~260 lines | 0 hours |
| OCRProcessor | 📝 **TODO** | ~100 lines | 1-2 hours |
| WindowContextManager | 📝 **TODO** | ~80 lines | 1 hour |
| ContextAggregator | 📝 **TODO** | ~120 lines | 1-2 hours |
| ActivityMonitor | 📝 **TODO** | ~100 lines | 1-2 hours |
| Testing & tuning | 📝 **TODO** | N/A | 4-6 hours |

**Overall:** ~50% complete (infrastructure done, need 4 components + testing)  
**Remaining Work:** 2-3 days → **10-14 hours of actual coding/testing**

---

## 📦 What You're Building

Transform your companion from **reactive** (you talk, it responds) to **proactive** (it watches and comments).

**Current State:** Interactive voice companion  
**Target State:** Context-aware AI assistant that watches your screen and makes timely observations

**Estimated Time:** 2-3 days (down from 4 days - Phase 1 & 6 mostly done!)

---

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────┐
│         VoiceCompanionCoordinator               │
│  (existing - will be enhanced)                  │
└─────────────────────────────────────────────────┘
                    ▼
    ┌───────────────┴───────────────┐
    ▼                               ▼
┌─────────────┐              ┌─────────────────┐
│   Speech    │              │    Vision       │
│   System    │              │    System       │
│  (exists)   │              │    (new!)       │
└─────────────┘              └─────────────────┘
                                     │
                    ┌────────────────┼────────────────┐
                    ▼                ▼                ▼
            ┌──────────────┐  ┌──────────┐  ┌───────────────┐
            │ScreenCapture │  │   OCR    │  │WindowContext  │
            │   Manager    │  │Processor │  │   Manager     │
            └──────────────┘  └──────────┘  └───────────────┘
                    │                ▼                │
                    └────────►┌──────────────┐◄──────┘
                              │   Context    │
                              │  Aggregator  │
                              └──────────────┘
                                     ▼
                              ┌──────────────┐
                              │  Activity    │
                              │  Monitor     │
                              └──────────────┘
```

---

## 📋 Implementation Checklist

### Phase 1: Screen Capture Foundation ✅ **COMPLETE**
- [x] Create `Summon/Vision/` directory
- [x] **Implement `ScreenCaptureManager.swift`** ✅ (production-ready code provided)
- [x] Request screen recording permissions
- [x] Test basic 2 FPS capture (0.4 FPS OCR processing)
- [x] Display captured frame info in console
- [x] **Update `Info.plist` with screen recording description** ✅ (see integration guide)
- [x] **Memory optimization** (reused CIContext, frame throttling)
- [x] **Error handling** (custom error types, callbacks)

**Status:** Production-ready `ScreenCaptureManager` with advanced optimizations already implemented!

### Phase 2: Text Extraction (Day 1)
- [ ] Implement `OCRProcessor.swift`
- [ ] Use Vision framework for text recognition
- [ ] Test OCR accuracy with sample apps
- [ ] Filter/clean extracted text
- [ ] Console logging of extracted text

**Reference implementation provided in plan** - ready to copy/paste and test

### Phase 3: Window Context (Day 1)
- [ ] Implement `WindowContextManager.swift`
- [ ] Get active window info (app name, window title)
- [ ] Test with multiple applications
- [ ] Console logging of window changes
- [ ] Request Accessibility permissions

**Reference implementation provided in plan** - ready to copy/paste and test

### Phase 4: Context Aggregation (Day 1-2)
- [ ] Implement `ContextAggregator.swift`
- [ ] Store snapshots (last 20 captures)
- [ ] Build contextual summaries
- [ ] Detect context changes
- [ ] Console logging of aggregated context

**Reference implementation provided in plan** - ready to copy/paste and test

### Phase 5: Activity Monitoring (Day 2)
- [ ] Implement `ActivityMonitor.swift`
- [ ] Define trigger conditions
- [ ] Detect patterns (long sessions, app switching, etc.)
- [ ] Console logging of triggers
- [ ] **Enhanced triggers** (significantChange, periodCheck, focusedWork)

**Enhanced implementation provided in integration guide**

### Phase 6: Integration ✅ **MOSTLY COMPLETE**
- [x] **Enhance `VoiceCompanionCoordinator`** ✅ (full code in integration guide)
- [x] **Add context-aware mode toggle** (reactive/proactive/hybrid modes)
- [x] **Build proactive commentary system** (prompt building, trigger handling)
- [x] **Task-based monitoring** (better than Timer approach)
- [ ] Test dual modes (reactive + proactive)
- [x] **User controls** (settings UI provided)

**Status:** Complete integration code provided - just needs testing!

### Phase 7: Polish (Day 2-3)
- [ ] Tune trigger thresholds
- [ ] Refine system prompts with context
- [ ] Add privacy controls
- [ ] Performance optimization (targets defined in integration guide)
- [ ] User testing

**Performance targets defined:** < 5% CPU, < 50MB memory, < 1s OCR

---

## 📁 File Structure & Status

```
Summon/
├── Vision/                                    # NEW DIRECTORY
│   ├── ScreenCaptureManager.swift           ✅ PROVIDED (production-ready!)
│   ├── OCRProcessor.swift                    📝 TODO (copy from plan)
│   ├── WindowContextManager.swift            📝 TODO (copy from plan)
│   ├── ContextAggregator.swift              📝 TODO (copy from plan)
│   └── ActivityMonitor.swift                📝 TODO (copy from plan - enhanced!)
├── Coordinator/
│   └── VoiceCompanionCoordinator.swift      ✅ INTEGRATION CODE PROVIDED
├── AI/
│   └── ConversationEngine.swift             ℹ️  May need minor prompt tweaks
└── Info.plist                               ✅ PERMISSIONS DOCUMENTED
```

**Legend:**
- ✅ = Code provided, ready to use
- 📝 = Need to implement (reference code in plan)
- ℹ️ = Optional enhancement

**Files to Copy:**
1. `screen_capture_manager.swift` → `Summon/Vision/ScreenCaptureManager.swift`
2. Integration code from `coordinator_integration.md` → Apply to `VoiceCompanionCoordinator.swift`

**Files to Implement:**
3. `OCRProcessor.swift` (Step 2 below - ~100 lines)
4. `WindowContextManager.swift` (Step 3 below - ~80 lines)
5. `ContextAggregator.swift` (Step 4 below - ~120 lines)
6. `ActivityMonitor.swift` (Step 5 below - ~100 lines)

**Total New Code:** ~400 lines (all reference implementations provided!)

---

## 🔨 Step-by-Step Implementation

### Step 1: ScreenCaptureManager.swift ✅ **COMPLETE**

**Purpose:** Capture screen at 2 FPS for analysis

**Status:** ✅ Production-ready implementation already provided in `screen_capture_manager.swift`

**Key Features Implemented:**
- ✅ Request screen recording permission with error handling
- ✅ Low-frequency capture (2 FPS capture, 0.4 FPS OCR processing)
- ✅ Memory efficient (reused CIContext - critical!)
- ✅ Frame throttling (processes every 5th frame)
- ✅ Custom error types
- ✅ Error callbacks
- ✅ Proper cleanup and resource management
- ✅ Dedicated dispatch queue for output

**Implementation Notes:**

The provided `ScreenCaptureManager` includes advanced optimizations:

1. **Memory Management:** Reuses single CIContext instance instead of creating one per frame (prevents memory disaster)
2. **Frame Throttling:** Captures at 2 FPS but only processes every 5th frame (0.4 FPS for OCR)
3. **Error Handling:** Custom `ScreenCaptureError` enum with descriptive messages
4. **Configuration:** 1280x720 resolution (lower = faster OCR, less memory)

**Usage:**
```swift
// Initialize
let manager = ScreenCaptureManager()

// Set up callbacks
manager.onFrameCaptured = { image in
    // Process frame (will be called at ~0.4 FPS)
    print("📸 Frame: \(image.width)x\(image.height)")
}

manager.onError = { error in
    print("❌ Error: \(error.localizedDescription)")
}

// Request permission and start
do {
    _ = try await manager.requestPermission()
    try await manager.startCapture()
} catch {
    print("Failed to start: \(error)")
}

// Stop when done
await manager.stopCapture()
```

**Action Required:** Copy `screen_capture_manager.swift` to `Summon/Vision/ScreenCaptureManager.swift`

---

### Step 2: OCRProcessor.swift

**Purpose:** Extract text from screen captures using Vision framework

**Key Features:**
- Fast recognition (accuracy is secondary)
- Filter noise/UI elements
- Return clean text chunks
- Efficient processing

**Implementation:**
```swift
import Vision
import CoreImage

class OCRProcessor {
    private let maxTextLength = 500  // Limit for Claude context
    
    // Process image and extract text
    func extractText(from image: CGImage) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            // Create vision request
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: "")
                    return
                }
                
                // Extract and join text
                let text = self.processObservations(observations)
                continuation.resume(returning: text)
            }
            
            // Configure for speed over accuracy
            request.recognitionLevel = .fast
            request.usesLanguageCorrection = false
            
            // Perform request
            let handler = VNImageRequestHandler(cgImage: image, options: [:])
            
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    private func processObservations(_ observations: [VNRecognizedTextObservation]) -> String {
        var allText: [String] = []
        
        for observation in observations {
            guard let candidate = observation.topCandidates(1).first else {
                continue
            }
            
            let text = candidate.string
            
            // Filter out noise
            if isValidText(text) {
                allText.append(text)
            }
        }
        
        // Join and limit length
        let combined = allText.joined(separator: " ")
        
        if combined.count > maxTextLength {
            return String(combined.prefix(maxTextLength))
        }
        
        return combined
    }
    
    private func isValidText(_ text: String) -> Bool {
        // Filter out very short text
        guard text.count > 2 else { return false }
        
        // Filter out common UI noise
        let noise = ["...", "•", "▸", "×"]
        if noise.contains(text) { return false }
        
        // Must have at least one letter
        return text.contains(where: { $0.isLetter })
    }
}
```

---

### Step 3: WindowContextManager.swift

**Purpose:** Track active window and application

**Key Features:**
- Get frontmost app
- Get window title (if accessible)
- Detect app switches
- Privacy-aware

**Implementation:**
```swift
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
```

---

### Step 4: ContextAggregator.swift

**Purpose:** Combine screen text + window info into meaningful context

**Key Features:**
- Store last N snapshots
- Build context summaries
- Detect significant changes
- Format for Claude API

**Implementation:**
```swift
import Foundation

struct ContextSnapshot {
    let windowContext: WindowContext
    let screenText: String
    let timestamp: Date
}

class ContextAggregator {
    private var snapshots: [ContextSnapshot] = []
    private let maxSnapshots = 20
    private let ocrProcessor = OCRProcessor()
    private let windowManager = WindowContextManager()
    
    // Process a new screen capture
    func processCapture(_ image: CGImage) async {
        // Extract text
        let text = (try? await ocrProcessor.extractText(from: image)) ?? ""
        
        // Get window context
        guard let windowContext = windowManager.getCurrentContext() else {
            return
        }
        
        // Create snapshot
        let snapshot = ContextSnapshot(
            windowContext: windowContext,
            screenText: text,
            timestamp: Date()
        )
        
        // Store
        snapshots.append(snapshot)
        
        // Trim old snapshots
        if snapshots.count > maxSnapshots {
            snapshots.removeFirst()
        }
        
        print("📊 Context: \(windowContext.appName) - \(text.prefix(50))...")
    }
    
    // Build context summary for AI
    func buildContextSummary() -> String {
        guard !snapshots.isEmpty else {
            return "No context available"
        }
        
        let latest = snapshots.last!
        
        // Get recent text (last 3 snapshots)
        let recentSnapshots = Array(snapshots.suffix(3))
        let recentText = recentSnapshots
            .map { $0.screenText }
            .filter { !$0.isEmpty }
            .joined(separator: " ")
        
        // Build summary
        var summary = "Current: \(latest.windowContext.appName)"
        
        if let title = latest.windowContext.windowTitle, !title.isEmpty {
            summary += " - \(title)"
        }
        
        if !recentText.isEmpty {
            let cleanText = recentText
                .components(separatedBy: .whitespacesAndNewlines)
                .filter { !$0.isEmpty }
                .joined(separator: " ")
                .prefix(200)
            
            summary += "\nRecent text: \(cleanText)"
        }
        
        return summary
    }
    
    // Get current app
    var currentApp: String? {
        return snapshots.last?.windowContext.appName
    }
    
    // Check if context is stable
    func isContextStable(timeWindow: TimeInterval = 30.0) -> Bool {
        guard snapshots.count >= 3 else { return false }
        
        let recent = snapshots.suffix(5)
        let appNames = Set(recent.map { $0.windowContext.appName })
        
        return appNames.count == 1  // Same app for recent snapshots
    }
}
```

---

### Step 5: ActivityMonitor.swift

**Purpose:** Detect patterns and trigger proactive commentary

**Key Features:**
- Pattern detection
- Trigger conditions  
- Cooldown periods
- Smart timing
- **Enhanced triggers** (from integration guide)

**Enhanced ActivityTrigger Enum:**
```swift
import Foundation

enum ActivityTrigger {
    case longSession(app: String, duration: TimeInterval)
    case focusedWork(app: String, duration: TimeInterval)
    case significantChange(from: String, to: String)  // Enhanced!
    case periodCheck(context: String)                 // Enhanced!
    
    var description: String {
        switch self {
        case .longSession(let app, let duration):
            return "Long session in \(app) for \(Int(duration/60)) minutes"
        case .focusedWork(let app, let duration):
            return "Focused work in \(app) for \(Int(duration/60)) minutes"
        case .significantChange(let from, let to):
            return "Switched from \(from) to \(to)"
        case .periodCheck(let ctx):
            return "Periodic check: \(ctx)"
        }
    }
}
```

**Implementation:**
```swift
class ActivityMonitor {
    private var appSessionStart: [String: Date] = [:]
    private var lastApp: String?
    private var lastCommentaryTime: Date?
    private var lastTriggerType: String?
    private let commentaryCooldown: TimeInterval = 600.0  // 10 min between comments (longer is better!)
    
    // Track engagement for learning
    private var engagementCount = 0
    private var ignoredCount = 0
    
    // Analyze context and detect triggers
    func analyzeActivity(aggregator: ContextAggregator) async -> ActivityTrigger? {
        // Don't spam - respect cooldown
        if let lastTime = lastCommentaryTime,
           Date().timeIntervalSince(lastTime) < commentaryCooldown {
            return nil
        }
        
        guard let currentApp = aggregator.currentApp else {
            return nil
        }
        
        // Detect app switches (significant change)
        if let previousApp = lastApp, previousApp != currentApp {
            lastApp = currentApp
            appSessionStart[currentApp] = Date()
            
            // Only trigger on significant switches (not minor window changes)
            if isSignificantSwitch(from: previousApp, to: currentApp) {
                return .significantChange(from: previousApp, to: currentApp)
            }
        }
        
        // Track session time
        if appSessionStart[currentApp] == nil {
            appSessionStart[currentApp] = Date()
            lastApp = currentApp
        }
        
        let sessionDuration = Date().timeIntervalSince(appSessionStart[currentApp]!)
        
        // Long session trigger (20+ minutes)
        if sessionDuration > 1200 && await aggregator.isContextStable() {
            return .longSession(app: currentApp, duration: sessionDuration)
        }
        
        // Focused work trigger (40+ minutes)
        if sessionDuration > 2400 && await aggregator.isContextStable(timeWindow: 60.0) {
            return .focusedWork(app: currentApp, duration: sessionDuration)
        }
        
        return nil
    }
    
    // Mark that commentary was triggered
    func markCommentary(trigger: ActivityTrigger) async {
        lastCommentaryTime = Date()
        lastTriggerType = trigger.description
    }
    
    // User feedback methods
    func markEngaged() async {
        engagementCount += 1
        print("📊 Engagement: \(engagementCount) engaged, \(ignoredCount) ignored")
    }
    
    func markIgnored() async {
        ignoredCount += 1
        print("📊 Engagement: \(engagementCount) engaged, \(ignoredCount) ignored")
    }
    
    // Check if app switch is significant
    private func isSignificantSwitch(from: String, to: String) -> Bool {
        // Filter out noise (system apps, notifications)
        let systemApps = ["Finder", "System Preferences", "Spotlight", "Notification Center"]
        if systemApps.contains(from) || systemApps.contains(to) {
            return false
        }
        return true
    }
    
    // Reset session for app
    func resetSession(for app: String) {
        appSessionStart[app] = nil
    }
    
    // Get statistics
    func getStatistics() async -> String {
        let engagementRate = engagementCount + ignoredCount > 0 
            ? Double(engagementCount) / Double(engagementCount + ignoredCount) * 100 
            : 0
        return "Engagement: \(engagementRate.rounded())% (\(engagementCount)/\(engagementCount + ignoredCount))"
    }
}
```

**Key Improvements from Integration Guide:**
1. ✅ Enhanced trigger types (significantChange, periodCheck)
2. ✅ Longer cooldown (10 min default - prevents spam)
3. ✅ Engagement tracking (learns from user feedback)
4. ✅ System app filtering (ignores Finder, Spotlight, etc.)
5. ✅ Async methods for thread safety
6. ✅ Statistics tracking

---

### Step 6: Enhance VoiceCompanionCoordinator ✅ **MOSTLY COMPLETE**

**Status:** ✅ Complete integration code provided in `coordinator_integration.md`

**What's Provided:**

1. **CompanionMode enum** - reactive/proactive/hybrid modes
2. **Vision system integration** - enable/disable methods
3. **Activity monitoring** - Task-based approach (better than Timer!)
4. **Prompt building** - Context-aware messages for each trigger type
5. **Error handling** - Graceful failure and recovery
6. **User feedback tracking** - Engagement metrics
7. **Settings UI** - User controls for mode and vision toggle

**Key Enhancements from Integration Guide:**

```swift
enum CompanionMode {
    case reactive   // Only responds when user speaks
    case proactive  // Watches screen and comments
    case hybrid     // Both (default)
}
```

**Main Integration Points:**

1. **Enable Vision:**
```swift
func enableVision() async {
    // Initialize all vision components
    // Request permissions (screen recording + accessibility)
    // Set up callbacks
    // Start monitoring with Task-based loop (not Timer!)
}
```

2. **Activity Monitoring:**
```swift
// Uses Task for better async control
contextMonitoringTask = Task { [weak self] in
    while !Task.isCancelled {
        try? await Task.sleep(nanoseconds: 30_000_000_000)
        await self?.checkForActivityTriggers()
    }
}
```

3. **Proactive Commentary:**
```swift
private func handleActivityTrigger(_ trigger: ActivityTrigger) async {
    // Build context-aware prompt
    // Get AI response
    // Synthesize speech
    // Play audio
    // Mark engagement
}
```

4. **User Feedback:**
```swift
func userEngagedWithComment() async {
    await activityMonitor?.markEngaged()
}

func userIgnoredComment() async {
    await activityMonitor?.markIgnored()
}
```

**Complete Implementation:** See `coordinator_integration.md` for:
- Full code (~260 lines)
- Testing checklist
- Performance metrics
- Common issues & solutions
- Best practices
- Settings UI example

**Action Required:**
1. Copy integration code from `coordinator_integration.md` 
2. Apply to `VoiceCompanionCoordinator.swift`
3. Follow testing checklist
4. Tune thresholds based on testing

---

## 🔑 Permission Updates

**Update Info.plist:**
```xml
<!-- Add to existing entries -->
<key>NSScreenCaptureDescription</key>
<string>To watch what you're working on and make timely observations</string>

<key>NSAppleEventsUsageDescription</key>
<string>To know which app you're using</string>
```

---

## 🧪 Testing Strategy

### Phase 1 Testing
```swift
// Test screen capture
let manager = ScreenCaptureManager()
await manager.requestPermission()
try await manager.startCapture()
// Should see console logs with frame info
```

### Phase 2 Testing
```swift
// Test OCR
let processor = OCRProcessor()
let text = try await processor.extractText(from: testImage)
print("Extracted: \(text)")
```

### Phase 3 Testing
```swift
// Test window tracking
let contextManager = WindowContextManager()
let context = contextManager.getCurrentContext()
print("App: \(context?.appName ?? "none")")
```

### Integration Testing
1. Open Safari and browse
2. Wait 2 minutes - should comment on browsing
3. Switch to Xcode
4. Write code for 15 minutes - should comment on long session
5. Rapidly switch apps - should notice switching pattern

---

## ⚙️ Configuration & Tuning

**Trigger Thresholds:**
```swift
// Adjust these based on testing
let longSessionThreshold = 900.0      // 15 minutes
let focusedWorkThreshold = 1800.0     // 30 minutes
let commentaryCooldown = 120.0        // 2 minutes
let captureRate = 0.5                 // 2 FPS
```

**Performance:**
- Screen capture: 1280x720 (fast OCR)
- Capture rate: 2 FPS (not 60!)
- Text limit: 200 chars for Claude
- Snapshot history: Last 20 captures
- Commentary cooldown: 2 minutes

---

## 🚀 Implementation Order (Updated)

**Day 1: Core Components** (~4-6 hours)
1. ✅ ~~Create Vision directory~~ (ready to go)
2. ✅ ~~Copy ScreenCaptureManager.swift~~ (already done!)
3. ✅ ~~Update Info.plist~~ (permissions documented)
4. 📝 Implement OCRProcessor.swift (copy from plan)
5. 📝 Test OCR with sample apps
6. 📝 Implement WindowContextManager.swift (copy from plan)
7. 📝 Test window tracking & accessibility permission

**Day 2: Aggregation & Monitoring** (~4-6 hours)
8. 📝 Implement ContextAggregator.swift (copy from plan)
9. 📝 Test context building with console logs
10. 📝 Implement ActivityMonitor.swift (enhanced version from plan)
11. 📝 Test trigger detection logic
12. 📝 Tune initial cooldown thresholds

**Day 2-3: Integration & Testing** (~4-6 hours)
13. ✅ ~~Copy integration code~~ (from coordinator_integration.md)
14. 📝 Apply to VoiceCompanionCoordinator.swift
15. 📝 Test vision enable/disable
16. 📝 Test reactive mode (voice only)
17. 📝 Test proactive mode (screen monitoring)
18. 📝 Test hybrid mode (both)
19. 📝 Performance monitoring (Instruments)

**Day 3: Polish & Tune** (~2-3 hours)
20. 📝 Adjust trigger thresholds based on real usage
21. 📝 Refine system prompts for better responses
22. 📝 Add settings UI (optional, template provided)
23. 📝 Final bug fixes & optimization

**Total: 2-3 days** (down from 4 days!)

### Quick Start Checklist

```bash
# Day 1 Morning
[ ] Copy screen_capture_manager.swift → Summon/Vision/ScreenCaptureManager.swift
[ ] Implement OCRProcessor.swift
[ ] Implement WindowContextManager.swift
[ ] Test each component individually

# Day 1 Afternoon  
[ ] Implement ContextAggregator.swift
[ ] Test aggregation with console logs

# Day 2 Morning
[ ] Implement ActivityMonitor.swift
[ ] Test trigger detection

# Day 2 Afternoon
[ ] Copy coordinator integration code
[ ] Apply to VoiceCompanionCoordinator
[ ] Test basic integration

# Day 3
[ ] Test all modes thoroughly
[ ] Tune thresholds
[ ] Performance check
[ ] Ship it! 🚀
```

---

## 🎯 Success Criteria

✅ Screen capture working at 2 FPS  
✅ OCR extracting readable text  
✅ Window tracking accurate  
✅ Context aggregation meaningful  
✅ Triggers firing appropriately  
✅ Proactive commentary natural  
✅ No performance issues  
✅ Privacy respectful  

---

## 🔒 Privacy Considerations

1. **No storage** - Don't save screenshots or text
2. **Local processing** - OCR happens on device
3. **User control** - Easy to disable monitoring
4. **Transparent** - Log what's being monitored
5. **Cooldown** - Respect user's attention

---

## 📝 Notes

- Start with conservative trigger thresholds
- Use console logging extensively during development
- Test with real workflows (coding, browsing, writing)
- The personality should be helpful, not annoying
- Remember: less is more for proactive commentary

---

## 🔄 Integration Points

**Existing Systems:**
- `VoiceCompanionCoordinator` - Add context mode
- `ConversationEngine` - Add context-aware prompts
- `SummonApp` - Add context toggle in startup

**New Systems:**
- Vision module (all new files)
- Activity detection (trigger logic)
- Context formatting (for Claude API)

---

Ready to build? Start with Phase 1 (ScreenCaptureManager) and test thoroughly before moving to the next phase!

