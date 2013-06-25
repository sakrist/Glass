
//
//  VBRenderController.m
//  Glass
//
//  Created by Volodymyr Boichentsov on 21/05/2013.
//  Copyright (c) 2013 Volodymyr Boichentsov. All rights reserved.
//

#import "VBKit.h"

#import "VBRenderController.h"

#include <stdlib.h>

#define NUM_ENV_OBJECTS 10
#define TEXTURE_FORMAT  GL_RGB16F
#define TEXTURE_TYPE    GL_HALF_FLOAT

@interface VBRenderController () {
    int _numPPTextures;
    int _shadowmapSize;
    int _causticmapSize;
    int _cubemapSize;
    
    bool _applyPostprocess;
    bool _adaptationIndex;
    bool _useGeometryShader;
    bool _doubleRefractionGlass;
    bool _doubleRefractionCaustic;
    bool _drawInfo;
    float _materialIOR;
    
    NSString *_modelName;
    
    
    VBFramebuffer* _reflectionRefractionBuffer; // plain
    VBFramebuffer* _shadowBuffer; // plain

    VBTextureObject* _reflectionRefractionTexture; // cubemap
    VBTextureObject* _shadowmapTexture; // cubemap
    
    VBTextureObject* _floorTexture;
    VBTextureObject* _brickTexture;
    VBTextureObject* _postprocessTextures[16];
    VBTextureObject* _bloomTexture;
    VBTextureObject* _adaptationTexture[2];
    
    
    VBFramebuffer* _screenBuffer;
    VBFramebuffer* _postprocessBuffer;
    VBFramebuffer* _causticBuffer;
    VBFramebuffer* _sceneDepthBuffer;
    
    VBFramebuffer* _reflectionRefractionCubemapBuffer;
    VBFramebuffer* _shadowCubemapBuffer;
    
    VBFramebuffer* _backfaceBuffer;
    VBFramebuffer* _frontfaceBuffer;
        
    VBProgramObject* _indoorProgram;
    VBProgramObject* _envProgram;
    VBProgramObject* _lightProgram;
    
    VBProgramObject* _indoorGSProgram;
    VBProgramObject* _envGSProgram;
    
    VBProgramObject* _depthRenderProgram;
    
    VBProgramObject* _distanceRenderProgram;
    VBProgramObject* _distanceRenderGSProgram;
    
    VBProgramObject* _glassSingleRefProgram;
    VBProgramObject* _glassDoubleRefProgram;
    
    VBProgramObject* _downsampleProgram;
    VBProgramObject* _brightpassProgram;
    VBProgramObject* _blurProgram;
    VBProgramObject* _finalPassProgram;
    VBProgramObject* _adaptationProgram;
    VBProgramObject* _backfaceProgram;
    VBProgramObject* _noiseReductionProgram;
    
    VBProgramObject* _causticSingleRefProgram;
    VBProgramObject* _causticDoubleRefProgram;
    
    VBBuffer* _floor;
    VBBuffer* _envCube;
    VBBuffer* _envSphere;
    VBBuffer* _glassObject;
    VBBuffer* _photonMap;


    GLKMatrix4 _envTransforms[NUM_ENV_OBJECTS];
    GLKMatrix4 _cubemapProjectionMatrix;
    GLKMatrix4Cube _cubemapMatrices;
    
    GLKMatrix4 _modelTransformation;
    
    GLKMatrix4 _lightTransform;
    
    GLKVector3 _modelCenter;
    
    bool _loded;
    
    CFAbsoluteTime _lastTime;
}

@property (nonatomic, retain) VBRender *render;
@property (nonatomic, retain) VBLight *lightSource;

@end

@implementation VBRenderController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (id) view {
    return _glView;
}

- (void) awakeFromNib {
    NSLog(@"%@" , _glView);

    
//    ENGINEPARAMS P = {0};
//    
//    P.eRender.bForwardContext = false;
//    P.eWindowStyle = RW_FIXED_NO_CAPTION;
//    P.vSizeX = 800;
//    P.vSizeY = 600;
//    //P.vPosX = 1100;
//    
//    core.setParameters(P);
//    ApplicationScene scene;
//    core.run(&scene);
    
}

- (void) mouseDragged:(NSEvent *)theEvent {
//        [theEvent deltaX]
    
    GLKVector3 p = _render.camera->_position;
    p.y += [theEvent deltaY];
    p.z += [theEvent deltaX];
    
    [_render.camera lookAtFrom:p
                            to:_render.camera->_view
                            up:GLKVector3Make(0.0, 1.0, 0.0)];
}


- (void)scrollWheel:(NSEvent *)event {
    GLKVector3 p = _render.camera->_position;
    p.x += [event scrollingDeltaY];
    
    [_render.camera lookAtFrom:p
                            to:_render.camera->_view
                            up:GLKVector3Make(0.0, 1.0, 0.0)];
}

