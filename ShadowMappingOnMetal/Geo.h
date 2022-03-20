//
//  Geo.h
//  ShadowMappingOnMetal
//
//  Created by Andrey on 19.03.2022.
//

#import <Foundation/Foundation.h>
#import "ShaderTypes.h"

NS_ASSUME_NONNULL_BEGIN

@interface Geo : NSObject

@property (nonatomic, readonly) uint32_t size;
@property (nonatomic) matrix_float4x4 transform;

-(instancetype)initWith:(const Vertex*)data sized:(uint32_t)size;
-(const Vertex*) data;

-(void)scaleBy:(float)factor;

@end

NS_ASSUME_NONNULL_END
