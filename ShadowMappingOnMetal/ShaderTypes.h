//
//  ShaderTypes.h
//  ShadowMappingOnMetal
//
//  Created by Andrey on 19.03.2022.
//

#ifndef ShaderTypes_h
#define ShaderTypes_h


#include <simd/simd.h>

typedef enum
{
    IndexVertices        = 0,
    IndexViewportSize    = 1,
    IndexModelUniforms   = 2,
    IndexShadowsUniforms = 3,
    IndexModelMat        = 4,
    IndexLightCount      = 5,
} VertexInputIndex;

typedef enum
{
    FII_IndexDepthTexture = 0,
    FII_IndexColorTexture = 1,
    FII_IndexDepthTexture2 = 2,
} FragmentInputIndex;

typedef struct
{
    matrix_float4x4 projection;
    matrix_float4x4 view;
} ModelUniforms;

typedef struct
{
    matrix_float4x4 projection;
    matrix_float4x4 view;
    vector_float4   light_ray;
    vector_float4   light_origin;
} ShadowUniforms;

typedef struct
{
    vector_float4 position;
    vector_float4 normal;
    vector_float4 color;
} Vertex;

typedef struct
{
    vector_float4 position;
    vector_float2 uv_coords;
} TextureVertex;

#endif /* ShaderTypes_h */