- (void) setupGL {
    
    const GLubyte *v = glGetString(GL_VERSION);
    NSLog(@"OpenGL version %s", v);
    
    _shadowmapSize = 1024;
    _causticmapSize = 2048;
    _cubemapSize = 1024;
//    NSString *_modelName = @"boxes";
    
    float aspect = _glView.drawableWidth/_glView.drawableHeight;
    [[VBCore c] setAspect:aspect];
    [[VBCore c] setViewSize:GLKVector2Make(_glView.drawableWidth, _glView.drawableHeight)];
    
    _render = [[VBRender alloc] init];
    
    [_render blendFunction:GL_SRC_ALPHA second:GL_ONE_MINUS_SRC_ALPHA];
    
    [_render.camera perspectiveWithFov:M_PI_4 aspect:aspect near:1.0 far:4096.0];
    
    GLKVector3 from = GLKVector3Make(400.0, 150.0, 0.0);
//    from = GLKVector3Make(-285, 193, -31.0);
    [_render.camera lookAtFrom:from
                            to:GLKVector3Make(0.0, 50.0, 0.0)
                            up:GLKVector3Make(0.0, 1.0, 0.0)];
    [_render.camera setLockUpVector:true];
    [_render blend:false];
    [_render cullFace:GL_BACK];
    
    
    _screenBuffer = [VBFramebuffer framebuffer:@"Screen"
                                          size:_glView.frame.size
                             texInternalFormat:TEXTURE_FORMAT
                                     texFormat:GL_RGB
                                       texType:TEXTURE_TYPE];
    
    
    _sceneDepthBuffer = [VBFramebuffer framebuffer:@"Env depth" size:CGSizeMake(_causticmapSize, _causticmapSize) texInternalFormat:0 texFormat:0 texType:0];
    
    _causticBuffer = [VBFramebuffer framebuffer:@"Caustic buffer" size:CGSizeMake(_causticmapSize, _causticmapSize) texInternalFormat:GL_R16F texFormat:GL_RGB texType:GL_HALF_FLOAT depthInternalFormat:0 depthFormat:0 depthType:0];
    [_causticBuffer addSameRendertarget];
    [[[_causticBuffer renderTargets] objectAtIndex:0] setWrap:GL_CLAMP_TO_EDGE :GL_CLAMP_TO_EDGE];
    [[[_causticBuffer renderTargets] objectAtIndex:1] setWrap:GL_CLAMP_TO_EDGE :GL_CLAMP_TO_EDGE];
    

    _reflectionRefractionCubemapBuffer = [VBFramebuffer createCubemapFramebuffer:@"Cubemap single buffer" size:_cubemapSize internalFormat:TEXTURE_FORMAT format:GL_RGB type:TEXTURE_TYPE];
    
    _shadowCubemapBuffer = [VBFramebuffer createCubemapFramebuffer:@"Cubemap double buffer" size:_shadowmapSize internalFormat:GL_RGB8 format:GL_RGB type:GL_UNSIGNED_BYTE];
    
    
    _backfaceBuffer = [VBFramebuffer framebuffer:@"Backface" size:CGSizeMake(_causticmapSize, _causticmapSize) texInternalFormat:GL_RGBA16F texFormat:GL_RGBA texType:GL_HALF_FLOAT];
    _frontfaceBuffer = [VBFramebuffer framebuffer:@"Frontface" size:CGSizeMake(_causticmapSize, _causticmapSize) texInternalFormat:GL_RGBA16F texFormat:GL_RGBA texType:GL_HALF_FLOAT];
    
    
    [[[_screenBuffer renderTargets] objectAtIndex:0] setFiltrationMin:GL_NEAREST mag:GL_NEAREST];
    [[_screenBuffer depthBuffer] setFiltrationMin:GL_NEAREST mag:GL_NEAREST];

    [[[_backfaceBuffer renderTargets] objectAtIndex:0] setFiltrationMin:GL_NEAREST mag:GL_NEAREST];
    [[_backfaceBuffer depthBuffer] setFiltrationMin:GL_NEAREST mag:GL_NEAREST];

    [[[_frontfaceBuffer renderTargets] objectAtIndex:0] setFiltrationMin:GL_NEAREST mag:GL_NEAREST];
    [[_frontfaceBuffer depthBuffer] setFiltrationMin:GL_NEAREST mag:GL_NEAREST];
    
    
    CGSize s = CGSizeMake([self.view frame].size.width/2, [self.view frame].size.height/2);
    
    _postprocessBuffer = [VBFramebuffer framebuffer:@"PPBuffer" size:s
                                  texInternalFormat:TEXTURE_FORMAT texFormat:GL_RGB texType:TEXTURE_TYPE depthInternalFormat:0 depthFormat:0 depthType:0];
                          
    int sx = [self.view frame].size.width / 4;
    int sy = [self.view frame].size.height / 4;
    int i = 0;
    while ( (sx >= 1) && (sy >= 1) ) {
        
        NSString *texName = [NSString stringWithFormat:@"_pptexture %d", i];
        _postprocessTextures[i] = [[VBResourceManager instance] genarateTexture2DWithName:texName
                                                                                size:CGSizeMake(sx, sy)
                                                                      internalFormat:TEXTURE_FORMAT
                                                                              format:GL_RGB
                                                                                type:TEXTURE_TYPE
                                                                                data:NULL];
        
        [_postprocessTextures[i] setWrap:GL_CLAMP_TO_EDGE :GL_CLAMP_TO_EDGE];
        
        if (i == 0) {
            _bloomTexture = [[VBResourceManager instance] genarateTexture2DWithName:@"bloom"
                                                               size:CGSizeMake(sx, sy)
                                                     internalFormat:TEXTURE_FORMAT
                                                             format:GL_RGB
                                                               type:TEXTURE_TYPE
                                                               data:NULL];
            
            [_bloomTexture setWrap:GL_CLAMP_TO_EDGE :GL_CLAMP_TO_EDGE];            
        }
        
        sx /= 2;
        sy /= 2;
        
        if ((sx == 0) && (sy != 0)) sx = 1;
        if ((sy == 0) && (sx != 0)) sy = 1;
        
        i++;
    }
    _numPPTextures = i;
    
    
    
    _adaptationTexture[0] = [[VBResourceManager instance] genarateTexture2DWithName:@"adaptation texture 1" size:CGSizeMake(1,1)
                                                                     internalFormat:TEXTURE_FORMAT format:GL_RGB type:TEXTURE_TYPE data:0];
    _adaptationTexture[1] = [[VBResourceManager instance] genarateTexture2DWithName:@"adaptation texture 2" size:CGSizeMake(1,1)
                                                                     internalFormat:TEXTURE_FORMAT format:GL_RGB type:TEXTURE_TYPE data:0];
    _adaptationIndex = 0;
    
    
    _reflectionRefractionBuffer = [VBFramebuffer framebuffer:@"Cubemap framebuffer" size:CGSizeMake(_cubemapSize, _cubemapSize) texInternalFormat:0 texFormat:0 texType:0];
    _reflectionRefractionTexture = [[VBResourceManager instance] genarateCubeTextureWithName:@"Env cubemap" size:CGSizeMake(_cubemapSize, _cubemapSize) internalFormat:TEXTURE_FORMAT format:GL_RGB type:TEXTURE_TYPE datas:nil];
    
    _shadowBuffer = [VBFramebuffer framebuffer:@"Shadowmap buffer" size:CGSizeMake(_shadowmapSize, _shadowmapSize) texInternalFormat:0 texFormat:0 texType:0];
    _shadowmapTexture = [[VBResourceManager instance] genarateCubeTextureWithName:@"Shadowmap cube texture"
                         size:CGSizeMake(_shadowmapSize, _shadowmapSize) internalFormat:GL_RGB format:GL_RGB type:GL_UNSIGNED_BYTE datas:nil];

    
    _lightSource = [[VBLight alloc] init];
    [_lightSource perspectiveWithFov:M_PI_4 aspect:1.0 near:100.0 far:1500.0];
    _lightSource.color = GLKVector3Make(1.0, 1.0, 1.0);
    
    
    // LOAD SHADERS
    
    _glassSingleRefProgram = [VBProgramObject loadProgram:@"glass/glass.program"];
    [_glassSingleRefProgram setUniformTextures:[NSMutableArray arrayWithObject:@"environment_map"]];

    _glassDoubleRefProgram = [VBProgramObject loadProgram:@"glass/glass.program" param:@"DOUBLE_REFRACTION"];
    [_glassDoubleRefProgram setUniformTextures:[NSMutableArray arrayWithObjects:@"environment_map",
                                                @"backface_texture",
                                                @"backface_depth",
                                                nil ]];

    
    _backfaceProgram = [VBProgramObject loadProgram:@"glass/backface_normals.program"];
    
    _depthRenderProgram = [VBProgramObject loadProgram:@"env/depth_render.program"];
    _distanceRenderGSProgram = [VBProgramObject loadProgram:@"env/distance_render_gs.program" param:@"WITH_GS"];
    _distanceRenderProgram = [VBProgramObject loadProgram:@"env/distance_render.program"];
    
    
    NSMutableArray *texturesArray = [NSMutableArray arrayWithObjects:@"diffuse_texture", @"cubemap_shadow", @"caustic_texture", nil];
    
    _envProgram = [VBProgramObject loadProgram:@"env/env.program"];
    [_envProgram setUniformTextures:texturesArray];
    
    _envGSProgram = [VBProgramObject loadProgram:@"env/env_gs.program" param:@"WITH_GS"];
    [_envGSProgram setUniformTextures:texturesArray];
    
    _indoorProgram = [VBProgramObject loadProgram:@"env/indoor.program"];
    [_indoorProgram setUniformTextures:texturesArray];
    
    _indoorGSProgram = [VBProgramObject loadProgram:@"env/indoor_gs.program" param:@"WITH_GS"];
    [_indoorGSProgram setUniformTextures:texturesArray];
    
    _lightProgram = [VBProgramObject loadProgram:@"light/light.program"];
    _downsampleProgram = [VBProgramObject loadProgram:@"postprocess/downsample.program"];
    _blurProgram = [VBProgramObject loadProgram:@"postprocess/linearBlur.program"];
    _noiseReductionProgram = [VBProgramObject loadProgram:@"postprocess/noiseReduction.program"];
    
    
    texturesArray = [NSMutableArray arrayWithObjects:@"refractive_normals", @"refractive_depth", @"receiver_depth", nil];
    
    _causticSingleRefProgram = [VBProgramObject loadProgram:@"caustic/single_refraction_tex2d.program"];
    [_causticSingleRefProgram setUniformTextures:texturesArray];
    
    [texturesArray addObject:@"refractive_backface_normals"];
    [texturesArray addObject:@"refractive_backface_depth"];
    
    _causticDoubleRefProgram = [VBProgramObject loadProgram:@"caustic/single_refraction_tex2d.program" param:@"DOUBLE_REFRACTION"];
    [_causticDoubleRefProgram setUniformTextures:texturesArray];

    
    texturesArray = [NSMutableArray arrayWithObjects:@"source_image", @"luminocity_texture", nil];
    
    _brightpassProgram = [VBProgramObject loadProgram:@"postprocess/brightpass.program"];
    [_brightpassProgram setUniformTextures:texturesArray];
    
    [texturesArray addObject:@"bloom_image"];
    _finalPassProgram = [VBProgramObject loadProgram:@"postprocess/hdrFinalPass.program"];
    [_finalPassProgram setUniformTextures:texturesArray];

    texturesArray = [NSMutableArray arrayWithObjects:@"new_value", @"old_value", nil];
    
    _adaptationProgram = [VBProgramObject loadProgram:@"postprocess/adaptation.program"];
    [_adaptationProgram setUniformTextures:texturesArray];

    // NEXT STAGE
    _floorTexture = [VBTextureObject loadTexture:[[NSBundle mainBundle] pathForResource:@"floor.jpg" ofType:nil]];
    _brickTexture = [VBTextureObject loadTexture:[[NSBundle mainBundle] pathForResource:@"texture2.jpg" ofType:nil]];
    
    _floor = [VBBuffer createBox:@"room" dimension:GLKVector3Make(1024.0, 1024.0, 1024.0) inNormals:false];
    _envCube = [VBBuffer createBox:@"env cube" dimension:GLKVector3Make(1.0, 1.0, 1.0) inNormals:false];

    _envSphere = [VBBuffer createSphere:@"env sphere" radius:5.0 ver:9 hor:9];

    for (int i = 0; i < NUM_ENV_OBJECTS; i++)
    {
        float n = 25.0f + 25.0f * rand() / RAND_MAX;
        GLKVector3 dim = GLKVector3Make(n,n,n);
        
        GLKVector3 pos = fromSpherical(0.0f, M2_PI * rand() / RAND_MAX);
        
        n =  250.0f + 500.0f * rand() / RAND_MAX;
        pos = GLKVector3Multiply(GLKVector3Make(n,n,n), GLKVector3Normalize(pos));
        pos.y = dim.y;
        
        _envTransforms[i] = GLKMatrix4TranslateWithVector3(GLKMatrix4Identity, pos);
        _envTransforms[i] = GLKMatrix4ScaleWithVector3(_envTransforms[i], dim);
    }
    
    
    float radius = 50.0;
    _modelCenter = GLKVector3Make(0.0, radius, 0.0);
//    _glassObject = [VBBuffer createSphere:@"model" radius:radius ver:36 hor:36];
    

    _glassObject = [VBBuffer loadModel:[[NSBundle mainBundle] pathForResource:@"dragon" ofType:@"bin"] withScale:0.4];
    _modelCenter = _glassObject.center;
    
    
    
    _cubemapProjectionMatrix = GLKMatrix4MakePerspective(M_PI_2, 1.0, 1.0, 2048);
    _cubemapMatrices = [VBCamera cubemapMatrix:_cubemapProjectionMatrix pointOfView:_modelCenter];
    
    _photonMap = [VBBuffer createPhotonMap:@"Photon map" size:GLKVector2Make(_causticmapSize, _causticmapSize)];
    
    _materialIOR = 1.41f;
    
    
    _applyPostprocess = false;
    _useGeometryShader = true;
    _doubleRefractionGlass = true;
    _drawInfo = false;
    
    _modelTransformation = GLKMatrix4MakeTranslation(_modelCenter.x, _modelCenter.y, _modelCenter.z);
    
    _modelTransformation = GLKMatrix4TranslateWithVector3(_modelTransformation, _modelCenter);
    _lightTransform = GLKMatrix4Identity;
    
    _loded = true;
}




