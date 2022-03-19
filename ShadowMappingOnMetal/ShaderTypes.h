//
//  ShaderTypes.h
//  ShadowMappingOnMetal
//
//  Created by Andrey on 19.03.2022.
//

#ifndef ShaderTypes_h
#define ShaderTypes_h


#include <simd/simd.h>

typedef enum VertexInputIndex
{
    IndexVertices     = 0,
    IndexViewportSize = 1,
    IndexUniforms     = 2,
    IndexModelMat     = 3
} VertexInputIndex;

typedef struct
{
    matrix_float4x4 projection;
    matrix_float4x4 view;
    vector_float4 light_ray;
} Uniforms;

typedef struct
{
    vector_float4 position;
    vector_float4 normal;
    vector_float4 color;
} Vertex;

#endif /* ShaderTypes_h */
