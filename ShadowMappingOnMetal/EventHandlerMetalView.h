//
//  EventHandlerMetalView.h
//  ShadowMappingOnMetal
//
//  Created by Andrey on 20.03.2022.
//

#import <MetalKit/MetalKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol KeyboardArrowPressedDelegate
@required
-(void)leftPressed;
-(void)rightPressed;
-(void)topPressed;
-(void)downPressed;
@end

@interface EventHandlerMetalView : MTKView

@property (weak, nonatomic, nullable) id<KeyboardArrowPressedDelegate> keyArrowDelegate;

@end

NS_ASSUME_NONNULL_END
