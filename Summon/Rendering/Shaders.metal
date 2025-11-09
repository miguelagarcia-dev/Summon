//
//  Shaders.metal - FINAL WORKING VERSION
//  Summon
//

#include <metal_stdlib>
using namespace metal;

struct VertexIn {
    float3 position [[attribute(0)]];
    float3 normal [[attribute(1)]];
    float2 texCoord [[attribute(2)]];
};

struct VertexOut {
    float4 position [[position]];
    float3 worldPosition;
    float3 normal;
    float2 texCoord;
};

struct Uniforms {
    float4x4 modelMatrix;
    float4x4 viewMatrix;
    float4x4 projectionMatrix;
    float4x4 normalMatrix;
    float time;
    float3 _padding;
};

vertex VertexOut vertex_main(VertexIn in [[stage_in]],
                             constant Uniforms &uniforms [[buffer(10)]]) {
    VertexOut out;
    
    float4 worldPosition = uniforms.modelMatrix * float4(in.position, 1.0);
    out.worldPosition = worldPosition.xyz;
    float4 viewPosition = uniforms.viewMatrix * worldPosition;
    out.position = uniforms.projectionMatrix * viewPosition;
    
    float3x3 normalMatrix3x3 = float3x3(
        uniforms.normalMatrix.columns[0].xyz,
        uniforms.normalMatrix.columns[1].xyz,
        uniforms.normalMatrix.columns[2].xyz
    );
    out.normal = normalize(normalMatrix3x3 * in.normal);
    out.texCoord = in.texCoord;
    
    return out;
}

fragment float4 fragment_main(VertexOut in [[stage_in]],
                              texture2d<float> baseColorTexture [[texture(0)]],
                              texture2d<float> emissionTexture [[texture(1)]],
                              texture2d<float> metallicTexture [[texture(2)]],
                              texture2d<float> roughnessTexture [[texture(3)]],
                              texture2d<float> normalTexture [[texture(4)]],
                              texture2d<float> occlusionTexture [[texture(5)]]) {
    constexpr sampler textureSampler(mag_filter::linear,
                                     min_filter::linear,
                                     address::repeat);
    
    // Sample all PBR textures
    float3 baseColor = baseColorTexture.sample(textureSampler, in.texCoord).rgb;
    float3 emission = emissionTexture.sample(textureSampler, in.texCoord).rgb;
    float metallic = metallicTexture.sample(textureSampler, in.texCoord).r;
    float roughness = roughnessTexture.sample(textureSampler, in.texCoord).r;
    float occlusion = occlusionTexture.sample(textureSampler, in.texCoord).r;
    
    // CRITICAL: Apply sRGB to linear conversion for proper color space
    // The textures are in sRGB but Metal samples them as linear
    baseColor = pow(baseColor, float3(2.2));
    emission = pow(emission, float3(2.2));
    
    // Normal
    float3 normal = normalize(in.normal);
    
    // View direction
    float3 viewDir = normalize(float3(0, 0, 10.0) - in.worldPosition);
    
    float3 finalColor = float3(0.0);
    
    // ====== MUCH BRIGHTER LIGHTING SETUP ======
    
    // Key light (main directional - VERY BRIGHT)
    float3 keyLightDir = normalize(float3(1.0, 1.5, 1.0));
    float3 keyLightColor = float3(2.5, 2.5, 2.5);  // Super bright!
    float keyNdotL = max(dot(normal, keyLightDir), 0.0);
    
    // Fill light (softer from opposite side)
    float3 fillLightDir = normalize(float3(-0.5, 0.5, 0.5));
    float3 fillLightColor = float3(1.2, 1.2, 1.4);  // Slightly blue
    float fillNdotL = max(dot(normal, fillLightDir), 0.0);
    
    // Rim light (from behind)
    float3 rimLightDir = normalize(float3(0.0, 0.0, -1.0));
    float3 rimLightColor = float3(0.8, 0.8, 1.0);
    float rimNdotL = max(dot(normal, rimLightDir), 0.0);
    
    // Bottom/ambient light (so no pure black)
    float3 bottomLightDir = normalize(float3(0.0, -1.0, 0.0));
    float3 bottomLightColor = float3(0.6, 0.6, 0.7);
    float bottomNdotL = max(dot(normal, bottomLightDir), 0.0);
    
    // Diffuse contribution
    float3 diffuse = baseColor * (1.0 - metallic) * (
        keyNdotL * keyLightColor +
        fillNdotL * fillLightColor +
        rimNdotL * rimLightColor +
        bottomNdotL * bottomLightColor
    );
    
    // VERY bright ambient (so nothing is pure black)
    float3 ambient = baseColor * 1.0 * occlusion;
    
    // Specular highlights (for shiny metallic parts)
    float3 specular = float3(0.0);
    
    // Key light specular
    float3 keyHalfDir = normalize(keyLightDir + viewDir);
    float keySpecPower = mix(8.0, 256.0, 1.0 - roughness);
    float keySpec = pow(max(dot(normal, keyHalfDir), 0.0), keySpecPower);
    specular += keyLightColor * keySpec * 0.5 * mix(0.04, 1.0, metallic);
    
    // Fill light specular
    float3 fillHalfDir = normalize(fillLightDir + viewDir);
    float fillSpecPower = mix(8.0, 128.0, 1.0 - roughness);
    float fillSpec = pow(max(dot(normal, fillHalfDir), 0.0), fillSpecPower);
    specular += fillLightColor * fillSpec * 0.3 * mix(0.04, 1.0, metallic);
    
    // Fresnel effect (makes edges brighter on metals)
    float fresnel = pow(1.0 - max(dot(normal, viewDir), 0.0), 4.0);
    specular += fresnel * metallic * 0.5;
    
    // MASSIVELY boost emission (the green glow)
    emission *= 8.0;
    
    // Combine all lighting
    finalColor = ambient + diffuse + specular + emission;
    
    // Tone mapping (prevent over-bright areas)
    finalColor = finalColor / (finalColor + 1.0);
    
    // CRITICAL: Convert back from linear to sRGB for display
    finalColor = pow(finalColor, float3(1.0/2.2));
    
    return float4(finalColor, 1.0);
}
