//
//  ViewController.m
//  ShadowMappingOnMetal
//
//  Created by Andrey on 19.03.2022.
//

#import "ViewController.h"
#import "Renderer.h"
#import "GeoFactory.h"

@implementation ViewController
{
    Renderer *_renderer;
    Geo* _geo;
    Geo* _ge1;
    
    float _angle;
    NSTimer* _timer;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    EventHandlerMetalView* view = (EventHandlerMetalView *)self.view;
    
    view.device = MTLCreateSystemDefaultDevice();
    
    NSAssert(view.device, @"Metal is not supported on this device");
    
    _renderer = [[Renderer alloc] initWithMetalKitView:view];
    
    NSAssert(_renderer, @"Renderer failed initialization");
    
    _geo = [GeoFactory makeTriangleAt:(vector_float4){-1.3, 0, 0, 1}];
    _ge1 = [GeoFactory makeTriangleAt:(vector_float4){1.3, 0, 0, 1}];
    
    [_renderer mtkView:view drawableSizeWillChange:view.drawableSize];
    [_renderer addGeo: _ge1];
    [_renderer addGeo: _geo];
    
    view.delegate = _renderer;
    view.keyArrowDelegate = self;
    
    _angle = 0.f;
    _timer = [NSTimer scheduledTimerWithTimeInterval: 0.02
                                              target: self
                                              selector:@selector(onTick:)
                                              userInfo: nil repeats:YES];
}


- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];
}

- (void)onTick:(NSTimer*)t
{
    _angle += 0.01;
    
    float sn = sin(_angle);
    float cs = cos(_angle);
    
    matrix_float4x4 m = _geo.transform;
    m.columns[0].x = cs; m.columns[1].x = -sn;
    m.columns[0].y = sn; m.columns[1].y = cs;
    
    _geo.transform = m;
}
-(void)leftPressed {
    [_renderer.camera revolveAround:(vector_float3){0, 1, 0} by:0.05];
}
-(void)rightPressed {
    [_renderer.camera revolveAround:(vector_float3){0, 1, 0} by:-0.05];
}
-(void)topPressed {
    [_renderer.camera moveAlongLookBy:-0.5];
}
-(void)downPressed {
    [_renderer.camera moveAlongLookBy:0.5];
}

@end