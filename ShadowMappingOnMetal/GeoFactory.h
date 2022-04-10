//
//  GeoFactory.h
//  ShadowMappingOnMetal
//
//  Created by Andrey on 19.03.2022.
//

#ifndef GeoFactory_h
#define GeoFactory_h
#import "Geo.h"

@interface GeoFactory : NSObject

+(Geo*) makeColoredTriangleAt:(vector_float4)position;
+(Geo*) makeRectangleAt:(vector_float4)position color:(vector_float4)color;
+(Geo*) makeCubeAt:(vector_float4)position color:(vector_float4)color;

@end

#endif /* GeoFactory_h */
