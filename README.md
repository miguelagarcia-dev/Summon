# Summon

**Your snarky AI companion that lives on your screen, watches what you do, and has opinions about it.**

Built at **Princeton Hackathon** — November 2025.

---

## What It Does

Summon is a macOS app that places a living 3D character directly on your desktop as a transparent, always-on-top overlay. The companion:

- **Listens** to you in real time via your microphone and responds conversationally
- **Watches your screen** using OCR to understand what you're working on
- **Speaks back** with a natural voice powered by ElevenLabs
- **Reacts proactively** — if you've been staring at the same document for 30 minutes, it might have something to say about that
- **Glows** when speaking, giving real-time visual feedback through its PBR-rendered emission map

The persona leans into dry wit and deadpan observations. It won't just say "great job" — it might say *"Interesting choice. Bold. Wrong, but bold."*

---

## Demo

Summon floats as a 3D animated black cat (`Black_Cat.usdz`) rendered directly onto a transparent window that overlays everything on your screen. It cycles between four states — idle, listening, thinking, and speaking — and its eyes emit a subtle glow whenever it talks.

The companion operates in three modes:
- **Reactive** — only speaks when spoken to
- **Proactive** — monitors your screen and chimes in unprompted
- **Hybrid** (default) — does both

---

## Tech Stack

| Layer | Technology |
|---|---|
| Language | Swift 5.9 |
| UI / Windowing | AppKit — transparent `NSWindow` overlay |
| 3D Rendering | Metal + MetalKit + ModelIO + SceneKit |
| Shaders | Custom PBR Metal shaders (albedo, normal, metallic, roughness, AO, emission) |
| Speech-to-Text | Apple Speech framework (`SFSpeechRecognizer`) |
| Text-to-Speech | ElevenLabs REST API |
| AI Brain | Anthropic Claude API (`claude-3-haiku-20240307`) |
| Screen Vision | ScreenCaptureKit + Apple Vision framework (OCR) |
| Concurrency | Swift Structured Concurrency (`async`/`await`, `Task`) |

---

## Architecture Overview

```
SummonApp
└── OverlayWindowController     ← Transparent, always-on-top NSWindow
    └── MetalView               ← MTKView driving the render loop
        └── ModelRenderer       ← Loads USDZ, runs PBR Metal shaders
                                   Controls emission glow (isSpeaking)

VoiceCompanionCoordinator       ← Central state machine (idle/listening/thinking/speaking)
├── SpeechRecognizer            ← Microphone → transcribed text
├── ConversationEngine          ← Manages conversation history + system prompt
│   └── ClaudeAPIManager        ← HTTP client for Anthropic Messages API
├── ElevenLabsManager           ← HTTP client for ElevenLabs TTS synthesis
├── AudioPlayer                 ← Plays synthesized audio, fires completion callback
└── Vision System (optional)
    ├── ScreenCaptureManager    ← ScreenCaptureKit stream at ~0.4 FPS
    ├── OCRProcessor            ← Vision framework text extraction
    ├── WindowContextManager    ← Tracks active app / window titles
    ├── ContextAggregator       ← Merges OCR + window context into a prompt string
    └── ActivityMonitor         ← Detects triggers (long sessions, focus, app switches)
                                   Fires proactive commentary every 30 s
```

The coordinator drives a simple state machine. When speech is detected, it stops listening, calls Claude, synthesizes audio via ElevenLabs, plays it back, then returns to listening. Visual state (the emission glow) is updated on every state transition.

---

## Setup

### Prerequisites

- macOS 13 Ventura or later
- Xcode 15+
- API keys for Anthropic and ElevenLabs

### API Keys

Open `Summon/Config.swift` and fill in your keys:

```swift
struct Config {
    static let claudeAPIKey      = "sk-ant-..."          // Anthropic Console
    static let elevenLabsAPIKey  = "sk_..."              // ElevenLabs dashboard
    static let elevenLabsVoiceID = "JBFqnCBsd6RMkjVDRZzb" // Voice ID from ElevenLabs
}
```

You can find or create a voice ID in your [ElevenLabs account](https://elevenlabs.io).

### Build & Run

1. Clone the repo
2. Open `Summon.xcodeproj` in Xcode
3. Fill in `Config.swift` with your API keys
4. Build and run (`⌘R`)
5. Grant microphone and screen recording permissions when prompted

> The app requests **Microphone** access for speech recognition and **Screen Recording** access for the vision system. Both dialogs appear on first launch.

---

## Permissions Required

| Permission | Purpose |
|---|---|
| Microphone | Real-time speech-to-text |
| Screen Recording | ScreenCaptureKit OCR for context awareness |

---

## Built at Princeton Hackathon

Summon was designed and built from scratch during the **Princeton Hackathon** (November 2025) by Miguel Garcia. The goal: make an AI that doesn't just answer questions — one that actually lives alongside you while you work, with a personality worth putting up with.
