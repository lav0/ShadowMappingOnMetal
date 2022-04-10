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
    vector_float3 _eye;
}
-(instancetype)init
{
    if (self = [super init]) {
        _transform = matrix_identity_float4x4;
        _look = (vector_float3){0, 0, -1};
        _eye  = (vector_float3){0, 0, 0,};
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
    
    // TODO: revolve _eye for consistency
}
-(void)moveAlong:(vector_float3)axis by:(float)units
{
    // moving the view camera is achieved by 'moving' the whole scene
    // the opposite way, hence we invert the directions
    
    vector_float3 r = -1.f * (axis * units);
    
    matrix_float4x4 m = _transform;
    matrix_float4x4 t = matrix_identity_float4x4;
    t.columns[3].x = r.x;
    t.columns[3].y = r.y;
    t.columns[3].z = r.z;
    
    _transform = simd_mul(t, m);
    
    _eye += axis * units;
}
-(void)moveAlongLookBy:(float)units
{
    [self moveAlong:_look by:units];
}
-(vector_float3)getLookDirection
{
    return _look;
}
-(vector_float3)getEyePosition
{
    return _eye;
}

@end
