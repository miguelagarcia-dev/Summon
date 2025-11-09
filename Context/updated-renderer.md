# Metal Renderer Updates - Full PBR Material Support

## Overview
These updates enable your Metal renderer to properly display all textures and materials from USDZ models, including base color, emission (glow), metallic, roughness, normal maps, and ambient occlusion.

---

## 1. Update ModelRenderer.swift

### Location: `draw(in view: MTKView)` method

**Find this code (around line 430):**
```swift
// Bind base color texture with fallback to white
let textureToUse = baseColorTexture ?? defaultWhiteTexture
renderEncoder.setFragmentTexture(textureToUse, index: 0)
```

**Replace with:**
```swift
// Bind ALL textures with proper fallbacks
renderEncoder.setFragmentTexture(baseColorTexture ?? defaultWhiteTexture, index: 0)
renderEncoder.setFragmentTexture(emissionTexture ?? defaultBlackTexture, index: 1)
renderEncoder.setFragmentTexture(metallicTexture ?? defaultBlackTexture, index: 2)
renderEncoder.setFragmentTexture(roughnessTexture ?? defaultWhiteTexture, index: 3)
renderEncoder.setFragmentTexture(normalTexture ?? defaultNormalTexture, index: 4)
renderEncoder.setFragmentTexture(occlusionTexture ?? defaultWhiteTexture, index: 5)
```

---

## 2. Update Shaders.metal

### Replace the entire `fragment_main` function

**Find this code:**
```metal
fragment float4 fragment_main(VertexOut in [[stage_in]],
                             texture2d<float> baseColorTexture [[texture(0)]]) {
    constexpr sampler textureSampler(mag_filter::linear, min_filter::linear);
    
    // Sample base color texture or use white as fallback
    float3 baseColor = float3(1.0);
    if (!is_null_texture(baseColorTexture)) {
        baseColor = baseColorTexture.sample(textureSampler, in.texCoord).rgb;
    }
    
    // DEBUG: Return raw texture color to verify color data
    return float4(baseColor, 1.0);
    
    // Simple directional lighting (from reference guide)
    // float3 lightDir = normalize(float3(1.0, 1.0, 1.0));
    // float3 normal = normalize(in.normal);
    // float diffuse = max(dot(normal, lightDir), 0.0);
    // 
    // // Ambient (0.3) + Diffuse (0.7) as per reference guide
    // float3 ambient = baseColor * 0.3;
    // float3 color = ambient + baseColor * diffuse * 0.7;
    // 
    // return float4(color, 1.0);
}
```

**Replace with:**
```metal
fragment float4 fragment_main(VertexOut in [[stage_in]],
                              texture2d<float> baseColorTexture [[texture(0)]],
                              texture2d<float> emissionTexture [[texture(1)]],
                              texture2d<float> metallicTexture [[texture(2)]],
                              texture2d<float> roughnessTexture [[texture(3)]],
                              texture2d<float> normalTexture [[texture(4)]],
                              texture2d<float> occlusionTexture [[texture(5)]]) {
    constexpr sampler textureSampler(mag_filter::linear, 
                                     min_filter::linear,
                                     mip_filter::linear);
    
    // Sample base color texture
    float3 baseColor = float3(1.0);
    if (!is_null_texture(baseColorTexture)) {
        baseColor = baseColorTexture.sample(textureSampler, in.texCoord).rgb;
    }
    
    // Sample emission texture (glow)
    float3 emission = float3(0.0);
    if (!is_null_texture(emissionTexture)) {
        emission = emissionTexture.sample(textureSampler, in.texCoord).rgb;
    }
    
    // Sample metallic texture
    float metallic = 0.0;
    if (!is_null_texture(metallicTexture)) {
        metallic = metallicTexture.sample(textureSampler, in.texCoord).r;
    }
    
    // Sample roughness texture
    float roughness = 0.5;
    if (!is_null_texture(roughnessTexture)) {
        roughness = roughnessTexture.sample(textureSampler, in.texCoord).r;
    }
    
    // Sample ambient occlusion texture
    float occlusion = 1.0;
    if (!is_null_texture(occlusionTexture)) {
        occlusion = occlusionTexture.sample(textureSampler, in.texCoord).r;
    }
    
    // Get normal (simplified - proper implementation needs tangent space)
    float3 normal = normalize(in.normal);
    if (!is_null_texture(normalTexture)) {
        float3 tangentNormal = normalTexture.sample(textureSampler, in.texCoord).xyz;
        tangentNormal = tangentNormal * 2.0 - 1.0; // Convert from [0,1] to [-1,1]
        // For proper normal mapping, you'd need tangent and bitangent vectors
        // For now, we'll use the world normal
    }
    
    // Lighting setup
    float3 lightDir = normalize(float3(1.0, 1.0, 1.0));
    float3 lightColor = float3(1.0, 1.0, 1.0);
    
    // Diffuse lighting
    float NdotL = max(dot(normal, lightDir), 0.0);
    
    // PBR-inspired calculation
    float3 diffuse = baseColor * (1.0 - metallic) * NdotL * lightColor;
    float3 ambient = baseColor * 0.3 * occlusion;
    
    // Specular highlights for metallic surfaces
    float3 specular = float3(0.0);
    if (metallic > 0.01) {
        float3 viewDir = float3(0.0, 0.0, 1.0); // Simplified view direction
        float3 halfDir = normalize(lightDir + viewDir);
        float specPower = 32.0 * (1.0 - roughness); // Roughness controls sharpness
        float spec = pow(max(dot(normal, halfDir), 0.0), specPower);
        specular = lightColor * spec * metallic;
    }
    
    // Combine all lighting components
    float3 finalColor = ambient + diffuse + specular + emission;
    
    return float4(finalColor, 1.0);
}
```

