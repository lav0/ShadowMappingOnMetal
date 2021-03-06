//
//  Renderer.m
//  ShadowMappingOnMetal
//
//  Created by Andrey on 19.03.2022.
//

@import simd;

#import "Renderer.h"
#import "ShaderTypes.h"
#import "Geo.h"
#include "Helpers.h"


@implementation Renderer
{
    id<MTLDevice> _device;
    
    id<MTLBuffer> _uniforms;
    id<MTLBuffer> _shadowUniforms;
    NSMutableArray< id<MTLTexture> > *_depthTex;
    id<MTLTexture> _colorTex;
    
    id<MTLRenderPipelineState> _pipelineMainState;
    id<MTLRenderPipelineState> _pipelineDepthState;
    id<MTLDepthStencilState> _depthState;
    id<MTLCommandQueue> _commandQueue;
    
    NSMutableArray< MTLRenderPassDescriptor* >* _shadowPassDescriptor;

    vector_uint2 _viewportSize;
    
    matrix_float4x4 _projection;
    matrix_float4x4 _shadowProjection;
    uint            _numShadowCameras;
    
    NSMutableArray< Geo* >* _nodes;
}

- (nonnull instancetype)initWithMetalKitView:(nonnull MTKView *)mtkView andNumCameras:(uint)numCameras
{
    self = [super init];
    if(self)
    {
        NSError *error;

        _device = mtkView.device;

        // Load all the shader files with a .metal file extension in the project.
        id<MTLLibrary> defaultLibrary = [_device newDefaultLibrary];

        id<MTLFunction> vertexFunction = [defaultLibrary newFunctionWithName:@"vertexShader"];
        id<MTLFunction> depthFunction = [defaultLibrary newFunctionWithName:@"vertexDepth"];
        id<MTLFunction> fragmentMainFunction = [defaultLibrary newFunctionWithName:@"fragmentTextureShader"];
        id<MTLFunction> fragmentDepthFunction = [defaultLibrary newFunctionWithName:@"fragmentDepthShader"];

        // Configure a pipeline descriptor that is used to create a pipeline state.
        MTLRenderPipelineDescriptor *pipelineStateDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
        pipelineStateDescriptor.label = @"Simple Pipeline";
        pipelineStateDescriptor.vertexFunction = vertexFunction;
        pipelineStateDescriptor.fragmentFunction = fragmentMainFunction;
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = mtkView.colorPixelFormat;
        pipelineStateDescriptor.depthAttachmentPixelFormat = mtkView.depthStencilPixelFormat;

        _pipelineMainState = [_device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor
                                                                 error:&error];
        
        NSAssert(_pipelineMainState, @"Failed to create pipeline main state: %@", error);
        
        pipelineStateDescriptor.label = @"Depth Pipeline";
        pipelineStateDescriptor.vertexFunction = depthFunction;
        pipelineStateDescriptor.fragmentFunction = fragmentDepthFunction;
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatInvalid;
        pipelineStateDescriptor.depthAttachmentPixelFormat = MTLPixelFormatDepth32Float;
        
        _pipelineDepthState = [_device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor
                                                                      error:&error];
        NSAssert(_pipelineDepthState, @"Failed to create pipeline depth state: %@", error);

        MTLDepthStencilDescriptor *depthStateDesc = [[MTLDepthStencilDescriptor alloc] init];
        depthStateDesc.depthCompareFunction = MTLCompareFunctionLessEqual;
        depthStateDesc.depthWriteEnabled = YES;
        _depthState = [_device newDepthStencilStateWithDescriptor:depthStateDesc];

        MTLTextureDescriptor* depthTextureDesc = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat: MTLPixelFormatDepth32Float
                                                                                                    width: 1024 //mtkView.frame.size.width
                                                                                                   height: 1024 //mtkView.frame.size.height
                                                                                                mipmapped: NO];
        
        depthTextureDesc.textureType = MTLTextureType2D;
        depthTextureDesc.sampleCount = 1;
        depthTextureDesc.storageMode = MTLStorageModePrivate;
        depthTextureDesc.usage = MTLTextureUsageShaderRead & MTLTextureUsageRenderTarget;
        
        _depthTex = [[NSMutableArray alloc] init];
        for (int i=0; i<numCameras; ++i)
            [_depthTex addObject: [_device newTextureWithDescriptor:depthTextureDesc]];
        
        MTLTextureDescriptor* colorTextureDesc = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:mtkView.colorPixelFormat
                                                                                                    width:256 //mtkView.frame.size.width
                                                                                                   height:256 //mtkView.frame.size.height
                                                                                                mipmapped:NO];
        colorTextureDesc.textureType = MTLTextureType2D;
        colorTextureDesc.sampleCount = 1;
        colorTextureDesc.storageMode = MTLStorageModePrivate;
        colorTextureDesc.usage = MTLTextureUsageShaderRead & MTLTextureUsageRenderTarget;
        
        _colorTex = [_device newTextureWithDescriptor:colorTextureDesc];
        
        _shadowPassDescriptor = [[NSMutableArray alloc] init];
        for (int i=0; i<numCameras; ++i) {
            MTLRenderPassDescriptor* shadowPassDescriptor = [[MTLRenderPassDescriptor alloc] init];
            shadowPassDescriptor.depthAttachment.texture = _depthTex[i];
            shadowPassDescriptor.depthAttachment.loadAction = MTLLoadActionClear;
            shadowPassDescriptor.depthAttachment.storeAction = MTLStoreActionStore;
            shadowPassDescriptor.depthAttachment.clearDepth = 1.0;
            [_shadowPassDescriptor addObject:shadowPassDescriptor];
        }
        
        _uniforms = [_device newBufferWithLength:sizeof(ModelUniforms)
                                         options:MTLResourceStorageModeShared];
        
        _shadowUniforms = [_device newBufferWithLength:sizeof(ShadowUniforms)*numCameras
                                               options:MTLResourceStorageModeShared];
                
        // Pipeline State creation could fail if the pipeline descriptor isn't set up properly.
        //  If the Metal API validation is enabled, you can find out more information about what
        //  went wrong.  (Metal API validation is enabled by default when a debug build is run
        //  from Xcode.)
        NSAssert(_pipelineMainState, @"Failed to create pipeline state: %@", error);

        // Create the command queue
        _commandQueue = [_device newCommandQueue];
        
        _nodes = [[NSMutableArray alloc] init];
        
        _numShadowCameras = numCameras;
        [self offsetCamera];
    }

    return self;
}

