//
//  EventHandlerMetalView.m
//  ShadowMappingOnMetal
//
//  Created by Andrey on 20.03.2022.
//

#import "EventHandlerMetalView.h"

@implementation EventHandlerMetalView

-(BOOL)acceptsFirstResponder{
  return YES;
}
-(void)keyDown:(NSEvent *)event
{
    if (self.keyArrowDelegate) {
        if (event.keyCode == 123)
            [self.keyArrowDelegate leftPressed];
        else
        if (event.keyCode == 124)
            [self.keyArrowDelegate rightPressed];
        else
        if (event.keyCode == 125)
            [self.keyArrowDelegate downPressed];
        else
        if (event.keyCode == 126)
            [self.keyArrowDelegate topPressed];
    }
}

@end
