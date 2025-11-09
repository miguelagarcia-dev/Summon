# 3D Model Rendering Plan

## Goal
Create a transparent floating window and display Black_Cat.usdz model using Metal rendering. This phase focuses ONLY on visual rendering - no speech, no voice, no API integrations.

## Implementation Steps

### Step 1: Create Window Controller
**File:** `Window/OverlayWindowController.swift`

**What it does:**
- Creates transparent, borderless, floating NSWindow
- Manages window lifecycle and positioning
- Makes window draggable

**Key properties:**
- Window size: 400x500px
- Style: borderless, no title bar
- Background: transparent (isOpaque = false, backgroundColor = .clear)
- Level: .floating (stays on top)
- Collection behavior: canJoinAllSpaces, stationary

**Implementation details:**
- NSWindowController subclass
- Custom init() creates and configures window
- Window positioned at default location (100, 100 from bottom-left)

---

### Step 2: Create Metal View
**File:** `Rendering/MetalView.swift`

**What it does:**
- Custom MTKView with transparency support
- Sets up Metal device and rendering context
- Connects to ModelRenderer for drawing

**Key properties:**
- Clear color: MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0) - fully transparent
- Pixel format: .bgra8Unorm (supports alpha channel)
- Layer opacity: false (allows transparency)
- Framebuffer only: false (needed for transparency)

**Implementation details:**
- Subclass of MTKView
- Creates Metal device in init
- Sets up renderer as delegate
- Handles view resize events

---

### Step 3: Create Model Renderer
**File:** `Rendering/ModelRenderer.swift`

**What it does:**
- Loads Black_Cat.usdz using ModelIO
- Converts USDZ mesh to Metal-compatible format
- Renders 3D model every frame using Metal

**Key components:**
- Metal device reference
- Vertex buffer (3D model vertices)
- Index buffer (triangle indices)
- Render pipeline state (shaders)
- Uniform buffer (transformation matrices)

**Implementation details:**
- Conforms to MTKViewDelegate
- Loads USDZ: MDLAsset(url:) → extract mesh → convert to Metal buffers
- Creates render pipeline with vertex/fragment shaders
- Implements draw(in:) method called every frame
- Applies basic rotation animation (optional)

**ModelIO workflow:**
1. Load USDZ: `MDLAsset(url: modelURL)`
2. Extract mesh: `MDLMesh` from asset
3. Convert to Metal: `MTKMesh(mesh:mdlMesh, device:device)`
4. Create buffers: vertex buffer, index buffer from MTKMesh

---

### Step 4: Create Metal Shaders
**File:** `Rendering/Shaders.metal`

**What it does:**
- GPU code that transforms 3D vertices and colors pixels
- Runs on GPU every frame for each vertex and pixel

**Vertex Shader:**
- Input: vertex position (float3), normal (float3), texture coord (float2)
- Transforms: model space → world space → camera space → screen space
- Uses: model matrix, view matrix, projection matrix
- Output: position (float4), normal, texture coord (passed to fragment shader)

**Fragment Shader:**
- Input: interpolated data from vertex shader
- Calculates: lighting (simple directional light)
- Output: color (float4) with alpha channel

**Basic shader structure:**
- Vertex function: transforms vertices
- Fragment function: colors pixels
- Uniform buffer: contains transformation matrices and time

---

### Step 5: Connect AppDelegate
**File:** `SummonApp.swift`

**What it does:**
- Creates window controller when app launches
- Shows the transparent window

**Implementation:**
- In `applicationDidFinishLaunching`:
  - Create OverlayWindowController instance
  - Call `showWindow(nil)` to display
  - Store reference in windowController property

---

## File Structure

```
Summon/
├── SummonApp.swift (already done)
├── Window/
│   └── OverlayWindowController.swift (NEW)
├── Rendering/
│   ├── MetalView.swift (NEW)
│   ├── ModelRenderer.swift (NEW)
│   └── Shaders.metal (NEW)
└── Resources/
    └── Black_Cat.usdz (already added)
```

---

## Technical Flow

**App Launch:**
1. AppDelegate.applicationDidFinishLaunching() called
2. OverlayWindowController creates transparent NSWindow
3. MetalView created and set as window's contentView
4. ModelRenderer loads Black_Cat.usdz
5. ModelRenderer converts USDZ to Metal buffers
6. MetalView starts render loop (60 FPS)

**Every Frame (60 times per second):**
1. MetalView prepares drawable
2. Calls ModelRenderer.draw(in:)
3. ModelRenderer creates command buffer
4. Sets up render pass
5. Binds vertex/index buffers
6. Draws triangles
7. Presents drawable to screen

---

## Success Criteria

- App builds without errors
- Transparent floating window appears on desktop
- Window stays on top of other apps
- Window can be dragged around
- Black_Cat.usdz model is visible in window
- Model renders correctly (not distorted)
- Optional: Model rotates slowly

**Scope:** This plan covers ONLY visual rendering. Speech, voice, and API integrations will be added in future phases.

---

## Implementation Order

1. Create folder structure (Window/, Rendering/)
2. Implement OverlayWindowController (transparent window)
3. Implement MetalView (Metal-backed view)
4. Implement basic ModelRenderer (load model, basic draw)
5. Create basic shaders (vertex + fragment)
6. Connect AppDelegate (create window on launch)
7. Test and debug
8. Add rotation animation (optional polish)

**Stop here** - Once the model is visible and rendering correctly, this phase is complete.

