//
//  ModelRenderer.swift
//  Summon
//
//  Created by Miguel Garcia on 11/8/25.
//

import MetalKit
import ModelIO
import simd
import SceneKit

struct Uniforms {
    var modelMatrix: float4x4
    var viewMatrix: float4x4
    var projectionMatrix: float4x4
    var normalMatrix: float4x4  // For correct normal transformation
    var time: Float
    var emissionIntensity: Float  // Controls glow brightness (0.0 = normal, 1.0+ = brighter)
    var _padding: SIMD2<Float> = SIMD2<Float>(0, 0) // Padding to align to 16 bytes
}

class ModelRenderer: NSObject, MTKViewDelegate {
    
    let device: MTLDevice
    let commandQueue: MTLCommandQueue
    var renderPipelineState: MTLRenderPipelineState?
    var vertexBuffers: [MTLBuffer] = []  // Store all vertex buffers
    var vertexBufferOffsets: [Int] = []  // Store all offsets
    var indexBuffer: MTLBuffer?
    var indexCount: Int = 0
    var indexType: MTLIndexType = .uint32
    var uniformsBuffer: MTLBuffer?
    var meshVertexDescriptor: MTLVertexDescriptor?
    var baseColorTexture: MTLTexture?  // Base color/albedo texture
    var emissionTexture: MTLTexture?  // Emission texture for glowing parts
    var metallicTexture: MTLTexture?  // Metallic map
    var roughnessTexture: MTLTexture?  // Roughness map
    var normalTexture: MTLTexture?  // Normal map for surface details
    var occlusionTexture: MTLTexture?  // Ambient occlusion
    var defaultWhiteTexture: MTLTexture?  // Default 1x1 white texture
    var defaultBlackTexture: MTLTexture?  // Default 1x1 black texture
    var defaultNormalTexture: MTLTexture?  // Default normal map (0.5, 0.5, 1.0)
    var modelURL: URL?  // Store USDZ file path for texture extraction
    
    var time: Float = 0.0
    weak var view: MTKView?
    
    // Emission glow control
    var isSpeaking: Bool = false {
        didSet {
            print("✨ ModelRenderer.isSpeaking changed: \(oldValue) -> \(isSpeaking), glowIntensity: \(glowIntensity)")
        }
    }
    private var glowIntensity: Float = 1.0
    
    // Test quad for debug rendering
    var testQuadVertexBuffer: MTLBuffer?
    var testQuadIndexBuffer: MTLBuffer?
    
    // Model bounding box and scaling
    var modelBoundingBoxMin: SIMD3<Float> = SIMD3<Float>(Float.infinity, Float.infinity, Float.infinity)
    var modelBoundingBoxMax: SIMD3<Float> = SIMD3<Float>(-Float.infinity, -Float.infinity, -Float.infinity)
    
    // 🎭 Animation inspection function
    func inspectAnimations(asset: MDLAsset) {
        print("📋 Total objects in asset: \(asset.count)")
        
        // Check asset-level animations
        let animationCount = asset.animations.count
        if animationCount > 0 {
            print("✅ Found \(animationCount) animation objects at asset level")
            // Note: MDLObjectContainerComponent doesn't provide direct iteration
            // We'll check for animations in the object hierarchy instead
        } else {
            print("ℹ️  No asset-level animation container objects found")
        }
        
        // Traverse all objects recursively
        var objectQueue: [(MDLObject, Int)] = [(asset.object(at: 0), 0)]
        var objectIndex = 0
        
        while !objectQueue.isEmpty {
            let (obj, level) = objectQueue.removeFirst()
            let indent = String(repeating: "  ", count: level)
            
            print("\(indent)📦 Object \(objectIndex): \(type(of: obj))")
            print("\(indent)   Name: \(obj.name)")
            
            // Check for skeletal structure
            if let mesh = obj as? MDLMesh {
                print("\(indent)   ✅ Is MDLMesh with \(mesh.vertexCount) vertices")
                
                // Check for morph targets (blend shapes)
                // Note: MDLMesh doesn't expose morph targets directly in older APIs
            }
            
            // Check for transform animations
            if let transform = obj.transform {
                print("\(indent)   Transform found")
                // Check if transform has keyframes
            }
            
            // Check children
            let children = obj.children.objects
            if !children.isEmpty {
                print("\(indent)   Children: \(children.count)")
                for child in children {
                    objectQueue.append((child, level + 1))
                }
            }
            
            objectIndex += 1
        }
        
        print("🔍 Animation inspection complete\n")
    }
    var modelScale: Float = 1.0
    var modelCenter: SIMD3<Float> = SIMD3<Float>(0, 0, 0)
    var depthStencilState: MTLDepthStencilState?

    
    init(device: MTLDevice, view: MTKView) {
        self.device = device
        self.view = view
        
        guard let commandQueue = device.makeCommandQueue() else {
            fatalError("Could not create command queue")
        }
        self.commandQueue = commandQueue
        
        super.init()
        
        // Create uniforms buffer
        uniformsBuffer = device.makeBuffer(length: MemoryLayout<Uniforms>.size, options: [])
        
        // Create default white texture for models without textures
        createDefaultTexture()
        
        // Create test quad for debug rendering
        createTestQuad(device: device)
        
        // Load model first to get vertex descriptor
        loadModel()
        
        // Then setup pipeline with correct vertex descriptor
        setupRenderPipeline(view: view)
    }
    
