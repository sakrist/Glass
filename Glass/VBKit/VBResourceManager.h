//
//  VBResourceManager.h
//  Glass
//
//  Created by Volodymyr Boichentsov on 23/05/2013.
//  Copyright (c) 2013 Volodymyr Boichentsov. All rights reserved.
//

#import <Foundation/Foundation.h>

@class VBTextureObject;


@interface VBResourceManager : NSObject

@property (nonatomic, retain) NSMutableArray *textures;

@property (nonatomic, retain) VBTextureObject * DEFTEX_white;
@property (nonatomic, retain) VBTextureObject * DEFTEX_black;
@property (nonatomic, retain) VBTextureObject * DEFTEX_normal;
@property (nonatomic, retain) VBTextureObject * DEFTEX_cell;
@property (nonatomic, retain) VBTextureObject * DEFTEX_noise;
@property (nonatomic, retain) VBTextureObject * DEFTEX_normalnoise;

@property (nonatomic) bool support_mipmap_generation;
@property (nonatomic) bool support_shaders;
@property (nonatomic) bool support_vertex_attrib_arrays;
@property (nonatomic) bool support_vertex_buffers;

+ (VBResourceManager *)instance;

- (id) genarateTexture2DWithName:(NSString *)name
                            size:(CGSize)size
                  internalFormat:(int)nInternalFormat
                          format:(int)nFormat
                            type:(int)nType
                            data:(NSData*)data;


- (id) genarateCubeTextureWithName:(NSString *)name
                              size:(CGSize)size
                    internalFormat:(int)nInternalFormat
                            format:(int)nFormat
                              type:(int)nType
                             datas:(NSMutableArray *)data;

- (void) bindTexture:(GLenum)unit texture:(VBTextureObject*)texture;
- (void) bindTexture:(GLenum)unit texture:(VBTextureObject*)texture target:(int)target;

- (void) unloadTexture:(VBTextureObject*)texture;

@end
