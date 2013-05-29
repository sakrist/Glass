//
//  VBRender.h
//  Glass
//
//  Created by Volodymyr Boichentsov on 27/05/2013.
//  Copyright (c) 2013 Volodymyr Boichentsov. All rights reserved.
//

#import <Foundation/Foundation.h>

@class VBProgramObject;
@class VBTextureObject;
@class VBFramebuffer;

@interface VBRender : NSObject

@property (nonatomic ,retain) VBCamera *camera;

@property (nonatomic ,retain) VBProgramObject* prog_copy;
@property (nonatomic ,retain) VBProgramObject* prog_copy_scale;

- (void) viewPortSize:(GLKVector2)size;
- (void) cullFace:(GLenum)C;
- (void) blend:(bool) B;
- (void) blendFunction:(GLenum)B0 second:(GLenum)B1;

- (void) drawFSQ;
- (void) drawFSQWithTexture:(VBTextureObject *)texture;
- (void) drawFSQWithTextureScaled:(VBTextureObject*) texture scale:(GLKVector4)scale;

- (void) bindFramebuffer:(VBFramebuffer *)FBO;


@end
