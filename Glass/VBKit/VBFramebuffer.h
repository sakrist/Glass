//
//  VBFramebuffer.h
//  Glass
//
//  Created by Volodymyr Boichentsov on 22/05/2013.
//  Copyright (c) 2013 Volodymyr Boichentsov. All rights reserved.
//

#import <Foundation/Foundation.h>

@class VBTextureObject;

@interface VBFramebuffer : NSObject {

}

@property (nonatomic, retain) NSMutableArray *renderTargets;
@property (nonatomic, retain) VBTextureObject *depthBuffer;
@property (nonatomic, retain) NSString *name;
@property (nonatomic) GLuint nID;
@property (nonatomic) CGSize size;
@property (nonatomic) GLuint nTargets;

+ (instancetype) framebuffer:(NSString*)name
                        size:(CGSize)size
           texInternalFormat:(int)texInternalFormat
                   texFormat:(int)texFormat
                     texType:(int)texType;

+ (instancetype) framebuffer:(NSString*)name
                        size:(CGSize)size
           texInternalFormat:(int)texInternalFormat
                   texFormat:(int)texFormat
                     texType:(int)texType
         depthInternalFormat:(int)depthInternalFormat
                 depthFormat:(int)depthFormat
                   depthType:(int)depthType;

+ (instancetype) createCubemapFramebuffer:(NSString*)name
                                     size:(int)size
                           internalFormat:(int)texInternalFormat
                                   format:(int)texFormat
                                     type:(int)texType;

- (void) bind;
- (bool) check;

- (bool) addRenderTarget:(VBTextureObject*)rt;
- (bool) setDepthTarget:(VBTextureObject *)rt;

- (void) duplicateLastRenderTarget;

- (void) setCurrentRenderTarget:(VBTextureObject*)texture;
- (void) setCurrentRenderTarget:(VBTextureObject*)texture target:(GLenum) target;
- (void) switchRenderTarget:(int)renderTargetNumber;


- (void) setDrawBuffersCount:(int)c;

- (void) unloadFramebuffer;

@end