- (void) glkViewControllerUpdate:(id)controller {
    
    
    if (_loded) {
        
//        float d = CFAbsoluteTimeGetCurrent()-_lastTime;
        
        float t = [VBCore c].runTime / 10.0f;
        GLKVector3 _b = GLKVector3Make(cos(t), 1.0f + 0.25f * cos(t), sin(t));
        
        GLKVector3 lp = GLKVector3Multiply(GLKVector3Make(384.0, _modelCenter.y + 200.0f, 384.0), _b);
        
        [_lightSource lookAtFrom:lp to:_modelCenter up:GLKVector3Make(0.0, 1.0, 0.0)];
        
        
//        _lightTransform = GLKMatrix4Rotate(_lightTransform, 0.01, 1, 0, 0);
//
//        _lightSource.modelViewMatrix = GLKMatrix4Translate(_lightSource.modelViewMatrix, 1000, 0, 0);
//        _lightSource.modelViewMatrix = GLKMatrix4Multiply(_lightSource.modelViewMatrix, _lightTransform);
//        _lightSource.modelViewMatrix = GLKMatrix4Translate(_lightSource.modelViewMatrix, -1000, 0, 0);
//        [_lightSource update];
//        
//        
//        GLKVector3 p = GLKMatrix4MultiplyVector3(_lightSource.modelViewProjectionMatrix, _lightSource.position);
//        [_lightSource setPosition:p];
        
//        _lightSource.modelViewMatrix = GLKMatrix4Multiply(_lightSource.modelViewMatrix,_lightTransform);
//        [_lightSource update];
        

        _modelTransformation = GLKMatrix4Rotate(_modelTransformation, 0.01, 0.0, -2.0, 0.0);
            
        _cubemapMatrices = [VBCamera cubemapMatrix:_cubemapProjectionMatrix pointOfView:_modelCenter];
        
        _envTransforms[0].m32 = sin(t / 10.0f) * 500.0f;
        
    }
    [VBCore c].runTime += [VBCore c].frameTime;
    _lastTime = CFAbsoluteTimeGetCurrent();
}

