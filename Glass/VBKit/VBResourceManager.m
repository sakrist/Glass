//
//  VBResourceManager.m
//  Glass
//
//  Created by Volodymyr Boichentsov on 23/05/2013.
//  Copyright (c) 2013 Volodymyr Boichentsov. All rights reserved.
//

#import "VBResourceManager.h"

@interface VBResourceManager () {
    char nLastUnit;
    GLuint TEXMAP[32];
}

@end

@implementation VBResourceManager

static VBResourceManager *__instance;

+ (VBResourceManager *)instance  {
	@synchronized(self) {
		if(!__instance) {
			__instance = [[VBResourceManager alloc] init];
            __instance.textures = [NSMutableArray array];
            __instance.support_mipmap_generation = ( glGenerateMipmap != NULL );
            __instance.support_shaders = ( glShaderSource != NULL ) && ( glCreateProgram != NULL );
            __instance.support_vertex_attrib_arrays = (glVertexAttribPointer != NULL);
            __instance.support_vertex_buffers = (glGenBuffers != NULL) && (glBindBuffer != NULL) && (glBufferData != NULL);
            
            [__instance defaultTextures];
            
            NSLog(@" + support_mipmap_generation %d ", __instance.support_mipmap_generation);
            NSLog(@" + support_shaders %d ", __instance.support_shaders);
            NSLog(@" + support_vertex_attrib_arrays %d ", __instance.support_vertex_attrib_arrays);
            NSLog(@" + support_vertex_buffers %d ", __instance.support_vertex_buffers);
		}
	}
	return __instance;
}


- (void) defaultTextures {
    Byte data[4];
    data[0] = 0;    data[1] = 0; data[2]    = 0; data[3] = 255;
    _DEFTEX_black = [self genarateTexture2DWithName:@"DEFTEX BLACK"
                                               size:CGSizeMake(1, 1)
                                     internalFormat:GL_RGBA
                                             format:GL_RGBA
                                               type:GL_UNSIGNED_BYTE data:[NSData dataWithBytes:data length:4]];
    
    data[0] = 255; data[1] = 255; data[2] = 255; data[3] = 255;
    _DEFTEX_white  = [self genarateTexture2DWithName:@"DEFTEX WHITE"
                                                size:CGSizeMake(1, 1)
                                      internalFormat:GL_RGBA
                                              format:GL_RGBA
                                                type:GL_UNSIGNED_BYTE data:[NSData dataWithBytes:data length:4]];
    data[0] = 128; data[1] = 128; data[2] = 255; data[3] = 255;
    _DEFTEX_normal = [self genarateTexture2DWithName:@"DEFTEX NORMAL"
                                                size:CGSizeMake(1, 1)
                                      internalFormat:GL_RGBA
                                              format:GL_RGBA
                                                type:GL_UNSIGNED_BYTE data:[NSData dataWithBytes:data length:4]];
    
    Byte cell[16] = {0};
    cell[ 0] = 255; cell[ 1] =   0; cell[ 2] = 0; cell[ 3] = 255;
    cell[ 4] =   0; cell[ 5] = 255; cell[ 6] = 0; cell[ 7] = 255;
    cell[ 8] =   0; cell[ 9] = 255; cell[10] = 0; cell[11] = 255;
    cell[12] = 255; cell[13] =   0; cell[14] = 0; cell[15] = 255;
    _DEFTEX_cell = [self genarateTexture2DWithName:@"DEFTEX CELL"
                                             size:CGSizeMake(2, 2)
                                   internalFormat:GL_RGBA
                                           format:GL_RGBA
                                             type:GL_UNSIGNED_BYTE data:[NSData dataWithBytes:cell length:4]];

//
//    _DEFTEX_noise       = manager()->genNoiseTexture2D("DEFTEX NOISE",        256, 256, false);
//    _DEFTEX_normalnoise = manager()->genNoiseTexture2D("DEFTEX NORMAL NOISE",   4,   4, true);
}


- (id) genarateTexture2DWithName:(NSString *)name       size:(CGSize)size
                  internalFormat:(int)nInternalFormat
                          format:(int)nFormat
                            type:(int)nType             data:(NSData*)data {

    VBTextureObject *texture = [[VBTextureObject alloc] init];
    texture.name    = [name copy];
    texture.format  = nFormat;
    texture.internalFormat = nInternalFormat;
    texture.size    = size;
    texture.type    = nType;

//#warning "not implementad yet"
//    render()->buildTexture(tex, GL_TEXTURE_2D, data);
    [self buildTexture:texture target:GL_TEXTURE_2D data:data mipmap:true];
    
    
    [self.textures addObject:texture];
    
    return texture;
}