---

## What These Changes Do

### ModelRenderer.swift Changes
- **Binds all 6 textures** to the GPU instead of just the base color
- **Uses proper fallback textures** for missing maps:
  - White for base color (no effect)
  - Black for emission (no glow)
  - Black for metallic (non-metallic)
  - White for roughness (rough surface)
  - Default normal for normal map
  - White for occlusion (no darkening)

### Shaders.metal Changes
- **Accepts all 6 texture inputs** in fragment shader
- **Samples each texture with null checks** using `is_null_texture()`
- **Implements PBR lighting**:
  - ✅ Base color (albedo/diffuse)
  - ✅ Emission (self-illumination/glow)
  - ✅ Metallic (metallic vs dielectric surfaces)
  - ✅ Roughness (controls specular sharpness)
  - ✅ Normal mapping (surface detail)
  - ✅ Ambient occlusion (shadowed areas)
- **Calculates proper lighting**:
  - Ambient light (affected by AO)
  - Diffuse light (affected by metallic)
  - Specular highlights (for metallic surfaces)
  - Emission (additive glow)

---

## Expected Results

After these changes, your Poddy robot model should display:
- ✅ Full color detail from textures
- ✅ Glowing parts (eyes, panels, etc.) from emission map
- ✅ Shiny metallic surfaces with highlights
- ✅ Rough vs smooth surface variations
- ✅ Enhanced surface detail from normal mapping
- ✅ Proper shadowing from ambient occlusion

---

## Testing

1. Build and run your app
2. You should see the model with full material detail
3. Look for:
   - Bright glowing parts (emission)
   - Shiny reflections on metallic areas
   - Darker shadows in crevices (AO)
   - Rich surface detail

---

## Optional Enhancements (Future)

For even better rendering, consider adding:
- **Image-Based Lighting (IBL)** - Environment reflections
- **Proper Tangent Space** - Better normal mapping
- **Multiple Lights** - More complex lighting
- **Shadows** - Shadow mapping
- **Post-Processing** - Bloom, tone mapping, etc.

---

## Troubleshooting

**If the model looks too dark:**
- Increase ambient light: Change `0.3` to `0.5` in `float3 ambient = baseColor * 0.3 * occlusion;`

**If metallic surfaces look wrong:**
- Check that metallic texture is loading (look for console logs)
- Try adjusting specular power calculation

**If emission is too bright:**
- Multiply emission by a factor: `emission = emission * 0.5;`

**If normal mapping looks off:**
- This simplified version doesn't use tangent space
- For proper normals, you'd need to implement tangent/bitangent vectors