- (void) glkView:(GLKView *)view drawInRect:(CGRect)rect {

    
    if (_loded) {
        [self renderShadowmap];

        [self prerenderCaustic];
        [self renderCaustic];

        [self prerenderGlass];

        if (_applyPostprocess) {
            [_render bindFramebuffer:_screenBuffer];
        } else {
            [_render bindFramebuffer:0];
            glBindFramebuffer(GL_FRAMEBUFFER, 0);
        }
        
        glClear(GL_DEPTH_BUFFER_BIT);

        [self renderEnvironment:_render.camera.position modelViewProjection:_render.camera.modelViewProjectionMatrix];
        [self renderGlass];
        
        [_render blend:false];
        
        if (_applyPostprocess) {
            [self applyPostprocess];
            
            [_render bindFramebuffer:0];
            glBindFramebuffer(GL_FRAMEBUFFER, 0);
            
            [_finalPassProgram bind];
//            [_render bindTexture:0 texture:0];
            [_render bindTexture:0 texture:[[_screenBuffer renderTargets] objectAtIndex:0]];
            [_render bindTexture:1 texture:[self luminanceTexture]];
//            [_render bindTexture:2 texture:0];
            [_render bindTexture:2 texture:_bloomTexture];

            [_render drawFSQ];
        }
        [_render blend:true];
        
    }
    
    GL_CHECK_ERROR
}



