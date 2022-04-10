//
//  Geo.m
//  ShadowMappingOnMetal
//
//  Created by Andrey on 19.03.2022.
//

#import <Foundation/Foundation.h>
#import "Geo.h"

@implementation Geo
{
    matrix_float4x4 _trs;
    NSMutableData*  _vertices;
}
-(instancetype)initWith:(const Vertex*)data sized:(uint32_t)size
{
    if (self = [super init]) {
        _trs = matrix_identity_float4x4;
        _size = size;
        
        _vertices = [NSMutableData dataWithLength:sizeof(Vertex) * size];
        Vertex* array = [_vertices mutableBytes];
        
        memcpy(array, data, sizeof(Vertex) * size);
    }
    return self;
}
-(matrix_float4x4)transform
{
    return _trs;
}
-(void)setTransform:(matrix_float4x4)transform
{
    _trs = transform;
}

-(const Vertex*) data
{
    return (const Vertex*)[_vertices mutableBytes];
}

-(void)scaleBy:(float)factor {
    if (fabs(factor) < 1e-4)
        return;
    
    matrix_float4x4 m = self.transform;
    matrix_float4x4 s = matrix_identity_float4x4;
    s.columns[0].x = factor;
    s.columns[1].y = factor;
    s.columns[2].z = factor;
    
    self.transform = simd_mul(m, s);
}


+(matrix_float4x4) matrix4x4_rotation:(float)radians around:(vector_float3)axis {
    axis = vector_normalize(axis);
    float ct = cosf(radians);
    float st = sinf(radians);
    float ci = 1 - ct;
    float x = axis.x, y = axis.y, z = axis.z;

    return (matrix_float4x4) {{
            {ct + x * x * ci, y * x * ci + z * st, z * x * ci - y * st, 0},
            {x * y * ci - z * st, ct + y * y * ci, z * y * ci + x * st, 0},
            {x * z * ci + y * st, y * z * ci - x * st, ct + z * z * ci, 0},
            {0, 0, 0, 1}
    }};
}

@end
