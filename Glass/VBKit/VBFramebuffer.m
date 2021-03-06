//
//  VBFramebuffer.m
//  Glass
//
//  Created by Volodymyr Boichentsov on 22/05/2013.
//  Copyright (c) 2013 Volodymyr Boichentsov. All rights reserved.
//

#import <OpenGL/OpenGL.h>

#import "VBFramebuffer.h"
#import "VBTextureObject.h"
#import "VBResourceManager.h"

static const GLenum RENDERBUFFERS_ENUM[16] =
{ GL_COLOR_ATTACHMENT0,
    GL_COLOR_ATTACHMENT1,
    GL_COLOR_ATTACHMENT2,
    GL_COLOR_ATTACHMENT3,
    GL_COLOR_ATTACHMENT4,
    GL_COLOR_ATTACHMENT5,
    GL_COLOR_ATTACHMENT6,
    GL_COLOR_ATTACHMENT7,
    GL_COLOR_ATTACHMENT8,
    GL_COLOR_ATTACHMENT9,
    GL_COLOR_ATTACHMENT10,
    GL_COLOR_ATTACHMENT11,
    GL_COLOR_ATTACHMENT12,
    GL_COLOR_ATTACHMENT13,
    GL_COLOR_ATTACHMENT14,
    GL_COLOR_ATTACHMENT15 };

@implementation VBFramebuffer

- (NSString*) framebufferStatusToString:(int)status {
    switch (status)
    {
        case GL_FRAMEBUFFER_COMPLETE                      : return @" - GL_FRAMEBUFFER_COMPLETE";
        case GL_FRAMEBUFFER_INCOMPLETE_ATTACHMENT         : return @" - GL_FRAMEBUFFER_INCOMPLETE_ATTACHMENT";
        case GL_FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT : return @" - GL_FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT";
        case GL_FRAMEBUFFER_INCOMPLETE_DRAW_BUFFER        : return @" - GL_FRAMEBUFFER_INCOMPLETE_DRAW_BUFFER";
        case GL_FRAMEBUFFER_INCOMPLETE_READ_BUFFER        : return @" - GL_FRAMEBUFFER_INCOMPLETE_READ_BUFFER";
        //  case GL_FRAMEBUFFER_INCOMPLETE_DIMENSIONS         : return @"GL_FRAMEBUFFER_INCOMPLETE_DIMENSIONS";
        //  case GL_FRAMEBUFFER_INCOMPLETE_UNSUPPORTED        : return @"GL_FRAMEBUFFER_INCOMPLETE_UNSUPPORTED";
    }
    return [NSString stringWithFormat:@" - Unknown FBO status %d", status];
}

- (id) init {
    if (self = [super init]) {
        self.nTargets = 0;
        self.nID = 0;
        self.renderTargets = [NSMutableArray array];
        return self;
    }
    return nil;
}

- (void) generate {
    glGenFramebuffers(1, &_nID);
}

- (void) bind {
    glViewport(0, 0, self.size.width, self.size.height);
    glBindFramebuffer(GL_FRAMEBUFFER, _nID);
}


+ (instancetype) createCubemapFramebuffer:(NSString*)name
                                       size:(int)size
                             internalFormat:(int)texInternalFormat
                                     format:(int)texFormat
                                       type:(int)texType {
    
    return [[self class] createCubemapFramebuffer:name
                                              size:size
                                    internalFormat:texInternalFormat
                                     format:texFormat
                                              type:texType
                               depthInternalFormat:GL_DEPTH_COMPONENT24
                                       depthFormat:GL_DEPTH_COMPONENT
                                         depthType:GL_UNSIGNED_BYTE];
}


+ (instancetype) createCubemapFramebuffer:(NSString*)name
                                       size:(int)size
                             internalFormat:(int)texInternalFormat
                                     format:(int)texFormat
                                       type:(int)texType
                        depthInternalFormat:(int)depthInternalFormat
                                depthFormat:(int)depthFormat
                                  depthType:(int)depthType {
    
    VBFramebuffer* F = [[[self class] alloc] init];

    F.size = CGSizeMake(size, size);
    F.name = [name copy];
    [F generate];
    [F bind];
    
    if (texInternalFormat != 0) {
        
        NSString *texname = [NSString stringWithFormat:@"FBO %@ color0", F.name];
        
        VBTextureObject *color = [[VBResourceManager instance] genarateCubeTextureWithName:texname
                                                                                      size:F.size
                                                                            internalFormat:texInternalFormat
                                                                                    format:texFormat
                                                                                      type:texType
                                                                                      datas:nil];
        
        if (![F addRenderTarget:color]) {
            NSLog(@" - CubeTexture %@ was not added to %@", texname, F.name);
        }
    } else {
        glReadBuffer(GL_NONE);
        glDrawBuffer(GL_NONE);
    }
    
    if (depthInternalFormat != 0)
    {
        
        NSString *texname = [NSString stringWithFormat:@"FBO %@ depth", F.name];
        
        VBTextureObject *depth = [[VBResourceManager instance] genarateCubeTextureWithName:texname
                                                                                      size:F.size
                                                                            internalFormat:depthInternalFormat
                                                                                    format:depthFormat
                                                                                      type:depthType
                                                                                      datas:nil];
        [F setDepthTarget:depth];
    } else {
        NSLog(@" * without depth");
    }
    
    
    [F check];
    
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
    
    return F;
}