- (void) prerenderGlass {
    
    [_render bindFramebuffer:nil];
    
    if (_useGeometryShader)
    {
        [_render bindFramebuffer:_reflectionRefractionCubemapBuffer];
        glClear(GL_DEPTH_BUFFER_BIT);
        [self renderEnvironmentToCubeMap:_modelCenter];
        
    } else {
        [_render bindFramebuffer:_reflectionRefractionBuffer];
        
        for (int i = 0; i < 6; i++) {
            [_reflectionRefractionBuffer setCurrentRenderTarget: _reflectionRefractionTexture target:GL_TEXTURE_CUBE_MAP_POSITIVE_X + i];
            [_reflectionRefractionBuffer setDrawBuffersCount:1];
            
            glClear(GL_DEPTH_BUFFER_BIT);
            [self renderEnvironment:_modelCenter modelViewProjection:_cubemapMatrices.m[i]];
        }
    }
    
    [_render bindFramebuffer:nil];
    [_render bindFramebuffer:_sceneDepthBuffer];
    
    glClear(GL_DEPTH_BUFFER_BIT);
    [self renderEnvironmentToDepth:_render.camera.position modelViewProjection:_render.camera.modelViewProjectionMatrix];
    
    [_render bindFramebuffer:_backfaceBuffer];
    
    glClear(GL_DEPTH_BUFFER_BIT);
    
    [_backfaceProgram bind];
    [_backfaceProgram setMVPMatrix:_render.camera.modelViewProjectionMatrix];
    [_backfaceProgram setCameraPosition:_render.camera.position];
    [_backfaceProgram setUniform:@"mTransform" m:_modelTransformation];
    
    [_render cullFace:GL_FRONT];
    [_glassObject renderAll];
    [_render cullFace:GL_BACK];
}

- (void) renderGlass {
    
    VBProgramObject* glass = _doubleRefractionGlass ? _glassDoubleRefProgram : _glassSingleRefProgram;
    
    [glass bind];
    [glass setMVPMatrix:_render.camera.modelViewProjectionMatrix];
    [glass setCameraPosition:_render.camera.position];
    [glass setPrimaryLightPosition:_lightSource.position];
    
    [glass setUniform:@"cLightColor" v3:_lightSource.color];
    [glass setUniform:@"mTransform" m:_modelTransformation];
    [glass setUniform:@"indexOfRefraction" f:(1.0f / _materialIOR)];
    
    if (_doubleRefractionGlass)
    {
        [glass setUniform:@"mModelViewProjectionInverse" m:_render.camera.inverseMVPMatrix];
        [[VBResourceManager instance] bindTexture:1 texture:[_backfaceBuffer.renderTargets objectAtIndex:0]];
        [[VBResourceManager instance] bindTexture:2 texture:_backfaceBuffer.depthBuffer];
    }
    
    VBTextureObject *tex = _useGeometryShader ? [_reflectionRefractionCubemapBuffer.renderTargets objectAtIndex:0] : _reflectionRefractionTexture;
    
    [[VBResourceManager instance] bindTexture:0 texture:tex];
    [_glassObject renderAll];
}


