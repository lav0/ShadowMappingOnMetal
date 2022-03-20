//
//  Helpers.h
//  ShadowMappingOnMetal
//
//  Created by Andrey on 19.03.2022.
//

#ifndef Helpers_h
#define Helpers_h
#include <simd/simd.h>

matrix_float4x4 matrix_perspective_right_hand(float fovyRadians, float aspect, float nearZ, float farZ) {
    float ys = 1 / tanf(fovyRadians * 0.5f);
    float xs = ys / aspect;
    float zs = farZ / (nearZ - farZ);

    return (matrix_float4x4) {{
            {xs, 0, 0, 0},
            {0, ys, 0, 0},
            {0, 0, zs, -1},
            {0, 0, nearZ * zs, 0}
    }};
}


#endif /* Helpers_h */
