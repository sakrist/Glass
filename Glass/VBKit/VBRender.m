//
//  VBRender.m
//  Glass
//
//  Created by Volodymyr Boichentsov on 27/05/2013.
//  Copyright (c) 2013 Volodymyr Boichentsov. All rights reserved.
//

#import "VBRender.h"

#import "VBCamera.h"

#import "VBProgramObject.h"

#define DEG_30				0.52359877559829887307710723054658f
#define DEG_15				0.26179938779914943653855361527329f


@interface VBRender () {
    GLKVector2 _nLastVPSize;
    int nLastFBO, nLastB0, nLastB1;
    int nLastVPx, nLastVPy;
    
    bool _blendEnabled;
    
    GLenum _cullState;
    
    GLint  _pcs_u;
    
    VBBuffer* FSQuad;
}

@end

@implementation VBRender

- (id)init {
    self = [super init];
    if (self) {
        self.camera = [[VBCamera alloc] init];
        float aspect = [VBCore c].aspect;
        [self.camera perspectiveWithFov:DEG_30 aspect:aspect near:1.0f far:100.0f];
        [self.camera lookAtFrom:GLKVector3Make(0, 0, cos(DEG_15)/ sin(DEG_15)) to:GLKVector3Make(0, 0, 0) up:GLKVector3Make(0, 1, 0)];
        
        nLastFBO = 0;
        
        nLastVPx = nLastVPy = 0;
        nLastB0  = nLastB1  = 0;
        
        _cullState = GL_NONE;
        _blendEnabled = false;
        
        glEnable(GL_DEPTH_TEST);        
        
        GLKVector2 vert[4]  = {-1.0,  1.0, -1.0, -1.0,  1.0,  1.0,  1.0, -1.0};
        int indx[4] = {0, 1, 2, 3};
        
        NSData *vertices = [NSData dataWithBytes:&vert length:sizeof(GLKVector2)*4];
        NSData *indices = [NSData dataWithBytes:&indx length:16];
        
        FSQuad = [VBBuffer createVertexBuffer:@"Fullscreen quad" type:VBBufferAttrTypeV2
                                     vertices:vertices indices:indices
                                   indicesNum:4 drawMode:GL_TRIANGLE_STRIP];
        
        _prog_copy = [VBProgramObject loadProgram:@"fullscreen.program"];
        _prog_copy_scale = [VBProgramObject loadProgram:@"fullscreen_scaled.program"];
        VBUniform uniform = [_prog_copy_scale uniformWithName:@"vScale"];
        _pcs_u = uniform.location;

        
    }
    return self;
}



- (void) drawFSQ {
    [FSQuad renderAll];
}

- (void) drawFSQWithTexture:(VBTextureObject *)texture {
    
    [[VBResourceManager instance] bindTexture:0 texture:texture];
    [_prog_copy bind];
    [FSQuad renderAll];
}

- (void) drawFSQWithTextureScaled:(VBTextureObject*) texture scale:(GLKVector4)scale {
    
    [[VBResourceManager instance] bindTexture:0 texture:texture];
    [_prog_copy_scale bind];

    glUniform4fv(_pcs_u, 1, (GLfloat*)&(scale.v));
    
    [FSQuad renderAll];
}


- (void) bindFramebuffer:(VBFramebuffer *) FBO {
    if (!FBO)
    {
        if (nLastFBO == 0) return;
        
        nLastFBO = 0;
        [self viewPortSize:[VBCore c].viewSize];
        glBindFramebuffer(GL_FRAMEBUFFER, 0);
        GL_CHECK_ERROR
    } else {
        if ( FBO.nID == nLastFBO ) return;
        
        nLastFBO = FBO.nID;
        [self viewPortSize:GLKVector2Make(FBO.size.width, FBO.size.height)];
        glBindFramebuffer(GL_FRAMEBUFFER, FBO.nID);
        
        GL_CHECK_ERROR
    }
}





- (void) viewPortSize:(GLKVector2)size {
    _nLastVPSize = size;
    glViewport(0, 0, size.x, size.y);
}

- (void) cullFace:(GLenum) C {
    if (_cullState == C)
        return;
    
    _cullState = C;
    
    if (C == GL_NONE) {
        glDisable(GL_CULL_FACE);
    } else {
        glCullFace(C);
        glEnable(GL_CULL_FACE);
    }
}

- (void) blend:(bool) B {
    if ((_blendEnabled = B)) {
        glEnable(GL_BLEND);
    } else {
        glDisable(GL_BLEND);
    }
}

- (void) blendFunction:(GLenum)B0 second:(GLenum)B1 {
    if ( (B0 != nLastB0) || (B1 != nLastB1) ) {
        nLastB0 = B0;
        nLastB1 = B1;
        glBlendFunc(B0, B1);
    }
}

- (void) bindTexture:(GLenum)unit texture:(VBTextureObject*)texture {
    [[VBResourceManager instance] bindTexture:unit texture:texture target:GL_TEXTURE_2D];
}

- (void) bindTexture:(GLenum)unit texture:(VBTextureObject*)texture target:(int)target {
    [[VBResourceManager instance] bindTexture:unit texture:texture target:GL_TEXTURE_2D];
}

@end