+ (instancetype) framebuffer:(NSString*)name
              size:(CGSize)size
 texInternalFormat:(int)texInternalFormat
         texFormat:(int)texFormat
           texType:(int)texType {
    return [self framebuffer:name
                                 size:size
                    texInternalFormat:texInternalFormat
                            texFormat:texFormat
                              texType:texType
                  depthInternalFormat:GL_DEPTH_COMPONENT
                          depthFormat:GL_DEPTH_COMPONENT
                            depthType:GL_UNSIGNED_BYTE];
}


+ (instancetype) framebuffer:(NSString*)name
              size:(CGSize)size
 texInternalFormat:(int)texInternalFormat
         texFormat:(int)texFormat
           texType:(int)texType
depthInternalFormat:(int)depthInternalFormat
       depthFormat:(int)depthFormat
         depthType:(int)depthType {

    VBFramebuffer *F = [[[self class] alloc] init];

    F.size  = size;
    F.name  = name;
    [F generate];
    [F bind];

    if (texInternalFormat != 0) {
        
        NSString *texName = [NSString stringWithFormat:@"FBO %@ color 0", F.name];
        
        VBTextureObject *C = [[VBResourceManager instance] genarateTexture2DWithName:texName
                                                                                size:F.size
                                                                      internalFormat:texInternalFormat
                                                                              format:texFormat
                                                                                type:texType
                                                                                data:NULL];

        [C setWrap:GL_CLAMP_TO_EDGE :GL_CLAMP_TO_EDGE];
        
        if (![F addRenderTarget:C]) {
            NSLog(@" - Texture %@ was not added to %@", texName, F.name);
        }


    } else {
        glReadBuffer(GL_NONE);
        glDrawBuffer(GL_NONE);
        NSLog(@" * without color %@", F.name);
    }    
    
    if (depthInternalFormat != 0) {
        
        NSString *texName = [NSString stringWithFormat:@"FBO %@ depth", F.name];
        
        VBTextureObject *D = [[VBResourceManager instance] genarateTexture2DWithName:texName
                                                                                size:F.size
                                                                      internalFormat:depthInternalFormat
                                                                              format:depthFormat
                                                                                type:depthType
                                                                                data:NULL];
        [D setWrap:GL_CLAMP_TO_EDGE :GL_CLAMP_TO_EDGE];
        if (![F setDepthTarget:D]) {
            NSLog(@" - DEPTH WRONG");
        }
    } else {
        NSLog(@" * without depth %@", F.name);
    }
    
    [F check];
    
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
    
    return F;
}

- (bool) addRenderTarget:(VBTextureObject*)rt {
    
    if ( (!rt) || (rt.size.width != self.size.width) || (rt.size.height != self.size.height)) {
        return false;
    }
    
    [self bind];
    
    glFramebufferTexture(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0 + _nTargets, rt.glID, 0);
    [_renderTargets addObject:rt];
    _nTargets = (GLuint)[_renderTargets count];
    
    return [self check];
}


- (void) duplicateLastRenderTarget {

    VBTextureObject *last = [_renderTargets lastObject];
    
    NSString *namec = [NSString stringWithFormat:@"%ld rendertarget", [_renderTargets count]+1];
    
    VBTextureObject *texture = [[VBResourceManager instance] genarateTexture2DWithName:namec
                                                                            size:last.size
                                                                  internalFormat:last.internalFormat
                                                                          format:last.format
                                                                            type:last.type
                                                                            data:NULL];
    
    [texture setWrap:GL_CLAMP_TO_EDGE :GL_CLAMP_TO_EDGE];
    
    if (![self addRenderTarget:texture]) {
        NSLog(@" - Same Texture %@ was not added to %@", namec, self.name);
    }
}



- (bool) setDepthTarget:(VBTextureObject *)texture {
    
    
    if ( !texture || !CGSizeEqualToSize(texture.size, self.size)) {
        return false;
    }
    
    [self bind];
    glFramebufferTexture(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, texture.glID, 0);
    self.depthBuffer = texture;

    return [self check];
}



- (void) setCurrentRenderTarget:(VBTextureObject*) texture {
    [self bind];
    glViewport(0, 0, texture.size.width, texture.size.height);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, texture.target, texture.glID, 0);
    [self check];
}

- (void) setCurrentRenderTarget:(VBTextureObject *)texture target:(GLenum) target {
    [self bind];
    glViewport(0, 0, texture.size.width, texture.size.height);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, target, texture.glID, 0);
    [self check];
}

- (void) switchRenderTarget:(int)renderTargetNumber {
    if (renderTargetNumber < _nTargets) {
        [self setCurrentRenderTarget:[_renderTargets objectAtIndex:renderTargetNumber]];
    }
}


- (void) setDrawBuffersCount:(int) c {
    [self bind];
    glDrawBuffers(c, RENDERBUFFERS_ENUM);
    [self check];
}


- (bool) check {
    [self bind];
    
    int status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    
    if (status != GL_FRAMEBUFFER_COMPLETE) {
        NSString *info = [self framebufferStatusToString:status];
        NSLog(@"%@ for %@", info, _name);
    }
    
    return (status == GL_FRAMEBUFFER_COMPLETE);
}


- (void) unloadFramebuffer {
    
    [[VBResourceManager instance] unloadTexture:self.depthBuffer];
    self.depthBuffer = nil;

    for (VBTextureObject *t in self.renderTargets) {
        [[VBResourceManager instance] unloadTexture:t];
    }
    [self.renderTargets removeAllObjects];
    self.renderTargets = nil;
    
    glDeleteFramebuffers(1, &_nID);
}


@end
