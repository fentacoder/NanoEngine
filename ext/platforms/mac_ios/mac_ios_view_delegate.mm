/*************************************************************************************************
 Copyright 2021 Jamar Phillip

Licensed to the Apache Software Foundation (ASF) under one
or more contributor license agreements.  See the NOTICE file
distributed with this work for additional information
regarding copyright ownership.  The ASF licenses this file
to you under the Apache License, Version 2.0 (the
"License"); you may not use this file except in compliance
with the License.  You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing,
software distributed under the License is distributed on an
"AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
KIND, either express or implied.  See the License for the
specific language governing permissions and limitations
under the License.
*************************************************************************************************/
#include "mac_ios_view_delegate.h"

#ifdef __PEN_MAC_IOS__
static PenMacIOSMTKViewDelegate* instance;

@implementation PenMacIOSMTKViewDelegate

- (nonnull instancetype)initWithMetalKitView:(nonnull MTKView *)view size:(CGSize)size
{
    self = [super init];
    if(self)
    {
        PenMacIOSState* inst = [PenMacIOSState Get];
        self.motionManager = [[CMMotionManager alloc] init];
        if(self.motionManager.isAccelerometerAvailable){
            self.motionManager.accelerometerUpdateInterval = 1.0 / 60.0;
            void (^accelerometerCallback)(CMAccelerometerData*, NSError*) = ^(CMAccelerometerData* accelerometerData, NSError* error){
                double acelX = (double)accelerometerData.acceleration.x;
                double acelY = (double)accelerometerData.acceleration.y;
                double acelZ = (double)accelerometerData.acceleration.z;
                
                if (pen::State::Get()->mobileOnTiltCallback != nullptr){ (*pen::State::Get()->mobileOnTiltCallback)(acelX, acelY, acelZ);
                }
            };
            
            [self.motionManager startAccelerometerUpdatesToQueue:[NSOperationQueue currentQueue] withHandler:accelerometerCallback];
        }
        
        inst.iosDevice = view.device;

        /*Currently at max three different buffer types sent to metal shaders*/
        inst.dispatchSemaphore = dispatch_semaphore_create(3);
        
        App* app = new App();
        pen::State::Get()->mobileActive = true;
        app->CreateApplication("App", size.width, size.height, "");
        
        inst.iosCommandQueue = [inst.iosDevice newCommandQueue];
        inst.iosMtkView = view;
        [inst.iosMtkView setFramebufferOnly:NO];

    #ifndef TARGET_OS_IOS
        NSApplication* pApp = reinterpret_cast<NSApplication*>([inst.iosLaunchNotification object]);
        [pApp activateIgnoringOtherApps:true];
    #endif

        /*Initializes uniforms*/
    #ifndef TARGET_OS_IOS
        inst.iosUniformBuffer = [inst.iosDevice newBufferWithLength:MVP_MATRIX_SIZE options:MTLResourceStorageModeManaged];
    #else
        inst.iosUniformBuffer = [inst.iosDevice newBufferWithLength:MVP_MATRIX_SIZE options:MTLResourceStorageModeShared];
    #endif
        
        app->OnCreate();
    }
    instance = self;
    return self;
}

- (void)drawInMTKView:(nonnull MTKView *)view {
    /*Render loop*/
    (*pen::State::Get()->mobileOnRenderCallback)();
}

- (void)mtkView:(nonnull MTKView *)view drawableSizeWillChange:(CGSize)size
{
    /*Update the size of the screen*/
    pen::State* inst = pen::State::Get();
    if (size.width < inst->screenWidth || size.height < inst->screenHeight) {
        size.width = inst->screenWidth;
        size.height = inst->screenHeight;
    }

    inst->actualScreenHeight = size.height;
    inst->actualScreenWidth = size.width;
}

#ifndef TARGET_OS_IOS
- (BOOL)acceptsFirstResponder {
    return YES;
}

