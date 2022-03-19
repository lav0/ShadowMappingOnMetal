//
//  GeoFactory.m
//  ShadowMappingOnMetal
//
//  Created by Andrey on 19.03.2022.
//

#import <Foundation/Foundation.h>
#import "GeoFactory.h"

@implementation GeoFactory

+(Geo*) makeTriangleAt:(vector_float4)position
{
    const Vertex triangleVertices[] =
    {
        { {  0.5,  -0.5, 0.1, 1 }, {0, 0, 1, 0}, { 1, 0, 0, 1 } },
        { { -0.5,  -0.5, 0.1, 1 }, {0, 0, 1, 0}, { 0, 1, 0, 1 } },
        { {    0,   0.5, 0.1, 1 }, {0, 0, 1, 0}, { 0, 0, 1, 1 } },
    };
    
    Geo* geo = [[Geo alloc] initWith:triangleVertices sized: 3];
    
    matrix_float4x4 m = matrix_identity_float4x4;
    m.columns[3] = position;
    
    geo.transform = m;
    
    return geo;
}


@end