    func createTestQuad(device: MTLDevice) {
        // Create a simple colored quad for testing
        let quadVertices: [Float] = [
            // Position (x, y, z), Color (r, g, b, a)
            -0.5, -0.5, 0.0,  1.0, 0.0, 0.0, 1.0,  // Bottom-left (red)
             0.5, -0.5, 0.0,  0.0, 1.0, 0.0, 1.0,  // Bottom-right (green)
             0.5,  0.5, 0.0,  0.0, 0.0, 1.0, 1.0,  // Top-right (blue)
            -0.5,  0.5, 0.0,  1.0, 1.0, 0.0, 1.0,  // Top-left (yellow)
        ]
        
        let quadIndices: [UInt16] = [
            0, 1, 2,  // First triangle
            2, 3, 0   // Second triangle
        ]
        
        testQuadVertexBuffer = device.makeBuffer(bytes: quadVertices, 
                                                 length: quadVertices.count * MemoryLayout<Float>.size,
                                                 options: [])
        testQuadIndexBuffer = device.makeBuffer(bytes: quadIndices,
                                                length: quadIndices.count * MemoryLayout<UInt16>.size,
                                                options: [])
        
        print("✅ Test quad created for debug rendering")
        NSLog("✅ Test quad created for debug rendering")
    }
    
    func createDefaultTexture() {
        // Create a 1x1 white texture as fallback for models without textures
        let descriptor = MTLTextureDescriptor()
        descriptor.pixelFormat = .rgba8Unorm
        descriptor.width = 1
        descriptor.height = 1
        descriptor.usage = [.shaderRead]
        
        guard let whiteTexture = device.makeTexture(descriptor: descriptor) else {
            print("⚠️ Failed to create default white texture")
            return
        }
        
        // Fill with white color
        let white: [UInt8] = [255, 255, 255, 255]
        whiteTexture.replace(region: MTLRegionMake2D(0, 0, 1, 1),
                            mipmapLevel: 0,
                            withBytes: white,
                            bytesPerRow: 4)
        
        defaultWhiteTexture = whiteTexture
        print("✅ Default white texture created")
        NSLog("✅ Default white texture created")
        
        // Create a 1x1 black texture for emission fallback (no glow)
        guard let blackTexture = device.makeTexture(descriptor: descriptor) else {
            print("⚠️ Failed to create default black texture")
            return
        }
        
        // Fill with black color (no emission)
        let black: [UInt8] = [0, 0, 0, 255]
        blackTexture.replace(region: MTLRegionMake2D(0, 0, 1, 1),
                            mipmapLevel: 0,
                            withBytes: black,
                            bytesPerRow: 4)
        
        defaultBlackTexture = blackTexture
        print("✅ Default black texture created")
        NSLog("✅ Default black texture created")
        
        // Create a 1x1 normal map texture (pointing up: RGB 128,128,255 = normalized (0,0,1))
        guard let normalTexture = device.makeTexture(descriptor: descriptor) else {
            print("⚠️ Failed to create default normal texture")
            return
        }
        
        let normalUp: [UInt8] = [128, 128, 255, 255]  // (0.5, 0.5, 1.0) in 0-255 range
        normalTexture.replace(region: MTLRegionMake2D(0, 0, 1, 1),
                             mipmapLevel: 0,
                             withBytes: normalUp,
                             bytesPerRow: 4)
        
        defaultNormalTexture = normalTexture
        print("✅ Default normal texture created")
        NSLog("✅ Default normal texture created")
    }
    
