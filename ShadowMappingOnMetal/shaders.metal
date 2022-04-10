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
    float4 color [[color(1)]];
    float depth [[depth(less)]];
}
DepthFragmentOut;

vertex PositionOut
vertexShader(constant Vertex *vertices                  [[ buffer(IndexVertices) ]],
             constant ModelUniforms *transforms         [[ buffer(IndexModelUniforms) ]],
             constant ShadowUniforms *shadows           [[ buffer(IndexShadowsUniforms)  ]],
             const device float4x4& modelMat            [[ buffer(IndexModelMat) ]],
             uint vid                                   [[ vertex_id ]])
{
    PositionOut out;
    matrix_float4x4 projViewMat = transforms->projection * transforms->view;
    out.positionW = projViewMat * modelMat * vertices[vid].position;
    out.positionM = shadows->projection * shadows->view * modelMat * vertices[vid].position;
    out.normal = modelMat * vertices[vid].normal;
    out.light  = float4((modelMat * vertices[vid].position).xyz - shadows->light_origin.xyz, 0.f);
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

    float4 ambient = 0.4 * in.color;
    float4 diffuse = 0.6 * in.color;

    float3 N = normalize(in.normal.xyz);
    float3 L = -normalize(in.light.xyz);

    float t = (in.positionM.z / in.positionM.w);
    float diffuseFactor = d < t-1e-5 ? 0 : fmax(0.f, dot(N, L));
    
    return ambient + diffuseFactor * diffuse;
}

//

vertex PositionOut vertexDepth(constant Vertex *vertices                  [[ buffer(IndexVertices) ]],
                               constant ShadowUniforms *transforms        [[ buffer(IndexShadowsUniforms) ]],
                               const device float4x4& modelMat            [[ buffer(IndexModelMat) ]],
                               uint vid                                   [[ vertex_id ]])
{
    PositionOut out;
    matrix_float4x4 projViewMat = transforms->projection * transforms->view;
    out.positionW = projViewMat * modelMat * vertices[vid].position;
    out.positionM = projViewMat * modelMat * vertices[vid].position;
    
    return out;
}

fragment DepthFragmentOut fragmentDepthShader(PositionOut in [[ stage_in ]])
{
    DepthFragmentOut out;
    out.depth = in.positionM.z / in.positionM.w;
    return out;
}
