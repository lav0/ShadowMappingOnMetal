//
//  Renderer.m
//  ShadowMappingOnMetal
//
//  Created by Andrey on 19.03.2022.
//

@import simd;

#import "Renderer.h"
#import "ShaderTypes.h"
#import "Helpers.h"
#import "Geo.h"

@implementation Renderer
{
    id<MTLDevice> _device;
    
    id<MTLBuffer> _uniforms;
    id<MTLTexture> _depthTex;
    
    id<MTLRenderPipelineState> _pipelineState;
    id<MTLDepthStencilState> _depthState;
    id<MTLCommandQueue> _commandQueue;

    vector_uint2 _viewportSize;
    
    matrix_float4x4 _projection;
    
    NSMutableArray< Geo* >* _nodes;
}

- (nonnull instancetype)initWithMetalKitView:(nonnull MTKView *)mtkView
{
    self = [super init];
    if(self)
    {
        NSError *error;

        _device = mtkView.device;

        // Load all the shader files with a .metal file extension in the project.
        id<MTLLibrary> defaultLibrary = [_device newDefaultLibrary];

        id<MTLFunction> vertexFunction = [defaultLibrary newFunctionWithName:@"vertexShader"];
        id<MTLFunction> fragmentFunction = [defaultLibrary newFunctionWithName:@"fragmentShader"];

        // Configure a pipeline descriptor that is used to create a pipeline state.
        MTLRenderPipelineDescriptor *pipelineStateDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
        pipelineStateDescriptor.label = @"Simple Pipeline";
        pipelineStateDescriptor.vertexFunction = vertexFunction;
        pipelineStateDescriptor.fragmentFunction = fragmentFunction;
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = mtkView.colorPixelFormat;
        pipelineStateDescriptor.depthAttachmentPixelFormat = mtkView.depthStencilPixelFormat;

        _pipelineState = [_device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor
                                                                 error:&error];

        MTLDepthStencilDescriptor *depthStateDesc = [[MTLDepthStencilDescriptor alloc] init];
        depthStateDesc.depthCompareFunction = MTLCompareFunctionLessEqual;
        depthStateDesc.depthWriteEnabled = YES;
        _depthState = [_device newDepthStencilStateWithDescriptor:depthStateDesc];

        MTLTextureDescriptor* depthTextureDesc = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat: MTLPixelFormatDepth16Unorm
                                                                                                    width: mtkView.frame.size.width
                                                                                                   height: mtkView.frame.size.height
                                                                                                mipmapped: NO];
        
        depthTextureDesc.textureType = MTLTextureType2D;
        depthTextureDesc.sampleCount = 1;
        depthTextureDesc.storageMode = MTLStorageModePrivate;
        depthTextureDesc.usage = MTLTextureUsageRenderTarget;
        
        _depthTex = [_device newTextureWithDescriptor:depthTextureDesc];
        _uniforms = [_device newBufferWithLength:sizeof(Uniforms) options:MTLResourceStorageModeShared];
                
        // Pipeline State creation could fail if the pipeline descriptor isn't set up properly.
        //  If the Metal API validation is enabled, you can find out more information about what
        //  went wrong.  (Metal API validation is enabled by default when a debug build is run
        //  from Xcode.)
        NSAssert(_pipelineState, @"Failed to create pipeline state: %@", error);

        // Create the command queue
        _commandQueue = [_device newCommandQueue];
        
        _camera = [[MeshCamera alloc] init];
        [_camera moveAlong:(vector_float3){0, 0, -1} by:2.f];
        
        _nodes = [[NSMutableArray alloc] init];
        
    }

    return self;
}

- (void)addGeo:(Geo*)node
{
    [_nodes addObject:node];
}

/// Called whenever view changes orientation or is resized
- (void)mtkView:(nonnull MTKView *)view drawableSizeWillChange:(CGSize)size
{
    // Save the size of the drawable to pass to the vertex shader.
    _viewportSize.x = size.width;
    _viewportSize.y = size.height;
    
    _projection = matrix_perspective_right_hand(90 * (M_PI / 180.0f),
                                                size.width / (float)size.height,
                                                0.011f,
                                                5000.0f);
                  
}

/// Called whenever the view needs to render a frame.
- (void)drawInMTKView:(nonnull MTKView *)view
{
    [self updateUniforms];
    

    // Create a new command buffer for each render pass to the current drawable.
    id<MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];
    commandBuffer.label = @"MyCommand";

    // Obtain a renderPassDescriptor generated from the view's drawable textures.
    MTLRenderPassDescriptor *renderPassDescriptor = view.currentRenderPassDescriptor;

    if(renderPassDescriptor != nil)
    {
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.63, 0.81, 1.0, 1.0);
//        renderPassDescriptor.depthAttachment.texture = _depthTex;
        
        // Create a render command encoder.
        id<MTLRenderCommandEncoder> renderEncoder =
            [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
        renderEncoder.label = @"MyRenderEncoder";

        // Set the region of the drawable to draw into.
        [renderEncoder setViewport:(MTLViewport){0.0, 0.0, _viewportSize.x, _viewportSize.y, 0.0, 1.0 }];
        
        [renderEncoder setRenderPipelineState:_pipelineState];
        [renderEncoder setDepthStencilState:_depthState];
        [renderEncoder setVertexBuffer:_uniforms offset:0 atIndex:IndexUniforms];
        
        for (Geo* geometry in _nodes)
        {
            matrix_float4x4 model = geometry.transform;
            
            [renderEncoder setVertexBytes:&model length:sizeof(matrix_float4x4) atIndex:IndexModelMat];
            
            [renderEncoder setVertexBytes:[geometry data]
                                   length:sizeof(Vertex) * geometry.size
                                  atIndex:IndexVertices];
            
            [renderEncoder setVertexBytes:&_viewportSize
                                   length:sizeof(_viewportSize)
                                  atIndex:IndexViewportSize];

            [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle
                              vertexStart:0
                              vertexCount:geometry.size];
        }
        [renderEncoder endEncoding];

        // Schedule a present once the framebuffer is complete using the current drawable.
        [commandBuffer presentDrawable:view.currentDrawable];
    }

    // Finalize rendering here & push the command buffer to the GPU.
    [commandBuffer commit];
}

- (void) updateUniforms
{
    Uniforms* data = [_uniforms contents];
    data->view = _camera.transform;
    data->projection = _projection;
    data->light_ray = (vector_float4) {0, 0, -1, 0};
}



@end