    func setupRenderPipeline(view: MTKView) {
        guard let library = device.makeDefaultLibrary() else {
            fatalError("Could not create Metal library")
        }
        
        let vertexFunction = library.makeFunction(name: "vertex_main")
        let fragmentFunction = library.makeFunction(name: "fragment_main")
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        
        // Use mesh's vertex descriptor if available, otherwise use a default one
        if let meshVertexDescriptor = meshVertexDescriptor {
            pipelineDescriptor.vertexDescriptor = meshVertexDescriptor
            print("✅ Using vertex descriptor from USDZ model")
            NSLog("✅ Using vertex descriptor from USDZ model")
        } else {
            // Fallback vertex descriptor - matches shader expectations:
            // VertexIn { float3 position [[attribute(0)]]; float3 normal [[attribute(1)]]; float2 texCoord [[attribute(2)]] }
            print("⚠️ Using fallback vertex descriptor (model didn't provide one)")
            NSLog("⚠️ Using fallback vertex descriptor (model didn't provide one)")
            
            let vertexDescriptor = MTLVertexDescriptor()
            
            // Attribute 0: Position (float3) at offset 0
            vertexDescriptor.attributes[0].format = .float3
            vertexDescriptor.attributes[0].offset = 0
            vertexDescriptor.attributes[0].bufferIndex = 0
            
            // Attribute 1: Normal (float3) at offset 12 (3 floats * 4 bytes)
            vertexDescriptor.attributes[1].format = .float3
            vertexDescriptor.attributes[1].offset = MemoryLayout<Float>.size * 3
            vertexDescriptor.attributes[1].bufferIndex = 0
            
            // Attribute 2: TexCoord (float2) at offset 24 (6 floats * 4 bytes)
            vertexDescriptor.attributes[2].format = .float2
            vertexDescriptor.attributes[2].offset = MemoryLayout<Float>.size * 6
            vertexDescriptor.attributes[2].bufferIndex = 0
            
            // Layout: stride of 32 bytes (8 floats: 3 pos + 3 normal + 2 texCoord)
            vertexDescriptor.layouts[0].stride = MemoryLayout<Float>.size * 8
            vertexDescriptor.layouts[0].stepRate = 1
            vertexDescriptor.layouts[0].stepFunction = .perVertex
            
            pipelineDescriptor.vertexDescriptor = vertexDescriptor
        }
        
        pipelineDescriptor.colorAttachments[0].pixelFormat = view.colorPixelFormat
        pipelineDescriptor.colorAttachments[0].isBlendingEnabled = true
        pipelineDescriptor.colorAttachments[0].rgbBlendOperation = .add
        pipelineDescriptor.colorAttachments[0].alphaBlendOperation = .add
        pipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        pipelineDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha
        pipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        pipelineDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
        // Configure depth buffer
        pipelineDescriptor.depthAttachmentPixelFormat = .depth32Float

        // Create depth stencil state
        let depthStencilDescriptor = MTLDepthStencilDescriptor()
        depthStencilDescriptor.depthCompareFunction = .less
        depthStencilDescriptor.isDepthWriteEnabled = true
        depthStencilState = device.makeDepthStencilState(descriptor: depthStencilDescriptor)

        
        do {
            renderPipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch {
            fatalError("Could not create render pipeline state: \(error)")
        }
    }
    
    func loadModel() {
        print("🔍 Starting model load...")
        NSLog("🔍 Starting model load...")
        
        // Load the Poddy robot USDZ model
        guard let modelURL = Bundle.main.url(forResource: "Poddy_M1_-_Stylized_Floating_Robot_-_Posed", withExtension: "usdz") else {
            print("❌ ERROR: Could not find Poddy USDZ in bundle")
            NSLog("❌ ERROR: Could not find Poddy USDZ in bundle")
            print("   Bundle path: \(Bundle.main.bundlePath)")
            NSLog("   Bundle path: %@", Bundle.main.bundlePath)
            return
        }
        
        print("✅ Found model at: \(modelURL.path)")
        NSLog("✅ Found model at: %@", modelURL.path)
        
        // Store USDZ file path for texture extraction
        self.modelURL = modelURL
        
        // Create a Metal-compatible allocator for the mesh buffers
        let allocator = MTKMeshBufferAllocator(device: device)
        
        // Load USDZ asset
        let asset = MDLAsset(url: modelURL, vertexDescriptor: nil, bufferAllocator: allocator)
        
        guard asset.count > 0 else {
            print("❌ ERROR: USDZ asset is empty (count: \(asset.count))")
            NSLog("❌ ERROR: USDZ asset is empty (count: %d)", asset.count)
            return
        }
        
        print("✅ Asset loaded with \(asset.count) objects")
        NSLog("✅ Asset loaded with %d objects", asset.count)
        
        // 🔍 INSPECT ANIMATIONS IN THE MODEL
        print("\n🎭 Inspecting USDZ for animations and poses...")
        inspectAnimations(asset: asset)
        
        // Get the first object and check if it's a mesh or contains meshes
        let rootObject = asset.object(at: 0)
        print("Root object type: \(type(of: rootObject))")
        NSLog("Root object type: %@", String(describing: type(of: rootObject)))
        
        var mesh: MDLMesh?
        
        // Try direct cast first
        if let mdlMesh = rootObject as? MDLMesh {
            mesh = mdlMesh
            print("✅ Root object is directly a mesh")
        } else {
            // Search children recursively
            var queue: [MDLObject] = [rootObject]
            while !queue.isEmpty && mesh == nil {
                let current = queue.removeFirst()
                
                if let mdlMesh = current as? MDLMesh {
                    mesh = mdlMesh
                    print("✅ Found mesh in hierarchy")
                    break
                }
                
                // Add children to queue
                let children = current.children
                let childObjects = children.objects
                for child in childObjects {
                    queue.append(child)
                }
            }
        }
        
        guard let object = mesh else {
            print("❌ ERROR: Could not find any mesh in USDZ (searched entire hierarchy)")
            NSLog("❌ ERROR: Could not find any mesh in USDZ")
            return
        }
        
        print("✅ Mesh extracted: \(object.vertexCount) vertices")
        NSLog("✅ Mesh extracted: %d vertices", object.vertexCount)
        
        // Calculate bounding box from MDLMesh (before conversion)
        calculateBoundingBox(from: object)
        
        // Ensure the mesh has texture coordinates - add if missing
        if object.vertexAttributeData(forAttributeNamed: MDLVertexAttributeTextureCoordinate) == nil {
            print("⚠️ Adding default texture coordinates to mesh")
            NSLog("⚠️ Adding default texture coordinates to mesh")
            
            // Create texture coordinate data (simple planar mapping)
            let vertexCount = object.vertexCount
            var texCoords = [SIMD2<Float>](repeating: SIMD2<Float>(0, 0), count: vertexCount)
            
            // Generate simple UV coordinates (0-1 range)
            for i in 0..<vertexCount {
                let u = Float(i % 100) / 100.0
                let v = Float(i / 100) / 100.0
                texCoords[i] = SIMD2<Float>(u, v)
            }
            
            let texCoordData = Data(bytes: texCoords, count: texCoords.count * MemoryLayout<SIMD2<Float>>.size)
            let texCoordBuffer = allocator.newBuffer(with: texCoordData, type: .vertex)
            
            object.addAttribute(withName: MDLVertexAttributeTextureCoordinate, format: .float2)
            object.vertexBuffers[1] = texCoordBuffer
        }
        
        // Convert MDLMesh to MTKMesh
        do {
            let metalKitMesh = try MTKMesh(mesh: object, device: device)
            
            // Store vertex descriptor for pipeline setup
            // This converts the ModelIO vertex descriptor to a Metal-compatible one
            // The USDZ model should provide: position (float3), normal (float3), texCoord (float2)
            meshVertexDescriptor = MTKMetalVertexDescriptorFromModelIO(metalKitMesh.vertexDescriptor)
            
            print("✅ Vertex descriptor from model:")
            NSLog("✅ Vertex descriptor from model:")
            if let vd = meshVertexDescriptor {
                for i in 0..<3 {
                    if let attr = vd.attributes[i] {
                        print("   Attribute \(i): format=\(attr.format.rawValue), offset=\(attr.offset), bufferIndex=\(attr.bufferIndex)")
                        NSLog("   Attribute %d: format=%lu, offset=%lu, bufferIndex=%lu", i, attr.format.rawValue, attr.offset, attr.bufferIndex)
                    } else {
                        print("   Attribute \(i): not present")
                        NSLog("   Attribute %d: not present", i)
                    }
                }
            }
            
            // Get vertex and index buffers from the first submesh
            guard !metalKitMesh.vertexBuffers.isEmpty,
                  let submesh = metalKitMesh.submeshes.first else {
                print("❌ ERROR: Mesh has no vertex buffers or submeshes")
                NSLog("❌ ERROR: Mesh has no vertex buffers or submeshes")
                print("   Vertex buffers: \(metalKitMesh.vertexBuffers.count)")
                NSLog("   Vertex buffers: %d", metalKitMesh.vertexBuffers.count)
                print("   Submeshes: \(metalKitMesh.submeshes.count)")
                NSLog("   Submeshes: %d", metalKitMesh.submeshes.count)
                return
            }
            
            // Store ALL vertex buffers and their offsets
            vertexBuffers = metalKitMesh.vertexBuffers.map { $0.buffer }
            vertexBufferOffsets = metalKitMesh.vertexBuffers.map { $0.offset }
            
            indexBuffer = submesh.indexBuffer.buffer
            indexCount = submesh.indexCount
            indexType = submesh.indexType
            
            print("   - Vertex buffers count: \(vertexBuffers.count)")
            NSLog("   - Vertex buffers count: %d", vertexBuffers.count)
            
            // Try to load texture from the mesh material
            loadTexture(from: object)
            
            print("✅ SUCCESS: Model loaded!")
            NSLog("✅ SUCCESS: Model loaded!")
            print("   - Index count: \(indexCount)")
            NSLog("   - Index count: %d", indexCount)
            print("   - Index type: \(indexType)")
            NSLog("   - Index type: %@", String(describing: indexType))
            let totalVertexBufferSize = vertexBuffers.reduce(0) { $0 + $1.length }
            print("   - Total vertex buffer size: \(totalVertexBufferSize) bytes")
            NSLog("   - Total vertex buffer size: %d bytes", totalVertexBufferSize)
            print("   - Index buffer size: \(indexBuffer?.length ?? 0) bytes")
            NSLog("   - Index buffer size: %d bytes", indexBuffer?.length ?? 0)
            print("   - Bounding box min: (\(modelBoundingBoxMin.x), \(modelBoundingBoxMin.y), \(modelBoundingBoxMin.z))")
            NSLog("   - Bounding box min: (%f, %f, %f)", modelBoundingBoxMin.x, modelBoundingBoxMin.y, modelBoundingBoxMin.z)
            print("   - Bounding box max: (\(modelBoundingBoxMax.x), \(modelBoundingBoxMax.y), \(modelBoundingBoxMax.z))")
            NSLog("   - Bounding box max: (%f, %f, %f)", modelBoundingBoxMax.x, modelBoundingBoxMax.y, modelBoundingBoxMax.z)
            print("   - Model center: (\(modelCenter.x), \(modelCenter.y), \(modelCenter.z))")
            NSLog("   - Model center: (%f, %f, %f)", modelCenter.x, modelCenter.y, modelCenter.z)
            print("   - Model scale: \(modelScale)")
            NSLog("   - Model scale: %f", modelScale)
        } catch {
            print("❌ ERROR: Could not convert mesh to Metal: \(error)")
            NSLog("❌ ERROR: Could not convert mesh to Metal: %@", error.localizedDescription)
        }
    }
    
    func calculateBoundingBox(from mesh: MDLMesh) {
        // Reset bounding box
        modelBoundingBoxMin = SIMD3<Float>(Float.infinity, Float.infinity, Float.infinity)
        modelBoundingBoxMax = SIMD3<Float>(-Float.infinity, -Float.infinity, -Float.infinity)
        
        // Try to get bounding box from MDLMesh
        let boundingBox = mesh.boundingBox
        let minBounds = boundingBox.minBounds
        let maxBounds = boundingBox.maxBounds
        
        // Check if bounding box is valid (not all zeros/infinity)
        if maxBounds.x > minBounds.x && maxBounds.y > minBounds.y && maxBounds.z > minBounds.z {
            modelBoundingBoxMin = SIMD3<Float>(Float(minBounds.x), Float(minBounds.y), Float(minBounds.z))
            modelBoundingBoxMax = SIMD3<Float>(Float(maxBounds.x), Float(maxBounds.y), Float(maxBounds.z))
        } else {
            // Fallback: iterate through vertices
            guard let vertexBuffer = mesh.vertexAttributeData(forAttributeNamed: MDLVertexAttributePosition) else {
                print("⚠️ WARNING: Cannot calculate bounding box - missing vertex position data")
                NSLog("⚠️ WARNING: Cannot calculate bounding box - missing vertex position data")
                return
            }
            
            let vertexCount = mesh.vertexCount
            let dataStart = vertexBuffer.dataStart.assumingMemoryBound(to: SIMD3<Float>.self)
            
            for i in 0..<vertexCount {
                let position = dataStart[i]
                
                modelBoundingBoxMin = SIMD3<Float>(
                    min(modelBoundingBoxMin.x, position.x),
                    min(modelBoundingBoxMin.y, position.y),
                    min(modelBoundingBoxMin.z, position.z)
                )
                modelBoundingBoxMax = SIMD3<Float>(
                    max(modelBoundingBoxMax.x, position.x),
                    max(modelBoundingBoxMax.y, position.y),
                    max(modelBoundingBoxMax.z, position.z)
                )
            }
        }
        
        // Calculate center
        modelCenter = (modelBoundingBoxMin + modelBoundingBoxMax) * 0.5
        
        // Calculate size and scale to fit viewport (target size: ~3 units for smaller model)
        let size = modelBoundingBoxMax - modelBoundingBoxMin
        let maxDimension = max(size.x, max(size.y, size.z))
        if maxDimension > 0 {
            modelScale = 3.0 / maxDimension  // Scale to fit in ~3 unit cube (smaller)
        } else {
            modelScale = 1.0
        }
    }
    
    func loadTexture(from mesh: MDLMesh) {
        print("🎨 Attempting to load textures from mesh...")
        NSLog("🎨 Attempting to load textures from mesh...")
        
        // Check if mesh has submeshes with materials
        guard let submeshes = mesh.submeshes as? [MDLSubmesh],
              let firstSubmesh = submeshes.first,
              let material = firstSubmesh.material else {
            print("⚠️ No material found in mesh")
            NSLog("⚠️ No material found in mesh")
            return
        }
        
        print("✅ Found material: \(material.name)")
        NSLog("✅ Found material: %@", material.name)
        
        // Extract ALL PBR textures using the unified extraction method
        extractMaterialTexture(from: material, semantic: .baseColor, name: "base color") { texture in
            self.baseColorTexture = texture
        }
        
        extractMaterialTexture(from: material, semantic: .emission, name: "emission") { texture in
            self.emissionTexture = texture
        }
        
        extractMaterialTexture(from: material, semantic: .metallic, name: "metallic") { texture in
            self.metallicTexture = texture
        }
        
        extractMaterialTexture(from: material, semantic: .roughness, name: "roughness") { texture in
            self.roughnessTexture = texture
        }
        
        extractMaterialTexture(from: material, semantic: .tangentSpaceNormal, name: "normal") { texture in
            self.normalTexture = texture
        }
        
        extractMaterialTexture(from: material, semantic: .ambientOcclusion, name: "occlusion") { texture in
            self.occlusionTexture = texture
        }
        
        // Check for solid base color if no texture was loaded
        if baseColorTexture == nil {
            if let baseColorProperty = material.property(with: .baseColor),
               baseColorProperty.type == .color {
                let color = baseColorProperty.float3Value
                print("   Base color is solid: RGB(\(color.x), \(color.y), \(color.z))")
                NSLog("   Base color is solid: RGB(%f, %f, %f)", color.x, color.y, color.z)
            }
        }
    }
    
    func extractMaterialTexture(from material: MDLMaterial, semantic: MDLMaterialSemantic, name: String, completion: (MTLTexture) -> Void) {
        guard let property = material.property(with: semantic) else {
            print("   ⚠️ No \(name) property found")
            NSLog("   ⚠️ No %@ property found", name)
            return
        }
        
        print("   🎨 Found \(name) property, type: \(property.type)")
        NSLog("   🎨 Found %@ property, type: %ld", name, property.type.rawValue)
        
        if let stringValue = property.stringValue,
           let usdzURL = modelURL,
           let bracketStart = stringValue.firstIndex(of: "["),
           let bracketEnd = stringValue.firstIndex(of: "]") {
            
            let texturePathInZip = String(stringValue[stringValue.index(after: bracketStart)..<bracketEnd])
            print("   📦 Extracting \(name) texture: \(texturePathInZip)")
            NSLog("   📦 Extracting %@ texture: %@", name, texturePathInZip)
            
            if let texture = extractTextureFromUSDZ(usdzPath: usdzURL, texturePath: texturePathInZip) {
                completion(texture)
                print("✅ \(name.capitalized) texture loaded!")
                NSLog("✅ %@ texture loaded!", name.capitalized)
            }
        }
    }
    
    func extractTextureFromUSDZ(usdzPath: URL, texturePath: String) -> MTLTexture? {
        print("   🔓 Extracting texture from USDZ: \(texturePath)")
        NSLog("   🔓 Extracting texture from USDZ: %@", texturePath)
        
        // 1. Create temporary directory
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        
        do {
            // Create temp directory
            try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
            print("   📁 Created temp directory: \(tempDir.path)")
            NSLog("   📁 Created temp directory: %@", tempDir.path)
            
            // 2. Unzip USDZ (it's a ZIP archive) - extract specific texture file
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/unzip")
            process.arguments = ["-q", "-o", usdzPath.path, texturePath, "-d", tempDir.path]
            
            // Capture error output for debugging
            let errorPipe = Pipe()
            process.standardError = errorPipe
            
            // 3. Run unzip command
            try process.run()
            process.waitUntilExit()
            
            if process.terminationStatus != 0 {
                let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
                let errorOutput = String(data: errorData, encoding: .utf8) ?? "Unknown error"
                print("   ❌ Unzip failed with status \(process.terminationStatus): \(errorOutput)")
                NSLog("   ❌ Unzip failed with status %d: %@", process.terminationStatus, errorOutput)
                try? FileManager.default.removeItem(at: tempDir)
                return nil
            }
            
            print("   ✅ Unzip successful")
            NSLog("   ✅ Unzip successful")
            
            // 4. Load extracted texture
            let extractedTexturePath = tempDir.appendingPathComponent(texturePath)
            
            // Verify file exists
            guard FileManager.default.fileExists(atPath: extractedTexturePath.path) else {
                print("   ❌ Extracted texture not found at: \(extractedTexturePath.path)")
                NSLog("   ❌ Extracted texture not found at: %@", extractedTexturePath.path)
                try? FileManager.default.removeItem(at: tempDir)
                return nil
            }
            
            print("   📄 Found extracted texture at: \(extractedTexturePath.path)")
            NSLog("   📄 Found extracted texture at: %@", extractedTexturePath.path)
            
            let textureLoader = MTKTextureLoader(device: device)
            let options: [MTKTextureLoader.Option: Any] = [
                .textureUsage: MTLTextureUsage.shaderRead.rawValue,
                .generateMipmaps: false
            ]
            
            let texture = try textureLoader.newTexture(URL: extractedTexturePath, options: options)
            
            print("   ✅ Texture loaded: \(texture.width) x \(texture.height)")
            NSLog("   ✅ Texture loaded: %lu x %lu", texture.width, texture.height)
            print("   Texture pixel format: \(texture.pixelFormat.rawValue)")
            NSLog("   Texture pixel format: %lu", texture.pixelFormat.rawValue)
            
            // 5. Clean up temporary directory
            try FileManager.default.removeItem(at: tempDir)
            print("   🗑️ Cleaned up temp directory")
            NSLog("   🗑️ Cleaned up temp directory")
            
            return texture
            
        } catch {
            print("   ❌ Error extracting texture: \(error)")
            NSLog("   ❌ Error extracting texture: %@", error.localizedDescription)
            try? FileManager.default.removeItem(at: tempDir)
            return nil
        }
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        // Handle resize if needed
    }
    
    func draw(in view: MTKView) {
        guard let renderPipelineState = renderPipelineState,
              let drawable = view.currentDrawable,
              let renderPassDescriptor = view.currentRenderPassDescriptor else {
            return
        }
        
        // Check if model is loaded
        guard !vertexBuffers.isEmpty,
              let indexBuffer = indexBuffer, 
              indexCount > 0 else {
            // Model not loaded - render test quad instead
            renderTestQuad(in: view, descriptor: renderPassDescriptor)
            return
        }
        
        // Update time for rotation
        time += 0.016 // ~60 FPS
        
        // Update glow intensity - pulse when speaking
        if isSpeaking {
            // Pulse between 1.5 and 3.0 while speaking
            let newIntensity = 2.25 + sin(time * 6.0) * 0.75
            if abs(glowIntensity - newIntensity) > 0.5 {
                print("🔥 Speaking - pulsing glow: \(newIntensity)")
            }
            glowIntensity = newIntensity
        } else {
            // Smoothly fade back to normal (1.0)
            glowIntensity = glowIntensity * 0.95 + 1.0 * 0.05
        }
        
        // Fix aspect ratio calculation - handle zero/negative bounds
        let viewWidth = max(view.bounds.width, 1.0)
        let viewHeight = max(view.bounds.height, 1.0)
        var aspectRatio = Float(viewWidth / viewHeight)
        
        // Safety check: ensure aspect ratio is valid
        if aspectRatio <= 0 || !aspectRatio.isFinite {
            aspectRatio = 1.0
            print("⚠️ WARNING: Invalid aspect ratio, defaulting to 1.0")
            NSLog("⚠️ WARNING: Invalid aspect ratio, defaulting to 1.0")
        }
        
        if view.bounds.width <= 0 || view.bounds.height <= 0 {
            print("⚠️ WARNING: Invalid view bounds: width=\(view.bounds.width), height=\(view.bounds.height)")
            NSLog("⚠️ WARNING: Invalid view bounds: width=%f, height=%f", view.bounds.width, view.bounds.height)
        }
        
        // Calculate camera distance based on model size
        // Model is centered at origin after transformation, so camera looks at (0,0,0)
        let cameraDistance: Float = 10.0  // Increased for larger model
        let cameraPosition = SIMD3<Float>(0, 0, cameraDistance)
        let targetPosition = SIMD3<Float>(0, 0, 0)  // Look at origin (where model is centered)
        
        // Create look-at view matrix
        let viewMatrix = float4x4(lookAt: cameraPosition, target: targetPosition, up: SIMD3<Float>(0, 1, 0))
        
        // Create model matrix: scale first, then translate scaled model to origin, then move down
        // Matrix multiplication applies transformations in REVERSE order to vertices
        var modelMatrix = float4x4(scale: modelScale)  // Scale first
        modelMatrix = modelMatrix * float4x4(translation: -modelCenter * modelScale)  // Translate the SCALED model to origin
        modelMatrix = modelMatrix * float4x4(translation: SIMD3<Float>(0, -1.5, 0))  // Move down by 1.5 units
        // modelMatrix = modelMatrix * float4x4(rotationY: time * 0.5)  // Rotation disabled
        
        
        let projectionMatrix = float4x4(perspectiveProjectionFov: Float.pi / 4,
                                        aspectRatio: aspectRatio,
                                        nearZ: 0.1,
                                        farZ: 100.0)
        
        // Calculate normal matrix (inverse transpose of model matrix)
        // This ensures normals are transformed correctly even with non-uniform scaling
        let normalMatrix = modelMatrix.inverse.transpose
        
        // Update uniforms
        var uniforms = Uniforms(
            modelMatrix: modelMatrix,
            viewMatrix: viewMatrix,
            projectionMatrix: projectionMatrix,
            normalMatrix: normalMatrix,
            time: time,
            emissionIntensity: glowIntensity
        )
        uniformsBuffer?.contents().copyMemory(from: &uniforms, byteCount: MemoryLayout<Uniforms>.size)
        
        guard let commandBuffer = commandQueue.makeCommandBuffer(),
              let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
            return
        }
        
        renderEncoder.setRenderPipelineState(renderPipelineState)
        renderEncoder.setCullMode(.none)  // Disable backface culling to see all triangles
        
        // Enable depth testing
        if let depthStencilState = depthStencilState {
            renderEncoder.setDepthStencilState(depthStencilState)
        }
        
        // Bind ALL vertex buffers from the model (even if shader doesn't use them all)
        // Metal validation requires all buffers referenced in vertex descriptor to be bound
        for (index, buffer) in vertexBuffers.enumerated() {
            let offset = index < vertexBufferOffsets.count ? vertexBufferOffsets[index] : 0
            renderEncoder.setVertexBuffer(buffer, offset: offset, index: index)
        }
        
        // Bind uniforms buffer at a fixed high index to avoid conflicts with any model's vertex buffers
        if let uniformsBuffer = uniformsBuffer {
            renderEncoder.setVertexBuffer(uniformsBuffer, offset: 0, index: 10)
        }
        
        // Bind ALL textures with proper fallbacks
        renderEncoder.setFragmentTexture(baseColorTexture ?? defaultWhiteTexture, index: 0)
        renderEncoder.setFragmentTexture(emissionTexture ?? defaultBlackTexture, index: 1)
        renderEncoder.setFragmentTexture(metallicTexture ?? defaultBlackTexture, index: 2)
        renderEncoder.setFragmentTexture(roughnessTexture ?? defaultWhiteTexture, index: 3)
        renderEncoder.setFragmentTexture(normalTexture ?? defaultNormalTexture, index: 4)
        renderEncoder.setFragmentTexture(occlusionTexture ?? defaultWhiteTexture, index: 5)
        
        // We already checked indexBuffer exists in the guard above (it's now a local non-optional variable)
        renderEncoder.drawIndexedPrimitives(
            type: .triangle,
            indexCount: indexCount,
            indexType: indexType,
            indexBuffer: indexBuffer,
            indexBufferOffset: 0
        )
    
        renderEncoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
    
    func renderTestQuad(in view: MTKView, descriptor: MTLRenderPassDescriptor) {
        guard let renderPipelineState = renderPipelineState,
              let drawable = view.currentDrawable,
              let testQuadVertexBuffer = testQuadVertexBuffer,
              let testQuadIndexBuffer = testQuadIndexBuffer else {
            print("⚠️ WARNING: Cannot render test quad - missing resources")
            NSLog("⚠️ WARNING: Cannot render test quad - missing resources")
            return
        }
        
        guard let commandBuffer = commandQueue.makeCommandBuffer(),
              let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else {
            print("⚠️ WARNING: Cannot create command buffer/encoder for test quad")
            NSLog("⚠️ WARNING: Cannot create command buffer/encoder for test quad")
            return
        }
        
        // Simple identity matrices for test quad
        let modelMatrix = float4x4.identity
        let viewMatrix = float4x4(translation: [0, 0, -2])
        
        let viewWidth = max(view.bounds.width, 1.0)
        let viewHeight = max(view.bounds.height, 1.0)
        var aspectRatio = Float(viewWidth / viewHeight)
        
        // Safety check: ensure aspect ratio is valid
        if aspectRatio <= 0 || !aspectRatio.isFinite {
            aspectRatio = 1.0
        }
        
        let projectionMatrix = float4x4(perspectiveProjectionFov: Float.pi / 4,
                                        aspectRatio: aspectRatio,
                                        nearZ: 0.1,
                                        farZ: 100.0)
        
        // Calculate normal matrix (for identity model matrix, it's also identity)
        let normalMatrix = modelMatrix.inverse.transpose
        
        var uniforms = Uniforms(
            modelMatrix: modelMatrix,
            viewMatrix: viewMatrix,
            projectionMatrix: projectionMatrix,
            normalMatrix: normalMatrix,
            time: time,
            emissionIntensity: glowIntensity
        )
        uniformsBuffer?.contents().copyMemory(from: &uniforms, byteCount: MemoryLayout<Uniforms>.size)
        
        renderEncoder.setRenderPipelineState(renderPipelineState)
        renderEncoder.setVertexBuffer(testQuadVertexBuffer, offset: 0, index: 0)
        if let uniformsBuffer = uniformsBuffer {
            renderEncoder.setVertexBuffer(uniformsBuffer, offset: 0, index: 10)
        }
        
        renderEncoder.drawIndexedPrimitives(
            type: .triangle,
            indexCount: 6,
            indexType: .uint16,
            indexBuffer: testQuadIndexBuffer,
            indexBufferOffset: 0
        )
        
        renderEncoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}

// Matrix helper functions
extension float4x4 {
    static var identity: float4x4 {
        return float4x4(
            SIMD4<Float>(1, 0, 0, 0),
            SIMD4<Float>(0, 1, 0, 0),
            SIMD4<Float>(0, 0, 1, 0),
            SIMD4<Float>(0, 0, 0, 1)
        )
    }
    
    init(translation: SIMD3<Float>) {
        self.init(
            SIMD4<Float>(1, 0, 0, 0),
            SIMD4<Float>(0, 1, 0, 0),
            SIMD4<Float>(0, 0, 1, 0),
            SIMD4<Float>(translation.x, translation.y, translation.z, 1)
        )
    }
    
    init(scale: Float) {
        self.init(
            SIMD4<Float>(scale, 0, 0, 0),
            SIMD4<Float>(0, scale, 0, 0),
            SIMD4<Float>(0, 0, scale, 0),
            SIMD4<Float>(0, 0, 0, 1)
        )
    }
    
    init(rotationY angle: Float) {
        let c = cos(angle)
        let s = sin(angle)
        self.init(
            SIMD4<Float>(c, 0, s, 0),
            SIMD4<Float>(0, 1, 0, 0),
            SIMD4<Float>(-s, 0, c, 0),
            SIMD4<Float>(0, 0, 0, 1)
        )
    }
    
    init(lookAt eye: SIMD3<Float>, target: SIMD3<Float>, up: SIMD3<Float>) {
        let zAxis = normalize(eye - target)
        let xAxis = normalize(cross(up, zAxis))
        let yAxis = cross(zAxis, xAxis)
        
        self.init(
            SIMD4<Float>(xAxis.x, yAxis.x, zAxis.x, 0),
            SIMD4<Float>(xAxis.y, yAxis.y, zAxis.y, 0),
            SIMD4<Float>(xAxis.z, yAxis.z, zAxis.z, 0),
            SIMD4<Float>(-dot(xAxis, eye), -dot(yAxis, eye), -dot(zAxis, eye), 1)
        )
    }
    
    init(perspectiveProjectionFov fov: Float, aspectRatio: Float, nearZ: Float, farZ: Float) {
        let yScale = 1.0 / tan(fov * 0.5)
        let xScale = yScale / aspectRatio
        let zRange = farZ - nearZ
        let zScale = -(farZ + nearZ) / zRange
        let wzScale = -2.0 * farZ * nearZ / zRange
        
        self.init(
            SIMD4<Float>(xScale, 0, 0, 0),
            SIMD4<Float>(0, yScale, 0, 0),
            SIMD4<Float>(0, 0, zScale, -1),
            SIMD4<Float>(0, 0, wzScale, 0)
        )
    }
}