- (void)mouseDown:(NSEvent *)event {
    /*A click has started*/
    PenMacIOSState* inst = [PenMacIOSState Get];
    pen::State::Get()->keyableItem = nullptr;
    NSPoint location = event.locationInWindow;
    NSPoint localPoint = [self convertPoint:location fromView:inst.iosMtkView];
    
    double xPos = (double)location.x;
    double yPos = (double)location.y;
    /*Flip y position to start from the bottom*/
    yPos = inst->actualScreenHeight - yPos;

    /*Scale based on screen width and height*/
    xPos = xPos * inst->screenWidth / inst->actualScreenWidth;
    yPos = yPos * inst->screenHeight / inst->actualScreenHeight;
    pen::State::Get()->mobileMouseX = xPos;
    pen::State::Get()->mobileMouseY = yPos;
    pen::Pen::mobile_click_callback(pen::in::KEYS::MOUSE_LEFT, pen::in::KEYS::PRESSED, 0);
}

- (void)mouseDragged:(NSEvent *)event {
    /*A click is being dragged*/
    NSPoint location = event.locationInWindow;
    double xPos = (double)location.x;
    double yPos = (double)location.y;
    pen::State* inst = pen::State::Get();
    if ((inst->handleGUIDragEvents && inst->draggableItem != nullptr)
        || inst->handleCameraInput) {
        /*Flip y position to start from the bottom*/
        yPos = inst->actualScreenHeight - yPos;

        /*Scale based on screen width and height*/
        xPos = xPos * inst->screenWidth / inst->actualScreenWidth;
        yPos = yPos * inst->screenHeight / inst->actualScreenHeight;
        pen::State::Get()->mobileMouseX = xPos;
        pen::State::Get()->mobileMouseY = yPos;

        bool cameraHandled = pen::Render::Get()->camera.HandleInput(pen::in::KEYS::SPACE, pen::in::KEYS::HELD);
        if (!cameraHandled) {
            pen::ui::Item* item = (pen::ui::Item*)pen::State::Get()->draggableItem;
            item->OnDrag(item, &xPos, &yPos);
        }
    }
}

- (void)mouseUp:(NSEvent *)event {
    /*A click has ended*/
    PenMacIOSState* inst = [PenMacIOSState Get];
    pen::State::Get()->draggableItem = nullptr;
    NSPoint location = event.locationInWindow;
    NSPoint localPoint = [self convertPoint:location fromView:inst.iosMtkView];
    double xPos = (double)location.x;
    double yPos = (double)location.y;
    /*Flip y position to start from the bottom*/
    yPos = inst->actualScreenHeight - yPos;

    /*Scale based on screen width and height*/
    xPos = xPos * inst->screenWidth / inst->actualScreenWidth;
    yPos = yPos * inst->screenHeight / inst->actualScreenHeight;
    pen::State::Get()->mobileMouseX = xPos;
    pen::State::Get()->mobileMouseY = yPos;
    pen::Pen::mobile_click_callback(pen::in::KEYS::MOUSE_LEFT, pen::in::KEYS::RELEASED, 0);
}

- (void)keyDown:(NSEvent *)event{
    /*A key has been pressed*/
    NSString* characters = [event characters];
    const char* keys = [characters UTF8String];
    pen::State* inst = pen::State::Get();
    if ((inst->handleGUIKeyEvents && inst->keyableItem != nullptr) || inst->handleCameraInput) {
        bool cameraHandled = pen::Render::Get()->camera.HandleInput((int)keys[0], pen::int::KEYS::PRESSED);
        if (!cameraHandled) {
            pen::ui::Item* item = (pen::ui::Item*)pen::State::Get()->keyableItem;
            item->OnKey(item, (int)keys[0], pen::in::KEYS::PRESSED);
        }
    }
}

- (void)keyUp:(NSEvent *)event{
    /*A key has been released*/
    NSString* characters = [event characters];
    const char* keys = [characters UTF8String];
    pen::State* inst = pen::State::Get();
    if ((inst->handleGUIKeyEvents && inst->keyableItem != nullptr) || inst->handleCameraInput) {
        bool cameraHandled = pen::Render::Get()->camera.HandleInput((int)keys[0], pen::int::KEYS::RELEASED);
        if (!cameraHandled) {
            pen::ui::Item* item = (pen::ui::Item*)pen::State::Get()->keyableItem;
            item->OnKey(item, (int)keys[0], pen::in::KEYS::RELEASED);
        }
    }
}

