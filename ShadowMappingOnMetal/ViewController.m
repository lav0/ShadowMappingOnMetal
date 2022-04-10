//
//  ViewController.m
//  ShadowMappingOnMetal
//
//  Created by Andrey on 19.03.2022.
//

#import "ViewController.h"
#import "Renderer.h"
#import "GeoFactory.h"


static float _CAM_ANGLE_INCREMENT = 0.03f;
static float _RAD_OFFSET = 1.0f;

@implementation ViewController
{
    Renderer *_renderer;
    Geo* _geo;
    Geo* _ge1;
    Geo* _ge2;
    
    BOOL _revolving;
    float _triagAngle;
    float _cameraAngle;
    
    NSTimer* _timer;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    EventHandlerMetalView* view = (EventHandlerMetalView *)self.view;
    
    view.device = MTLCreateSystemDefaultDevice();
    view.depthStencilPixelFormat = MTLPixelFormatDepth32Float;
    view.clearColor = MTLClearColorMake(0.63, 0.81, 1.0, 1.0);
    
    NSAssert(view.device, @"Metal is not supported on this device");
    
    _renderer = [[Renderer alloc] initWithMetalKitView:view];
    
    NSAssert(_renderer, @"Renderer failed initialization");
    
    const vector_float4 grey = (vector_float4){ 0.5, 0.5, 0.5, 1 };
    const vector_float4 blueish = (vector_float4){ 0.5, 0.53, 0.7, 1 };
    
    _geo = [GeoFactory makeColoredTriangleAt:(vector_float4){0, 0, -0.9, 1}];
    _ge1 = [GeoFactory makeCubeAt:(vector_float4){0, 0, -2, 1} color:grey];
    _ge2 = [GeoFactory makeRectangleAt:(vector_float4){-10, -10, -10, 1} color:grey];
    
    [_ge2 scaleBy:20.0];
    
    [_renderer mtkView:view drawableSizeWillChange:view.drawableSize];
    [_renderer addGeo: _ge2];
    [_renderer addGeo: _ge1];
//    [_renderer addGeo: _geo];
    
    view.delegate = _renderer;
    view.keyArrowDelegate = self;
    
    _revolving = NO;
    _triagAngle = 3.82719493; // M_PI / 3;
    _cameraAngle = 0.f;
    _timer = [NSTimer scheduledTimerWithTimeInterval: 0.02
                                              target: self
                                              selector:@selector(onTick:)
                                              userInfo: nil repeats:YES];
    
//    float cam_x = _RAD_OFFSET * sin(_cameraAngle);
//    float cam_y = _RAD_OFFSET * cos(_cameraAngle);
//    [_renderer.shadowCamera moveAlong:(vector_float3){cam_x, -cam_y, 0} by: 1.0f];
    
    matrix_float4x4 rot_mat = [Geo matrix4x4_rotation:M_PI_2*0.95 around:(vector_float3){0, 1, 0}];
    _ge1.transform = simd_mul(_ge1.transform, rot_mat);
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
    
    _cameraAngle += _CAM_ANGLE_INCREMENT;
    
//    float cam_x = _RAD_OFFSET * sin(_cameraAngle);
//    float cam_y = _RAD_OFFSET * cos(_cameraAngle);
//
//    [_renderer.shadowCamera moveAlong:(vector_float3){-cam_y, cam_x, 0.f} by:_RAD_OFFSET*_CAM_ANGLE_INCREMENT];
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
