//
//  ViewController.m
//  ShadowMappingOnMetal
//
//  Created by Andrey on 19.03.2022.
//

#import "ViewController.h"
#import "Renderer.h"
#import "GeoFactory.h"


static float _CAM_ANGLE_INCREMENT = M_PI_2 / 2;
static float _RAD_OFFSET = 0.2f;

@implementation ViewController
{
    Renderer *_renderer;
    Geo* _geo;
    Geo* _ge1;
    Geo* _ge2;
    
    BOOL _revolving;
    float _triagAngle;
    
    NSTimer* _timer;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    EventHandlerMetalView* view = (EventHandlerMetalView *)self.view;
    
    view.device = MTLCreateSystemDefaultDevice();
    view.depthStencilPixelFormat = MTLPixelFormatDepth32Float;
    view.clearColor = MTLClearColorMake(0.63, 0.81, 1.0, 1.0);
    
    NSAssert(view.device, @"Metal is not supported on this device");
    
    uint numShadows = 2;
    _renderer = [[Renderer alloc] initWithMetalKitView:view andNumCameras:numShadows];
    
    NSAssert(_renderer, @"Renderer failed initialization");
    
    const vector_float4 grey = (vector_float4){ 0.5, 0.5, 0.5, 1 };
    const vector_float4 blueish = (vector_float4){ 0.5, 0.53, 0.7, 1 };
    
    _geo = [GeoFactory makeColoredTriangleAt:(vector_float4){0, 0, -0.5, 1}];
    _ge1 = [GeoFactory makeCubeAt:(vector_float4){-0.5, -0.5, -2, 1} color:blueish];
    _ge2 = [GeoFactory makeRectangleAt:(vector_float4){-10, -10, -10, 1} color:grey];
    
    [_ge2 scaleBy:20.0];
    
    [_renderer mtkView:view drawableSizeWillChange:view.drawableSize];
    [_renderer addGeo: _ge2];
    [_renderer addGeo: _ge1];
    [_renderer addGeo: _geo];
    
    view.delegate = _renderer;
    view.keyArrowDelegate = self;
    
    _revolving = NO;
    _triagAngle = 3.82719493; // M_PI / 3;
    
    _timer = [NSTimer scheduledTimerWithTimeInterval: 0.02
                                              target: self
                                              selector:@selector(onTick:)
                                              userInfo: nil repeats:YES];
    
    float cameraAngle = 0.f;
    float cam_x = _RAD_OFFSET * sin(cameraAngle);
    float cam_y = _RAD_OFFSET * cos(cameraAngle);
    [_renderer.shadowCamera[0] moveAlong:(vector_float3){cam_x, -cam_y, 0.f} by: 1.f];
    [_renderer.shadowCamera[0] moveAlong:(vector_float3){-cam_y, cam_x, 0.f} by:_RAD_OFFSET];
    
    [_renderer.shadowCamera[1] moveAlong:(vector_float3){0,    0, 0.f} by: 1.f];
    [_renderer.shadowCamera[1] moveAlong:(vector_float3){0.4f, 0,    0.f} by:_RAD_OFFSET];
}


- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];
}

- (void)onTick:(NSTimer*)t
{
    if (_revolving)
    {
        _triagAngle += 0.01;
        
        matrix_float4x4 rot_mat = [Geo matrix4x4_rotation:0.01 around:(vector_float3){0, 1, 0}];
        _ge1.transform = simd_mul(_ge1.transform, rot_mat);
    }
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
-(void)triggerRevolving {
    _revolving = !_revolving;
}

@end
