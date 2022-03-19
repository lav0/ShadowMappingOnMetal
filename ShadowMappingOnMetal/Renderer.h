//
//  Renderer.h
//  ShadowMappingOnMetal
//
//  Created by Andrey on 19.03.2022.
//

@import Foundation;
@import MetalKit;

#import "Geo.h"

NS_ASSUME_NONNULL_BEGIN

@interface Renderer : NSObject<MTKViewDelegate>

- (nonnull instancetype)initWithMetalKitView:(nonnull MTKView *)mtkView;
- (void)addGeo:(Geo*)node;

@end

NS_ASSUME_NONNULL_END
