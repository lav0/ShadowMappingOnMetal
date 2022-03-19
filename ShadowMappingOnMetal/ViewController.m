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
    MTKView *_view;

    Renderer *_renderer;
    Geo* _geo;
    Geo* _ge1;
    
    float _angle;
    NSTimer* _timer;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    _view = (MTKView *)self.view;
    
    _view.device = MTLCreateSystemDefaultDevice();
    
    NSAssert(_view.device, @"Metal is not supported on this device");
    
    _renderer = [[Renderer alloc] initWithMetalKitView:_view];
    
    NSAssert(_renderer, @"Renderer failed initialization");
    
    _geo = [GeoFactory makeTriangleAt:(vector_float4){-1.3, 0, 0, 1}];
    _ge1 = [GeoFactory makeTriangleAt:(vector_float4){1.3, 0, 0, 1}];
    
    [_renderer mtkView:_view drawableSizeWillChange:_view.drawableSize];
    [_renderer addGeo: _ge1];
    [_renderer addGeo: _geo];
    
    _view.delegate = _renderer;
    
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


@end
