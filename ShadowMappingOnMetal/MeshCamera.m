//
//  MeshCamera.m
//  SDFTest
//
//  Created by Andrey on 28.02.2022.
//

#import <simd/simd.h>
#import "MeshCamera.h"

#import <MetalKit/MetalKit.h>

@implementation MeshCamera
{
    vector_float3 _look;
}
-(instancetype)init
{
    if (self = [super init]) {
        _transform = matrix_identity_float4x4;
        _look = (vector_float3){0, 0, -1};
    }
    return self;
}
-(void)revolveAround:(vector_float3)axis by:(float)angle
{
    simd_quatf turn = simd_quaternion(angle, axis);
        
    _transform = simd_mul(_transform,
                          simd_matrix4x4( turn ));
    
    _look      = simd_act(turn,
                          _look);
}
-(void)moveAlong:(vector_float3)axis by:(float)units
{
    vector_float3 r = axis * units;
    
    matrix_float4x4 m = _transform;
    matrix_float4x4 t = matrix_identity_float4x4;
    t.columns[3].x = r.x;
    t.columns[3].y = r.y;
    t.columns[3].z = r.z;
    
    _transform = simd_mul(t, m);
}
-(void)moveAlongLookBy:(float)units
{
    [self moveAlong:_look by:units];
}


@end
