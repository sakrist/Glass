//
//  VBKit.h
//  Glass
//
//  Created by Volodymyr Boichentsov on 23/05/2013.
//  Copyright (c) 2013 Volodymyr Boichentsov. All rights reserved.
//

#import <Foundation/Foundation.h>


static __inline__ void __checkEnumError(GLenum Error) {
    switch ( Error )
    {
        case GL_INVALID_ENUM:      NSLog( @" - GL_INVALID_ENUM %s:%u",__FILE__, __LINE__      );  break;
        case GL_INVALID_VALUE:     NSLog( @" - GL_INVALID_VALUE %s:%u",__FILE__, __LINE__     );  break;
        case GL_INVALID_OPERATION: NSLog( @" - GL_INVALID_OPERATION %s:%u",__FILE__, __LINE__ );  break;
        case GL_OUT_OF_MEMORY:     NSLog( @" - GL_OUT_OF_MEMORY %s:%u",__FILE__, __LINE__     );  break;
        case 0x0506:  NSLog( @" - 0x0506 %s:%u",__FILE__, __LINE__     ); assert( 0 );  break;
        default:                   NSLog( @"%s:%u: 0x%04x\n", __FILE__, __LINE__, Error);     break;
    }
}

static __inline__ BOOL __hasError() {
    GLenum err = glGetError();
    if (err != GL_NO_ERROR) {
        __checkEnumError(err);
        return YES;
    }
    return NO;
}

#define GL_CHECK_ERROR { for ( GLenum Error = glGetError( ); ( GL_NO_ERROR != Error ); Error = glGetError( ) )\
{ __checkEnumError(Error); NSLog(@"GL_CHECK_ERROR %@", [NSThread callStackSymbols]);  } }


#define DEFAULT_VERTEXSHADER @"void main(){gl_Position = vec4(0.0, 0.0, 0.0, 1.0);}"
#define DEFAULT_FRAGMENTSHADER @"#version 150\nprecision highp float;\n out vec4 FragColor; void main(){FragColor = vec4(1.0, 0.0, 0.0, 1.0);}"

// RENDER ATTRIBUTES
#define RENDER_ATTRIB_POSITION  0
#define RENDER_ATTRIB_NORMAL    1
#define RENDER_ATTRIB_TEXCOORD0 2
#define RENDER_ATTRIB_TANGENT   3

// UNIFORM TYPES
#define UNIFORM_FLOAT   0
#define UNIFORM_VEC2    1
#define UNIFORM_VEC3    2
#define UNIFORM_VEC4    3
#define UNIFORM_MAT3    4
#define UNIFORM_MAT4    5
#define UNIFORM_SAMPLER 6

#define M2_PI M_PI*2


#import "VBCore.h"
#import "VBLight.h"
#import "VBCamera.h"
#import "VBRender.h"
#import "VBBuffer.h"
#import "VBFramebuffer.h"
#import "VBResourceManager.h"
#import "VBTextureObject.h"
#import "VBProgramObject.h"


