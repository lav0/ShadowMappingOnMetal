//
//  shaders.metal
//  ShadowMappingOnMetal
//
//  Created by Andrey on 19.03.2022.
//
#include <metal_stdlib>
using namespace metal;

#include "ShaderTypes.h"


typedef struct
{
    float4 position [[position]];
    float4 normal;
    float4 light;
    float4 color;
}
PositionOut;

vertex PositionOut
vertexShader(constant Vertex *vertices                  [[buffer(IndexVertices)]],
             constant vector_uint2 *viewportSizePointer [[buffer(IndexViewportSize)]],
             constant Uniforms *transforms              [[buffer(IndexUniforms)]],
             const device float4x4& modelMat            [[buffer(IndexModelMat)]],
             uint vid                                   [[vertex_id]])
{
    PositionOut out;
    matrix_float4x4 projViewMat = transforms->projection * transforms->view;
    out.position = projViewMat * modelMat * vertices[vid].position;
    out.normal = projViewMat * modelMat * vertices[vid].normal;
//    out.light = lightVec;
    out.color = vertices[vid].color;
    
    return out;
}

fragment float4 fragmentShader(PositionOut in [[stage_in]])
{
    // Return the interpolated color.
    return in.color;
}

