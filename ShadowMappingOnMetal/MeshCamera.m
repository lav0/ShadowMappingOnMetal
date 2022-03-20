//
//  MeshCamera.m
//  SDFTest
//
//  Created by Andrey on 28.02.2022.
//

#import <simd/simd.h>
#import "MeshCamera.h"


@implementation MeshCamera
{
}
-(instancetype)init
{
    if (self = [super init]) {
        _transform = matrix_identity_float4x4;
    }
    return self;
}
-(void)revolveAround:(vector_float3)axis by:(float)angle
{
    matrix_float4x4 turn = simd_matrix4x4( simd_quaternion(angle, axis) );
        
    _transform = simd_mul( _transform, turn );
}
-(void)moveAlong:(vector_float3)axis by:(float)units
{
    vector_float3 c = _transform.columns[3].xyz;
    
    vector_float3 r = c + axis * units;
    
    _transform.columns[3].x = r.x;
    _transform.columns[3].y = r.y;
    _transform.columns[3].z = r.z;
}
-(void)moveAlongLookBy:(float)units
{
    vector_float3 look = (vector_float3){_transform.columns[2].x,
                                         _transform.columns[2].y,
                                         _transform.columns[2].z
                                        };
    [self moveAlong:look by:units];
}

@end
