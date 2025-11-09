# AI Avatar Overlay - Simplified Implementation Plan

## Phase 1: Display 3D Model

Goal: Get Black_Cat.usdz visible in a transparent floating window with basic rotation.

### Implementation

- Create macOS App project (Swift, AppKit)
- Add MetalKit and ModelIO frameworks
- Disable App Sandbox
- Add Black_Cat.usdz to project resources
- Create transparent borderless window (400x500px, floating level)
- Implement ModelRenderer to load and render USDZ model
- Create Metal shaders for vertex/fragment rendering
- Add matrix math helpers for transformations
- Implement slow rotation animation

### Success Criteria

- Transparent floating window appears
- Black_Cat.usdz model visible and rotating
- Window stays on top, can be repositioned

---

## Phase 2: Screen Watching + Context

Goal: Capture screen content and extract context about user activity.

### Implementation

- Request screen recording permission (Info.plist + runtime)
- Implement ScreenCaptureManager using ScreenCaptureKit
- Capture at 2 FPS (low frequency for context)
- Detect active window/app using Accessibility API
- Implement OCRProcessor using Vision framework
- Extract text from captured screenshots
- Build ContextAggregator to combine window info + OCR text
- Store context history (last 20 snapshots)

### Success Criteria

- App requests and receives screen recording permission
- Captures screen every 10 seconds
- Accurately detects active app and window title
- Extracts visible text via OCR
- Console logs show current activity context

---

## Phase 3: Avatar Animation + Voice

Goal: Add natural speech and synchronized animations to avatar.

### Implementation

- Create avatar sprite assets (idle, speaking states)
- Implement AvatarAnimationController with state machine
- Add idle breathing animation (scale oscillation)
- Setup ElevenLabs API integration
- Implement ElevenLabsManager for text-to-speech
- Add lip-sync animation during speech
- Create speaking state transitions
- Handle audio playback with AVAudioPlayer

### Success Criteria

- Avatar has idle breathing animation
- Can trigger speech via ElevenLabs
- Mouth animates during speech
- Natural voice quality
- Smooth state transitions

---

## Phase 4: AI Conversation Brain

Goal: Enable context-aware natural conversations with Claude API.

### Implementation

- Setup Claude API client (ClaudeAPIManager)
- Design system prompt for companion personality
- Build ConversationEngine to construct prompts from context
- Implement ActivityMonitor to detect triggers (long sessions, app switches, inactivity, time-based)
- Create AICompanionCoordinator to orchestrate context capture, trigger detection, AI responses, and speech
- Add ConversationMemory to track recent exchanges
- Implement conversation loop with timing controls

### Success Criteria

- Claude API responds contextually to user activity
- Avatar speaks when triggers detected
- Comments are relevant and specific
- Not too chatty (10-30 min intervals)
- Remembers recent conversation context
- Natural interaction flow

---

## File Structure

```
AIAvatarOverlay/
├── AppDelegate.swift
├── Window/
│   └── OverlayWindowController.swift
├── Rendering/
│   ├── MetalView.swift
│   ├── ModelRenderer.swift
│   └── Shaders.metal
├── Vision/
│   ├── ScreenCaptureManager.swift
│   ├── WindowContextManager.swift
│   ├── OCRProcessor.swift
│   └── ContextAggregator.swift
├── Avatar/
│   ├── AvatarRenderer.swift
│   └── AvatarAnimationController.swift
├── Speech/
│   └── ElevenLabsManager.swift
├── AI/
│   ├── ClaudeAPIManager.swift
│   ├── ConversationEngine.swift
│   └── ActivityMonitor.swift
└── Coordinator/
    └── AICompanionCoordinator.swift
```