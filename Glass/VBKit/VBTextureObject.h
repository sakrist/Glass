//
//  VBTextureObject.h
//  Glass
//
//  Created by Volodymyr Boichentsov on 23/05/2013.
//  Copyright (c) 2013 Volodymyr Boichentsov. All rights reserved.
//

#import <Foundation/Foundation.h>

#ifndef __VBTextureObject_H
#define __VBTextureObject_H

@interface VBTextureObject : NSObject

@property (nonatomic, retain) NSString *name;
@property (nonatomic) GLenum glID;
@property (nonatomic) CGSize size;
@property (nonatomic) int nBPP;
@property (nonatomic) int internalFormat;
@property (nonatomic) int format;
@property (nonatomic) int type;
@property (nonatomic) int target;
@property (nonatomic) GLKVector2 texel;

- (void) setWrap:(GLenum)S :(GLenum)T;
- (void) setWrap:(GLenum)S :(GLenum)T :(GLenum)R;

- (void) generateID;

- (void) setFiltrationMin:(GLenum)min_f mag:(GLenum)mag_f;


+ (instancetype) loadTexture:(NSString*)filepath;

+ (instancetype) createWith:(CGImageRef)imageRef filename:(NSString*)filename;

- (void) unload;

@end

#endif // __VBTextureObject_H