- (id) genarateCubeTextureWithName:(NSString *)name   size:(CGSize)size
                  internalFormat:(int)nInternalFormat
                          format:(int)nFormat
                            type:(int)nType  datas:(NSMutableArray *)datas {
    
    if ([datas count] != 6) {
//        [NSException raise:@"Wrong data for cube texture." format:nil];
    }
    
    // data should be has 6 objects
    
    VBTextureObject *texture = [[VBTextureObject alloc] init];
    texture.name    = [name copy];
    texture.format  = nFormat;
    texture.internalFormat = nInternalFormat;
    texture.size    = size;
    texture.type    = nType;
    

    [self buildCubeTexture:texture data:datas mipmap:true];
    
    [self.textures addObject:texture];
    
    return texture;
}





- (void) bindTexture:(GLenum)unit texture:(VBTextureObject*)texture {
    [self bindTexture:unit texture:texture target:GL_TEXTURE_2D];
}

- (void) bindTexture:(GLenum)unit texture:(VBTextureObject*)texture target:(int)target {
    
    if (unit != nLastUnit) {
        nLastUnit = unit;
        glActiveTexture(GL_TEXTURE0 + nLastUnit);
    }
    
    if (texture)
    {
        if (TEXMAP[unit] != texture.glID)
        {
            TEXMAP[unit] = texture.glID;
            glBindTexture(texture.target, texture.glID);
            [self checkError:texture.name];
        }
    }
    else {
        TEXMAP[unit] = 0;
        glBindTexture(target, 0);
    }
}

- (void) buildCubeTexture:(VBTextureObject*)texture data:(NSMutableArray*)datas mipmap:(bool)bBuildMIPMAPs {
    
    [self checkError:@"buildCubeTexture"];
    
    texture.target = GL_TEXTURE_CUBE_MAP;
    [texture generateID];
    
    GL_CHECK_ERROR
    
    [self bindTexture:0 texture:texture target:GL_TEXTURE_CUBE_MAP];
//    checkErrorF("bindTexture<CUBE>", texture->name);
    
    glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
//    checkErrorF("glTexParameteri<CUBE, MIN>", texture->name);
    glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
//    checkErrorF("glTexParameteri<CUBE, MAG>", texture->name);
    glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
//    checkErrorF("glTexParameteri<CUBE, WRAP_S>", texture->name);
    glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
//    checkErrorF("glTexParameteri<CUBE, WRAP_T>", texture->name);
    glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_WRAP_R, GL_CLAMP_TO_EDGE);
//    checkErrorF("glTexParameteri<CUBE, WRAP_R>", texture->name);
    
    for (int face = 0; face < 6; face++)
    {
        NSData *data = nil;
        if ([datas count] < face+1) {
            data = [datas objectAtIndex:face];
        }
        
        
        glTexImage2D(GL_TEXTURE_CUBE_MAP_POSITIVE_X + face,
                     0,
                     texture.internalFormat,
                     texture.size.width,
                     texture.size.height,
                     0,
                     texture.format,
                     texture.type,
                     ((data == nil) ? 0 : [data bytes]));
        
//        checkErrorF("glTexImage2D<CUBE, " + intToStr(face) + ">", texture->name);
    }
    
    GL_CHECK_ERROR
}

- (void) buildTexture:(VBTextureObject *) texture  target:(int)target  data:(NSData*) data  mipmap:(bool) bBuildMIPMAPs {
    
    NSString *info = [NSString stringWithFormat:@"VBResourceManager::BuildTexture2D( %@ );", texture.name];
    [self checkError:info];
    
    texture.target = target;
    texture.texel = GLKVector2Make(1.0f/texture.size.width, 1.0f/texture.size.height);
    
    [texture generateID];
    
    info = [NSString stringWithFormat:@"glGenTextures( %@ );", texture.name];
    [self checkError:info];
    
    [self bindTexture:0 texture:texture];
    
    if (data && _support_mipmap_generation)
    {
        glTexParameteri(texture.target, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
//        info = "glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR) for "; info += texture->name;
    }
    else
    {
        glTexParameteri(texture.target, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
//        info = "glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR) for "; info += texture->name;
    }
//    checkError(info);
    
    glTexParameteri(texture.target, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
//    info = "glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR) for "; info += texture->name;
//    checkError(info);
    
    glTexParameteri(texture.target, GL_TEXTURE_WRAP_S, GL_REPEAT);
//    info = "glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT) for "; info += texture->name;
//    checkError(info);
    
    glTexParameteri(texture.target, GL_TEXTURE_WRAP_T, GL_REPEAT);
//    info = "glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT) for "; info += texture->name;
//    checkError(info);
    

    glTexImage2D(texture.target, 0,
               texture.internalFormat,
               texture.size.width,
               texture.size.height,
                 0,
               texture.format,
               texture.type, [data bytes]);
    
    [self checkError:@"texture generation"];
    
    
    if (data && _support_mipmap_generation)
    {
        glGenerateMipmap(target);
        [self checkError:@"glGenerateMipmap"];
//        checkErrorF("glGenerateMipmap", glTexTargetToString(target));
    }
    
}


- (void) checkError:(NSString*)info {
    GLenum error = glGetError();
    if (error == GL_NO_ERROR) return;
    
    NSLog(@"%@ 0x%04x", info, error);
}

@end
