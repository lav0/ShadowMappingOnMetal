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

+(Geo*) makeTriangleAt:(vector_float4)position;

@end

#endif /* GeoFactory_h */