- (void) prerenderCaustic {
    
    [_render bindFramebuffer:_sceneDepthBuffer];
    
    GL_CHECK_ERROR
    glClear(GL_DEPTH_BUFFER_BIT);
    GL_CHECK_ERROR
    [self renderEnvironmentToDepth:_lightSource.position modelViewProjection:_lightSource.modelViewProjectionMatrix];
    
    GL_CHECK_ERROR
    
    [_render bindFramebuffer:_frontfaceBuffer];
    glClear(GL_DEPTH_BUFFER_BIT);
    
    [_glassObject bind];
    
    [_backfaceProgram bind];
    [_backfaceProgram setMVPMatrix:_lightSource.modelViewProjectionMatrix];
    [_backfaceProgram setUniform:@"mTransform" m:_modelTransformation];
    [_backfaceProgram setUniform:@"indexOfRefraction" f:(1.0f / _materialIOR)];
    [_glassObject drawAllElements];
    
    [_render bindFramebuffer:_backfaceBuffer];
    glClear(GL_DEPTH_BUFFER_BIT);
    
    [_backfaceProgram bind];
    [_backfaceProgram setMVPMatrix:_lightSource.modelViewProjectionMatrix];
    [_backfaceProgram setUniform:@"mTransform" m:_modelTransformation];
    [_backfaceProgram setUniform:@"indexOfRefraction" f:_materialIOR];
    
    [self.render cullFace:GL_FRONT];
    [_glassObject drawAllElements];
    [self.render cullFace:GL_BACK];
    
    [_glassObject unbind];
}

- (void) renderCaustic {
    
    [_render bindFramebuffer:nil];
    [_render bindFramebuffer:_causticBuffer];
    [_causticBuffer setCurrentRenderTargetInt:0];
    
    glClear(GL_COLOR_BUFFER_BIT);
    
    glDepthMask(GL_FALSE);
    glDepthFunc(GL_ALWAYS);
    [_render blendFunction:GL_ONE second:GL_ONE];
    [_render blend:true];
    
    [[VBResourceManager instance] bindTexture:0 texture:[_frontfaceBuffer.renderTargets objectAtIndex:0]];
    [[VBResourceManager instance] bindTexture:1 texture:_frontfaceBuffer.depthBuffer];
    [[VBResourceManager instance] bindTexture:2 texture:_sceneDepthBuffer.depthBuffer];

    if (_doubleRefractionCaustic)
    {
        [[VBResourceManager instance] bindTexture:3 texture:[_backfaceBuffer.renderTargets objectAtIndex:0]];
        [[VBResourceManager instance] bindTexture:4 texture:_backfaceBuffer.depthBuffer];
    }
    VBProgramObject* caustic = _doubleRefractionCaustic ? _causticDoubleRefProgram : _causticSingleRefProgram;
    
    [caustic bind];
    [caustic setCameraPosition:_lightSource.position];
    [caustic setMVPMatrix:_lightSource.modelViewProjectionMatrix];
    [caustic setUniform:@"mInverseModelViewProjection" m:_lightSource.inverseMVPMatrix];
    
    [_photonMap renderAll];
    [_render blend:false];
    
    [_causticBuffer setCurrentRenderTargetInt:1];
    [_noiseReductionProgram bind];
    
    VBTextureObject *rt0 = [[_causticBuffer renderTargets] objectAtIndex:0];
    [_noiseReductionProgram setUniform:@"texel"  v2:rt0.texel];
    [[VBResourceManager instance] bindTexture:0 texture:rt0];
    [_render drawFSQ];
    
    glDepthFunc(GL_LESS);
    glDepthMask(GL_TRUE);
    
    [_render blendFunction:GL_SRC_ALPHA second:GL_ONE_MINUS_SRC_ALPHA];
}


- (void) renderShadowmap {
    
    if (_useGeometryShader) {
        
        [self renderEnvironmentToDepthCubeMap:_lightSource.position];
        
    } else {
        GLKMatrix4Cube cm_matrix = [VBCamera cubemapMatrix:_cubemapProjectionMatrix pointOfView:_lightSource.position];
        
        [self.render bindFramebuffer:_shadowBuffer];
        glClear(GL_DEPTH_BUFFER_BIT);
        
        [_distanceRenderProgram use];
        [_distanceRenderProgram setPrimaryLightPosition:_lightSource.position];
        
        glPolygonOffset(4, 4);
        glEnable(GL_POLYGON_OFFSET_FILL);
        glClearColor(1.0e+5, 1.0e+5, 1.0e+5, 0.0);
        for (int i = 0; i < 6; i++)
        {
            [_distanceRenderProgram setMVPMatrix:cm_matrix.m[i]];
            [_shadowBuffer setCurrentRenderTarget:_shadowmapTexture target:GL_TEXTURE_CUBE_MAP_POSITIVE_X + i];
            [_shadowBuffer setDrawBuffersCount:1];

            glClear(GL_DEPTH_BUFFER_BIT | GL_COLOR_BUFFER_BIT);
            [self renderEnvObjects:_distanceRenderProgram];
        }
        glClearColor(0.0, 0.0, 0.0, 0.0);
        glDisable(GL_POLYGON_OFFSET_FILL);
    }
}