-(void)offsetCamera
{
    float offset = 2.f;
    vector_float3 axis = (vector_float3){0, 0, 1};
    _camera = [[MeshCamera alloc] init];
    [_camera moveAlong:axis by:offset];
    
    MeshCamera* shadCam = [[MeshCamera alloc] init];
    [shadCam moveAlong:axis by:offset];
    
    MeshCamera* shadSecCam = [[MeshCamera alloc] init];
    [shadSecCam moveAlong:axis by:offset];
    
    _shadowCamera = [[NSArray alloc] initWithObjects:shadCam, shadSecCam, nil];
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
    
    NSLog(@"mtkView size: %f %f", size.width, size.height);
    
    _projection = matrix_perspective_right_hand(M_PI_2,
                                                size.width / (float)size.height,
                                                0.01f,
                                                50.0f);
    
    _shadowProjection = _projection;// matrix_orthogonal_right_hand(size.width / (float)size.height, 0.01f, 50.0f);
                  
}

/// Called whenever the view needs to render a frame.
- (void)drawInMTKView:(nonnull MTKView *)view
{
    [self updateUniforms];
    
    id<MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];
    commandBuffer.label = @"MyCommand";

    for (uint i=0; i<_numShadowCameras; ++i)
    {
        MTLRenderPassDescriptor* shadowPassDescriptor = _shadowPassDescriptor[i];
        if (shadowPassDescriptor != nil)
        {
            id<MTLRenderCommandEncoder> depthEncoder =
            [commandBuffer renderCommandEncoderWithDescriptor:shadowPassDescriptor];
            depthEncoder.label = @"DepthPassEncoder";

            [depthEncoder setRenderPipelineState:_pipelineDepthState];
            [depthEncoder setDepthStencilState:_depthState];
            [depthEncoder setVertexBuffer:_shadowUniforms offset:i * sizeof(ShadowUniforms) atIndex:IndexShadowsUniforms];

            for (Geo* geometry in _nodes)
            {
                matrix_float4x4 model = geometry.transform;

                [depthEncoder setVertexBytes:&model length:sizeof(matrix_float4x4) atIndex:IndexModelMat];

                [depthEncoder setVertexBytes:[geometry data]
                                       length:sizeof(Vertex) * geometry.size
                                      atIndex:IndexVertices];

                [depthEncoder drawPrimitives:MTLPrimitiveTypeTriangle
                                 vertexStart:0
                                 vertexCount:geometry.size];
            }
            [depthEncoder endEncoding];
        }
    }
    
    MTLRenderPassDescriptor *renderPassDescriptor = view.currentRenderPassDescriptor;

    if (renderPassDescriptor != nil)
    {
        renderPassDescriptor.colorAttachments[0].storeAction = MTLStoreActionStore;
        renderPassDescriptor.depthAttachment.storeAction = MTLStoreActionStore;
        
        // Create a render command encoder.
        id<MTLRenderCommandEncoder> renderEncoder =
            [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
        renderEncoder.label = @"MyRenderEncoder";

        [renderEncoder setRenderPipelineState:_pipelineMainState];
        [renderEncoder setDepthStencilState:_depthState];
        [renderEncoder setFragmentTexture:_depthTex[0] atIndex:FII_IndexDepthTexture];
        [renderEncoder setFragmentTexture:_depthTex[1] atIndex:FII_IndexDepthTexture2];
        [renderEncoder setVertexBuffer:_uniforms offset:0 atIndex:IndexModelUniforms];
        [renderEncoder setVertexBuffer:_shadowUniforms offset:0 atIndex:IndexShadowsUniforms];
        [renderEncoder setVertexBytes:&_numShadowCameras length:sizeof(_numShadowCameras) atIndex:IndexLightCount];

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
    ModelUniforms* data = [_uniforms contents];
    data->view = _camera.transform;
    data->projection = _projection;
    
    for (uint i=0; i<_numShadowCameras; ++i)
    {
        MeshCamera* shadCam = _shadowCamera[i];
        
        vector_float3 clook = [shadCam getLookDirection];
        vector_float3 cpos  = [shadCam getEyePosition];
        ShadowUniforms* shadow = [_shadowUniforms contents] + i * sizeof(ShadowUniforms);
        shadow->view = shadCam.transform;
        shadow->projection = _shadowProjection;
        shadow->light_ray = (vector_float4){ clook.x, clook.y, clook.z, 0.f };
        shadow->light_origin = (vector_float4){ cpos.x, cpos.y, cpos.z, 1.f };
    }
}



@end

