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

@end