- (void) renderEnvObjects:(VBProgramObject*) program {
    
    [_envCube bind];
    for (int i = 0; i < NUM_ENV_OBJECTS; i++) {
        [program _uniformWithName:@"mTransform" value:&_envTransforms[i]];
        [_envCube drawAllElements];
    }
    [_envCube unbind];
}


- (void) renderEnvironmentToCubeMap:(GLKVector3)cameraPosition {
    
    [[VBResourceManager instance] bindTexture:1 texture: (_useGeometryShader ? [_shadowCubemapBuffer.renderTargets objectAtIndex:0] : _shadowmapTexture)];
    [[VBResourceManager instance] bindTexture:2 texture:[_causticBuffer.renderTargets objectAtIndex:1]];
    [_render cullFace:GL_FRONT];

    [[VBResourceManager instance] bindTexture:0 texture:_floorTexture];
    
    [_indoorGSProgram bind];
    [_indoorGSProgram setPrimaryLightPosition:_lightSource.position];
    [_indoorGSProgram setLightProjectionMatrix:_lightSource.modelViewProjectionMatrix];
    [_indoorGSProgram _uniformWithName:@"mModelViewProjection[0]" value:&(_cubemapMatrices.v) count:6];
    [_indoorGSProgram setUniform:@"mTransform" m:GLKMatrix4MakeTranslation(0.0, 1024.0, 0.0)];
    [_indoorGSProgram setUniform:@"cLightColor" v3:_lightSource.color];
    [_floor renderAll];
    
    [_render cullFace:GL_BACK];
    
    [[VBResourceManager instance] bindTexture:0 texture:[VBResourceManager instance].DEFTEX_white];
    [_envSphere renderAll];
    
    [[VBResourceManager instance] bindTexture:0 texture:_brickTexture];
    
    [_envGSProgram bind];
    [_envGSProgram setCameraPosition:cameraPosition];
    [_envGSProgram setLightProjectionMatrix:_lightSource.modelViewProjectionMatrix];
    [_envGSProgram setPrimaryLightPosition:_lightSource.position];
    [_envGSProgram _uniformWithName:@"mModelViewProjection[0]" value:&(_cubemapMatrices.v) count:6];
    [_envGSProgram setUniform:@"cLightColor" v3:_lightSource.color];
    [self renderEnvObjects:_envGSProgram];
}

- (void) renderEnvironmentToDepthCubeMap:(GLKVector3)cameraPosition {
    
    GLKMatrix4Cube cm_matrix = [VBCamera cubemapMatrix:_cubemapProjectionMatrix pointOfView:cameraPosition];
    
    glClearColor(1.0e+5, 1.0e+5, 1.0e+5, 0.0);
    [self.render bindFramebuffer:_shadowCubemapBuffer];
    glClear(GL_DEPTH_BUFFER_BIT | GL_COLOR_BUFFER_BIT);
    glClearColor(0.0, 0.0, 0.0, 0.0);

    
    GL_CHECK_ERROR
    
    glPolygonOffset(4, 4);
    glEnable(GL_POLYGON_OFFSET_FILL);
    
    [_distanceRenderGSProgram bind];
    [_distanceRenderGSProgram setPrimaryLightPosition:_lightSource.position];
    [_distanceRenderGSProgram _uniformWithName:@"mModelViewProjection[0]" value:&(cm_matrix.v) count:6];
    
    [self renderEnvObjects:_distanceRenderGSProgram];
    
    glDisable(GL_POLYGON_OFFSET_FILL);
    
    GL_CHECK_ERROR
}

- (void) renderEnvironmentToDepth:(GLKVector3)cameraPosition  modelViewProjection:(GLKMatrix4)modelViewProjection {
    
    [_depthRenderProgram bind];
    [_depthRenderProgram setMVPMatrix:modelViewProjection];
    [_depthRenderProgram setUniform:@"mTransform" m:GLKMatrix4MakeTranslation(0.0, 1024.0, 0.0)];
    
    [self.render cullFace:GL_FRONT];
    [_floor renderAll];
    [self.render cullFace:GL_BACK];
    
    [self renderEnvObjects:_depthRenderProgram];
}

