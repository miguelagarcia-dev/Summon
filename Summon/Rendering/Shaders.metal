//
//  Shaders.metal
//  Summon
//
//  Created by Miguel Garcia on 11/8/25.
//

#include <metal_stdlib>
using namespace metal;

// Vertex input structure - must match the vertex descriptor from ModelRenderer
// attribute(0): position as float3 - vertex position in model space
// attribute(1): normal as float3 - surface normal for lighting
// attribute(2): texCoord as float2 - texture coordinates (UV mapping)
struct VertexIn {
    float3 position [[attribute(0)]];
    float3 normal [[attribute(1)]];
    float2 texCoord [[attribute(2)]];
};

struct VertexOut {
    float4 position [[position]];
    float3 normal;
    float2 texCoord;
};

struct Uniforms {
    float4x4 modelMatrix;
    float4x4 viewMatrix;
    float4x4 projectionMatrix;
    float4x4 normalMatrix;  // For correct normal transformation
    float time;
    float3 _padding;  // Padding to align to 16 bytes
};

vertex VertexOut vertex_main(VertexIn in [[stage_in]],
                             constant Uniforms &uniforms [[buffer(10)]]) {
    VertexOut out;
    
    // Transform position to clip space
    float4 worldPosition = uniforms.modelMatrix * float4(in.position, 1.0);
    float4 viewPosition = uniforms.viewMatrix * worldPosition;
    out.position = uniforms.projectionMatrix * viewPosition;
    
    // Transform normal using normal matrix (handles non-uniform scaling correctly)
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

