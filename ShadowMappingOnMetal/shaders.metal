//
//  shaders.metal
//  ShadowMappingOnMetal
//
//  Created by Andrey on 19.03.2022.
//
#include <metal_stdlib>
using namespace metal;

#include "ShaderTypes.h"

#define MaxLightCount 4

typedef struct
{
    float4 positionW [[position]];
    float4 positionM;
    float4 normal;
    float4 color;
    float4 light0;
    float4 light1;
    float4 light2;
    float4 light3;
    uint   lights_count;
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
             const device uint& light_count             [[ buffer(IndexLightCount) ]],
             uint vid                                   [[ vertex_id ]])
{
    PositionOut out;
    matrix_float4x4 projViewMat = transforms->projection * transforms->view;
    out.positionW = projViewMat * modelMat * vertices[vid].position;
    out.positionM = shadows->projection * shadows->view * modelMat * vertices[vid].position;
    out.normal = modelMat * vertices[vid].normal;
    out.color = vertices[vid].color;
    
    float4x4 lights;
    for (uint idx=0; idx<light_count; ++idx) {
        lights.columns[idx]  = float4((modelMat * vertices[vid].position).xyz - shadows[idx].light_origin.xyz, 0.f);
    }
    
    out.light0 = lights.columns[0];
    out.light1 = lights.columns[1];
    out.light2 = lights.columns[2];
    out.light3 = lights.columns[3];
    out.lights_count = light_count;
    
    return out;
}

fragment float4 fragmentTextureShader(PositionOut in [[ stage_in ]],
                                      depth2d<float, access::sample> depths [[ texture(FII_IndexDepthTexture) ]],
                                      depth2d<float, access::sample> depths2 [[ texture(FII_IndexDepthTexture2) ]]
                                      )
{
    constexpr sampler sampler2D(coord::normalized,
                                address::clamp_to_edge,
                                min_filter::linear,
                                mag_filter::linear);
    
    float3 model_world = in.positionM.xyz / in.positionM.w;
    
    float2 uv = model_world.xy;
    uv.y *= -1;
    uv.xy += 1.0;
    uv.xy /= 2.0;

    float4 ambient = 0.5 * in.color;
    float4 diffuse = 0.25 * in.color;

    float4 final_color = ambient;
    
    float4x4 lights = { in.light0, in.light1, in.light2, in.light3 };
    
    for (uint i=0; i<in.lights_count; ++i)
    {
        float d   = (i==0) ? depths.sample(sampler2D, uv) :
                             depths2.sample(sampler2D, uv);

        float3 N = normalize(in.normal.xyz);
        float3 L = -normalize(in.light1.xyz);

        float t = model_world.z;
        float diffuseFactor = d < t-1e-4 ? 0 : fmax(0.f, dot(N, L));
        
        final_color += diffuseFactor * diffuse;
    }
    
    return final_color;
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
