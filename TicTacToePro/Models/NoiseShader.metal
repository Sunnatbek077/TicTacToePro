//
//  File.metal
//  TicTacToePro
//
//  Created by Sunnatbek on 01/10/25.
//

#include <metal_stdlib>
using namespace metal;

struct VertexOut {
    float4 position [[position]];
};

vertex VertexOut noiseVertexShader(uint vertexID [[vertex_id]], constant float2* vertices [[buffer(0)]]) {
    VertexOut out;
    out.position = float4(vertices[vertexID], 0.0, 1.0);
    return out;
}

float random(float2 st, float seed) {
    return fract(sin(dot(st, float2(12.9898, 78.233)) + seed) * 43758.5453123);
}

fragment float4 noiseFragmentShader(VertexOut in [[stage_in]], constant float& time [[buffer(0)]]) {
    float2 uv = in.position.xy / float2(512.0); // Adjust based on resolution
    float noise = random(uv + time * 0.1, time);
    float alpha = 0.1 * noise; // Subtle noise opacity
    return float4(1.0, 1.0, 1.0, alpha); // White noise with adjustable opacity
}