- (NSSize)windowWillResize:(NSWindow *)sender
                    toSize:(NSSize)frameSize {
    /*Update the size of the window*/
    int width = (int) frameSize.width;
    int height = (int) frameSize.height;
    pen::State* inst = pen::State::Get();
    if (width < inst->screenWidth || height < inst->screenHeight) {
        width = inst->screenWidth;
        height = inst->screenHeight;
    }

    inst->actualScreenHeight = height;
    inst->actualScreenWidth = width;
}

#else
- (void) touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    /*A touch has started*/
    PenMacIOSState* inst = [PenMacIOSState Get];
    pen::State* stateInst = pen::State::Get();
    UITouch* touch = [[touches allObjects] objectAtIndex:0];
    CGPoint location = [touch locationInView:inst.iosMtkView];
    pen::State::Get()->mobileMouseX = (double)location.x;
    pen::State::Get()->mobileMouseY = (double)stateInst->actualScreenHeight - (double)location.y;
    pen::Pen::mobile_click_callback(pen::in::KEYS::MOUSE_LEFT, pen::in::KEYS::PRESSED, 0);
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    /*A touch is moving*/
    PenMacIOSState* inst = [PenMacIOSState Get];
    pen::State* stateInst = pen::State::Get();
    UITouch* touch = [[touches allObjects] objectAtIndex:0];
    CGPoint location = [touch locationInView:inst.iosMtkView];
    pen::State::Get()->mobileMouseX = (double)location.x;
    pen::State::Get()->mobileMouseY = (double)stateInst->actualScreenHeight - (double)location.y;
}

- (void) touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    /*A touch has ended*/
    PenMacIOSState* inst = [PenMacIOSState Get];
    pen::State* stateInst = pen::State::Get();
    UITouch* touch = [[touches allObjects] objectAtIndex:0];
    CGPoint location = [touch locationInView:inst.iosMtkView];
    pen::State::Get()->mobileMouseX = (double)location.x;
    pen::State::Get()->mobileMouseY = (double)stateInst->actualScreenHeight - (double)location.y;
    pen::Pen::mobile_click_callback(pen::in::KEYS::MOUSE_LEFT, pen::in::KEYS::RELEASED, 0);
}
#endif

+ (PenMacIOSMTKViewDelegate*) Get{
    /*Returns an instance of + PenMacIOSMTKViewDelegate*/
    return instance;
}

+ (void) UpdateUniforms: (pen::Mat4x4) mvp{
	/*Updates the uniform data*/
    PenMacIOSState* inst = [PenMacIOSState Get];
	simd::float4 colA = {mvp.matrix[0][0], mvp.matrix[1][0], mvp.matrix[2][0], mvp.matrix[3][0]};
	simd::float4 colB = {mvp.matrix[0][1], mvp.matrix[1][1], mvp.matrix[2][1], mvp.matrix[3][1]};
	simd::float4 colC = {mvp.matrix[0][2], mvp.matrix[1][2], mvp.matrix[2][2], mvp.matrix[3][2]};
	simd::float4 colD = {mvp.matrix[0][3], mvp.matrix[1][3], mvp.matrix[2][3], mvp.matrix[3][3]};
	simd::float4x4 mat = simd::float4x4(colA, colB, colC, colD);

	IOSUniformData* data = new IOSUniformData[1];
	data[0].uMVP = mat;

	int size = sizeof(IOSUniformData);

    if(!inst.iosUniformBuffer){
#ifndef TARGET_OS_IOS
        inst.iosUniformBuffer = [inst.iosDevice newBufferWithLength:size options:MTLResourceStorageModeManaged];
#else
        inst.iosUniformBuffer = [inst.iosDevice newBufferWithLength:size options:MTLResourceStorageModeShared];
#endif
    }
    
    memcpy([inst.iosUniformBuffer contents], data, size);
#ifndef TARGET_OS_IOS
    [inst.iosUniformBuffer didModifyRange: NSMakeRange(0, [inst.iosUniformBuffer length])];
#endif
}

