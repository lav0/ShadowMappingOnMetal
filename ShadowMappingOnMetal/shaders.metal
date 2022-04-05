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
    float4 positionW [[position]];
    float4 positionM;
    float4 normal;
    float4 light;
    float4 color;
    float2 texCoords;
}
PositionOut;

typedef struct
{
    float depth [[depth(less)]];
}
DepthFragmentOut;


vertex PositionOut
vertexShader(constant Vertex *vertices                  [[ buffer(IndexVertices) ]],
             constant Uniforms *transforms              [[ buffer(IndexUniforms) ]],
             constant Uniforms *shadows                 [[ buffer(IndexShadows)  ]],
             const device float4x4& modelMat            [[ buffer(IndexModelMat) ]],
             uint vid                                   [[ vertex_id ]])
{
    PositionOut out;
    matrix_float4x4 projViewMat = transforms->projection * transforms->view;
    out.positionW = projViewMat * modelMat * vertices[vid].position;
    out.positionM = shadows->projection * shadows->view * modelMat * vertices[vid].position;
    out.normal = modelMat * vertices[vid].normal;
    out.light = transforms->light_ray;
    out.color = vertices[vid].color;
    
    return out;
}

fragment float4 fragmentTextureShader(PositionOut in [[ stage_in ]],
                                      depth2d<float, access::sample> depths [[ texture(FII_IndexDepthTexture) ]])
{
    constexpr sampler sampler2D(coord::normalized,
                                address::clamp_to_edge,
                                min_filter::linear,
                                mag_filter::linear);
    
    float2 uv = in.positionM.xy / in.positionM.w;
    uv.y *= -1;
    uv.xy += 1.0;
    uv.xy /= 2.0;
    
    float d   = depths.sample(sampler2D, uv);

    float4 ambient = 0.5 * in.color;
    float4 diffuse = 0.7 * in.color;

    float3 N = normalize(in.normal.xyz);
    float3 L = -normalize(in.light.xyz);

    float t = (in.positionM.z / in.positionM.w);
    float diffuseFactor = d < t-0.00001 ? 0 : fmax(0.f, dot(N, L));
    
    return ambient + diffuseFactor * diffuse;
}



vertex PositionOut vertexDepth(constant Vertex *vertices                  [[ buffer(IndexVertices) ]],
                              constant Uniforms *transforms              [[ buffer(IndexUniforms) ]],
                              const device float4x4& modelMat            [[ buffer(IndexModelMat) ]],
                              uint vid                                   [[ vertex_id ]])
{
    PositionOut out;
    matrix_float4x4 projViewMat = transforms->projection * transforms->view;
    out.positionW = projViewMat * modelMat * vertices[vid].position;
    out.positionM = projViewMat * modelMat * vertices[vid].position;
    
    return out;
}

fragment float fragmentDepthShader(PositionOut in [[ stage_in ]])
{
    return in.positionM.z;
}