- (void) renderEnvironment:(GLKVector3)cameraPosition  modelViewProjection:(GLKMatrix4)modelViewProjection {
    
    [[VBResourceManager instance] bindTexture:1 texture: (_useGeometryShader ? [_shadowCubemapBuffer.renderTargets objectAtIndex:0] : _shadowmapTexture)];
    [[VBResourceManager instance] bindTexture:2 texture:[_causticBuffer.renderTargets objectAtIndex:1]];
    [_render cullFace:GL_FRONT];
    
    [_indoorProgram bind];
    [_indoorProgram setMVPMatrix:modelViewProjection];
    [_indoorProgram setPrimaryLightPosition:_lightSource.position];
    [_indoorProgram setLightProjectionMatrix:_lightSource.modelViewProjectionMatrix];
    [_indoorProgram setUniform:@"mTransform" m:GLKMatrix4MakeTranslation(0.0, 1024.0, 0.0)];
    [_indoorProgram setUniform:@"cLightColor" v3:_lightSource.color];
    
    [[VBResourceManager instance] bindTexture:0 texture:_floorTexture];
    [_floor renderAll];
    
    [_render cullFace:GL_BACK];
    [[VBResourceManager instance] bindTexture:0 texture:_brickTexture];
    
    [_envProgram bind];
    [_envProgram setCameraPosition:cameraPosition];
    [_envProgram setMVPMatrix:modelViewProjection];
    [_envProgram setPrimaryLightPosition: _lightSource.position];
    [_envProgram setLightProjectionMatrix: _lightSource.modelViewProjectionMatrix];
    [_envProgram setUniform: @"cLightColor" v3:_lightSource.color];
    [self renderEnvObjects:_envProgram];

    
    [_lightProgram bind];
    [_lightProgram setMVPMatrix:modelViewProjection];
    [_lightProgram setUniform:@"mTransform" m:GLKMatrix4MakeTranslation(_lightSource.position.x, _lightSource.position.y, _lightSource.position.z)];
    [_lightProgram setUniform:@"cLightColor" v3:_lightSource.color];
    [_envSphere renderAll];
}




// Post process

- (void) applyPostprocess {
    
    [_render bindFramebuffer:_postprocessBuffer];
    [_postprocessBuffer setCurrentRenderTargetInt:0];
    
    [_downsampleProgram bind];
    [_downsampleProgram setUniform:@"vTexel" v2:[[_screenBuffer.renderTargets objectAtIndex:0] texel]];
    
    [_render bindTexture:0 texture:[_screenBuffer.renderTargets objectAtIndex:0]];
    [_render drawFSQ];
    
    [_render bindTexture:0 texture:[_postprocessBuffer.renderTargets objectAtIndex:0]];
    [_downsampleProgram setUniform:@"vTexel" v2:[[_postprocessBuffer.renderTargets objectAtIndex:0] texel]];
    for (int i = 0; i < _numPPTextures; i++) {
        
        [_postprocessBuffer setCurrentRenderTarget:_postprocessTextures[i]];
        
        if (i != 0)
        {
            [_render bindTexture:0 texture:_postprocessTextures[i - 1]];
            [_downsampleProgram setUniform:@"vTexel" v2:[_postprocessTextures[i - 1] texel]];
        }
        
        [_render drawFSQ];
    }
    
    [_postprocessBuffer setCurrentRenderTarget:[self luminanceTexture]];
    [_adaptationProgram bind];
    [_adaptationProgram setUniform:@"time" f: 2.0f * [VBCore c].frameTime ];
    [_render bindTexture:0 texture:_postprocessTextures[_numPPTextures - 1]];
    [_render bindTexture:1 texture:[self nextLuminanceTexture]];
    [_render drawFSQ];
    
    [_postprocessBuffer setCurrentRenderTarget:_bloomTexture];
    [_brightpassProgram bind];
    [_render bindTexture:0 texture:_postprocessTextures[0]];
    [_render bindTexture:1 texture:[self luminanceTexture]];
    [_render drawFSQ];
    
    const float blurRadius = 5.0;
    
    [_blurProgram bind];
    
    [_postprocessBuffer setCurrentRenderTarget:_postprocessTextures[0]];
    [_blurProgram setUniform:@"texel_radius" v3:GLKVector3Make( [_postprocessTextures[0] texel].x, 0.0, blurRadius )];
    [_render bindTexture:0 texture:_bloomTexture];
    [_render drawFSQ];
    
    [_postprocessBuffer setCurrentRenderTarget:_bloomTexture];
    [_blurProgram setUniform:@"texel_radius" v3:GLKVector3Make( 0.0, [_postprocessTextures[0] texel].y, blurRadius )];
    [_render bindTexture:0 texture:_postprocessTextures[0]];
    [_render drawFSQ];
    
    _adaptationIndex = !_adaptationIndex;
}

- (VBTextureObject*) luminanceTexture { return _adaptationTexture[_adaptationIndex]; }
- (VBTextureObject*) nextLuminanceTexture  { return _adaptationTexture[!_adaptationIndex]; }

- (void) glkView:(GLKView *)view resizeWithSize:(CGSize)size {
    
    float aspect = _glView.drawableWidth/_glView.drawableHeight;
    [[VBCore c] setAspect:aspect];
    [[VBCore c] setViewSize:GLKVector2Make(_glView.drawableWidth, _glView.drawableHeight)];
}

- (void) unloadGL {
    [_screenBuffer unloadFramebuffer];
    [_postprocessBuffer unloadFramebuffer];
    [_reflectionRefractionBuffer unloadFramebuffer];
    [_backfaceBuffer unloadFramebuffer];
    [_frontfaceBuffer unloadFramebuffer];
    [_sceneDepthBuffer unloadFramebuffer];
    [_causticBuffer unloadFramebuffer];
    [_reflectionRefractionCubemapBuffer unloadFramebuffer];
    [_shadowCubemapBuffer unloadFramebuffer];
    [_shadowBuffer unloadFramebuffer];
    
    self.lightSource = nil;
    self.render = nil;
}

- (IBAction) windowWillClose:(id)sender {
    [self unloadGL];
    [_glView pause];
    [[NSApplication sharedApplication] terminate:nil];
}

@end