+ (void) SubmitBatch:(id<MTLBuffer>) iosVertexBuffer
    :(BatchVertexData*) data
    :(int) size {
    /*Submits the vertex data to the GPU*/
    memcpy([iosVertexBuffer contents], data, size);
#ifndef TARGET_OS_IOS
    [iosVertexBuffer didModifyRange: NSMakeRange(0, [iosVertexBuffer length])];
#endif
}

+ (void) Render: (unsigned int) layerId
                 :(unsigned int) shapeType
                 :(int) indexCount
                 :(unsigned int) instanceCount{
    /*Renders the ios mtk view*/
    PenMacIOSState* inst = [PenMacIOSState Get];
    inst.isInstanced = instanceCount > 0 ? 1 : 0;
    id<MTLBuffer> iosVertexBuffer = [[PenMacIOSVertexBuffer Get].iosVertexBuffers objectForKey:[NSString stringWithFormat:@"%d", layerId]];
    id<MTLBuffer> iosIndexBuffer = [[PenMacIOSIndexBuffer Get].iosIndexBuffers objectForKey:[NSString stringWithFormat:@"%d", layerId]];
    dispatch_semaphore_wait(inst.dispatchSemaphore, DISPATCH_TIME_FOREVER);
    id<MTLCommandBuffer> command = [inst.iosCommandQueue commandBuffer];
    MTLRenderPassDescriptor* renderPassDescriptor = [inst.iosMtkView currentRenderPassDescriptor];
    inst.iosCommandEncoder = [command renderCommandEncoderWithDescriptor:renderPassDescriptor];
    inst.iosCommandBuffer = command;
    
    [command addCompletedHandler:^(id<MTLCommandBuffer> dispatchCallback) {
        dispatch_semaphore_signal( inst.dispatchSemaphore );
    }];

    [inst.iosCommandEncoder setRenderPipelineState:inst.iosPipelineState];
    if(inst.isInstanced > 0){
        [inst.iosCommandEncoder setRenderPipelineState:inst.iosInstancedPipelineState];
        [inst.iosCommandEncoder setVertexBuffer:inst.iosInstanceBuffer offset:0 atIndex:2];
    }
    [inst.iosCommandEncoder setVertexBuffer:iosVertexBuffer offset:0 atIndex:0];
    [inst.iosCommandEncoder setVertexBuffer:inst.iosUniformBuffer offset:0 atIndex:1];
    [inst.iosCommandEncoder setFragmentTextures:[PenMacIOSState GetTextures] withRange:NSMakeRange(0,8)];
    [inst.iosCommandEncoder setCullMode:MTLCullModeBack];
    [inst.iosCommandEncoder setFrontFacingWinding:MTLWindingCounterClockwise];
    
    MTLPrimitiveType type;

    switch (shapeType) {
    case 0:
        type = MTLPrimitiveTypePoint;
        break;
    case 1:
        type = MTLPrimitiveTypeLine;
        break;
    case 2:
    case 3:
    case 4:
    case 5:
    case 6:
        type = MTLPrimitiveTypeTriangle;
        break;
    default:
        type = MTLPrimitiveTypeTriangle;
        break;
    }

    [inst.iosCommandEncoder drawIndexedPrimitives:type indexCount:indexCount indexType:MTLIndexTypeUInt32 indexBuffer:iosIndexBuffer indexBufferOffset:0 instanceCount:(instanceCount + 1)];
    [inst.iosCommandEncoder endEncoding];
    
    id<MTLBlitCommandEncoder> blitCommandEncoder = [command blitCommandEncoder];
    id<CAMetalDrawable> previousDrawable = [PenMacIOSMTKViewDelegate Get].previousDrawable;
    id<MTLTexture> previousTexture = [PenMacIOSMTKViewDelegate Get].previousTexture;
    id<CAMetalDrawable> currentDrawable = [inst.iosMtkView currentDrawable];
    if(previousDrawable && currentDrawable && previousTexture != currentDrawable.texture){
        [blitCommandEncoder copyFromTexture:previousTexture toTexture:currentDrawable.texture];
        
//        int textureSize = currentDrawable.texture.width * currentDrawable.texture.height * 4;
//        unsigned char* previousTextureData = new unsigned char[textureSize];
//        unsigned char* currentTextureData = new unsigned char[textureSize];
//
//        [previousDrawable.texture getBytes:previousTextureData bytesPerRow:previousDrawable.texture.width * 4 fromRegion:MTLRegionMake2D(0, 0, previousDrawable.texture.width, previousDrawable.texture.height) mipmapLevel:0];
//        [currentDrawable.texture getBytes:currentTextureData bytesPerRow:currentDrawable.texture.width * 4 fromRegion:MTLRegionMake2D(0, 0, currentDrawable.texture.width, currentDrawable.texture.height) mipmapLevel:0];
//
//        for(int i = 0; i < textureSize; i+=4){
//            int a = (int)previousTextureData[i];
//            int b = (int)previousTextureData[i + 1];
//            int c = (int)previousTextureData[i + 2];
//            int d = (int)previousTextureData[i + 3];
//            if(i == 6000){
//                float tb = 1.0f;
//            }
//
//            if((int)previousTextureData[i + 3] > 0)
//               //&& ((int)previousTextureData[i] != 0) &&
//                 // ((int)previousTextureData[i + 1] != 255) &&
//                  //((int)previousTextureData[i + 2] != 0))
//            {
//                currentTextureData[i] = previousTextureData[i];
//                currentTextureData[i + 1] = previousTextureData[i + 1];
//                currentTextureData[i + 2] = previousTextureData[i + 2];
//                currentTextureData[i + 3] = previousTextureData[i + 3];
//            }else{
//                float t = 1.0f;
//            }
//        }
//
//        [currentDrawable.texture replaceRegion:MTLRegionMake2D(0, 0, currentDrawable.texture.width, currentDrawable.texture.height) mipmapLevel:0 withBytes:currentTextureData bytesPerRow:currentDrawable.texture.width * 4];
//        delete[] previousTextureData;
//        delete[] currentTextureData;
    }
    [blitCommandEncoder endEncoding];
    if(currentDrawable){// && layerId > 0){
        [PenMacIOSMTKViewDelegate Get].previousDrawable = currentDrawable;
        [PenMacIOSMTKViewDelegate Get].previousTexture = currentDrawable.texture;
    }else{
        //[PenMacIOSMTKViewDelegate Get].previousDrawable = nil;
    }
    [inst.iosCommandBuffer presentDrawable:currentDrawable];
    [inst.iosCommandBuffer commit];
}

