//
//  MeshCamera.h
//  SDFTest
//
//  Created by Andrey on 28.02.2022.
//

#import <Foundation/Foundation.h>


@interface MeshCamera : NSObject

@property (nonatomic) matrix_float4x4 transform;

-(void)revolveAround:(vector_float3)axis by:(float)angle;
-(void)moveAlong:(vector_float3)axis by:(float)units;

@end
