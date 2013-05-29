//
//  VBTextureObject.m
//  Glass
//
//  Created by Volodymyr Boichentsov on 23/05/2013.
//  Copyright (c) 2013 Volodymyr Boichentsov. All rights reserved.
//

#import "VBTextureObject.h"

@implementation VBTextureObject

- (void) generateID {
    glGenTextures(1, &_glID);
}

- (void) setWrap:(GLenum)S :(GLenum)T {
    [self setWrap:S :T :GL_CLAMP_TO_EDGE];
}

- (void) setWrap:(GLenum)S :(GLenum)T :(GLenum)R {
    
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(self.target, _glID);

    glTexParameteri(_target, GL_TEXTURE_WRAP_S, S);
    glTexParameteri(_target, GL_TEXTURE_WRAP_T, T);
    glTexParameteri(_target, GL_TEXTURE_WRAP_R, R);
}

- (void) setFiltrationMin:(GLenum)min_f mag:(GLenum)mag_f {
    
    [[VBResourceManager instance] bindTexture:0 texture:self];
    
    glTexParameteri(_target, GL_TEXTURE_MIN_FILTER, min_f);
    glTexParameteri(_target, GL_TEXTURE_MAG_FILTER, mag_f);
    [[VBResourceManager instance] checkError:@"setFiltrationMin"];
}

+ (id) loadTexture:(NSString*)filepath{

    NSData *imageData = [NSData dataWithContentsOfFile:filepath];
    
#if TARGET_OS_IPHONE
    
    UIImage *image = [[[UIImage alloc] initWithData:imageData] autorelease];
    
    if (image == nil)
        return nil;
    CGImageRef imageRef = image.CGImage;
    
#elif TARGET_OS_MAC
    
    CGImageSourceRef myImageSourceRef = CGImageSourceCreateWithData((__bridge CFDataRef)imageData, NULL);
    CGImageRef imageRef = CGImageSourceCreateImageAtIndex (myImageSourceRef, 0, NULL);
    CFRelease(myImageSourceRef);
    
#endif
    
    return [VBTextureObject createWith:imageRef filename:[filepath lastPathComponent]];

}

+ (VBTextureObject *) createWith:(CGImageRef)imageRef filename:(NSString*)filename {
    
    
    GL_CHECK_ERROR
    
    GLsizei width = (GLsizei)CGImageGetWidth(imageRef);
    GLsizei height = (GLsizei)CGImageGetHeight(imageRef);
    
    CGSize _size;
    _size.width = width;
    _size.height = height;
    
    CGRect rect = {{0, 0}, {width, height}};
    void * imageData = malloc( height * width * 4 );
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    CGContextRef context = CGBitmapContextCreate( imageData, width, height, 8, 4 * width, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    
    
    CGContextTranslateCTM (context, 0, height);
    CGContextScaleCTM (context, 1.0, -1.0);
    
    CGContextSetBlendMode(context, kCGBlendModeCopy);
    CGContextDrawImage(context, rect, imageRef);
    
//    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, imageData);
    
    NSData *data = [NSData dataWithBytes:imageData length:(height * width * 4)];
    
    VBTextureObject *texture = [[VBResourceManager instance] genarateTexture2DWithName:filename
                                                       size:_size
                                             internalFormat:GL_RGBA
                                                     format:GL_RGBA
                                                       type:GL_UNSIGNED_BYTE
                                                       data:data];
    
    CGColorSpaceRelease( colorSpace );
    CGContextRelease(context);
    
    free(imageData);
    
    GL_CHECK_ERROR
    
    return texture;
}


@end