+ (void) Background: (float) r
:(float) g
:(float) b
:(float) a{
    /*Updates the background of the mtk window*/
    PenMacIOSState* inst = [PenMacIOSState Get];
    [inst.iosMtkView setClearColor:MTLClearColorMake(r, g, b, a)];
}
@end

void MapMacIOSUpdateUniforms(pen::Mat4x4 mvp){
    /*Updates the uniform data*/
    [PenMacIOSMTKViewDelegate UpdateUniforms:mvp];
}

void MapMacIOSSubmitBatch(unsigned int layerId, BatchVertexData* data, int size){
    /*Submits the vertex data to the GPU*/
    NSMutableDictionary* vertexBuffers = [PenMacIOSVertexBuffer Get].iosVertexBuffers;
    [PenMacIOSMTKViewDelegate SubmitBatch:[vertexBuffers objectForKey:[NSString stringWithFormat:@"%d", layerId]] :data :size];
}

void MapMacIOSRender(unsigned int shapeType, int indexCount, unsigned int layerId, unsigned int instanceCount){
    /*Render the ios mtk view*/
    [PenMacIOSMTKViewDelegate Render:layerId :shapeType :indexCount :instanceCount];
}

void MapMacIOSBackground(float r, float g, float b, float a){
    /*Updates the background of the mtk window*/
    [PenMacIOSMTKViewDelegate Background:r :g :b :a];
}
#endif
