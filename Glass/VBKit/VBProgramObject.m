//
//  VBProgramObject.m
//  Glass
//
//  Created by Volodymyr Boichentsov on 27/05/2013.
//  Copyright (c) 2013 Volodymyr Boichentsov. All rights reserved.
//

#import "VBProgramObject.h"



@interface VBProgramObject () {
    NSMutableString *_defines;
    NSString *_prog_folder;
    
@private
    int _mvm_loc;
    int _mvp_loc;
    int _cam_loc;
    int _l0_loc;
    int _lp_loc;
    
    GLint __programObject;
    GLint __vertexShader;
    GLint __geometryShader;
    GLint __fragmentShader;
    
    int ID;
}

@end

@implementation VBProgramObject

- (id) init {
    self = [super init];
    if (self) {
        __programObject = 0;
        __vertexShader = 0;
        __geometryShader = 0;
        __fragmentShader = 0;
        
        _mvp_loc = -1;
        _cam_loc = -1;
        _l0_loc = -1;
        _lp_loc = -1;
        _mvm_loc = -1;
        
        self.uniforms = [NSMutableDictionary dictionary];
        return self;
    }
    
    return nil;
}

+ (instancetype) loadProgram:(NSString*)filename {
    return [[self class] loadProgram:filename param:@""];
}

+ (instancetype) loadProgram:(NSString*)filename param:(NSString*)param {
    VBProgramObject *program = [[[self class] alloc] init];
    
    bool t = [program load:filename param:param];
    
    if (t) {
        NSLog(@" * loaded %@ , uniforms count %ld ", filename, (unsigned long)[program.uniforms count]);
    } else {
        NSLog(@" * not found %@ ", filename);
        return nil;
    }
    
    return program;
}

/// PROGRAM OBJECT
- (bool) load:(NSString*)filename param:(NSString*)param {

    self.name = filename;
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:filename]) {
        filename = [[NSBundle mainBundle] pathForResource:filename ofType:nil];
        if (![[NSFileManager defaultManager] fileExistsAtPath:filename])
            return false;
    }
    
    
    _defines = [NSMutableString stringWithString:param];
    
    NSString* vertex_source;
    NSString* geometry_source;
    NSString* fragment_source;
    
    
    NSString *fileContent = [NSString stringWithContentsOfFile:filename encoding:NSUTF8StringEncoding error:nil];
    
    
    NSArray *lines = [fileContent componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    
    for (NSString *line in lines) {
        
        NSArray *elements = [line componentsSeparatedByString:@":"];
        
        NSString *idr = [[elements objectAtIndex:0] lowercaseString];
        
        idr = [idr stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        
        if ([idr isEqualToString:@"vs"]) {
            vertex_source = [[elements objectAtIndex:1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        }
        if ([idr isEqualToString:@"gs"]) {
            geometry_source = [[elements objectAtIndex:1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        }
        if ([idr isEqualToString:@"fs"]) {
            fragment_source = [[elements objectAtIndex:1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        }
        if ([idr isEqualToString:@"defines"]) {
            [_defines appendString:@", "];
            [_defines appendString:[[elements objectAtIndex:1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]];
        }    
    }
    
    if (vertex_source != nil) {
        vertex_source = [vertex_source stringByReplacingOccurrencesOfString:@"\\" withString:@"/"];
    }
    if (fragment_source != nil) {
        fragment_source = [fragment_source stringByReplacingOccurrencesOfString:@"\\" withString:@"/"];
    }
    
    NSString *vertex_shader;
    NSString *geom_shader = @"none";
    NSString *frag_shader;
    
    _prog_folder = [filename stringByDeletingLastPathComponent];
    

    NSString *fName = [_prog_folder stringByAppendingPathComponent:vertex_source];
    if (![[NSFileManager defaultManager] fileExistsAtPath:fName]) {
        fName = [[NSBundle mainBundle] pathForResource:vertex_source ofType:nil];
    }
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:fName]) {
        
        vertex_shader = [NSString stringWithContentsOfFile:fName encoding:NSUTF8StringEncoding error:nil];
        vertex_shader = [self parse:vertex_shader];
        
    } else {
        vertex_shader = DEFAULT_VERTEXSHADER;
    }

    
    if (![geometry_source isEqualToString:@"none"] && geometry_source != nil) {
        
        NSString *fName = [_prog_folder stringByAppendingPathComponent:geometry_source];
        if (![[NSFileManager defaultManager] fileExistsAtPath:fName]) {
            fName = [[NSBundle mainBundle] pathForResource:geometry_source ofType:nil];
        }
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:fName]) {
            geom_shader = [NSString stringWithContentsOfFile:fName encoding:NSUTF8StringEncoding error:nil];
            geom_shader = [self parse:geom_shader];
        }
    }
    
    
    fName = [_prog_folder stringByAppendingPathComponent:fragment_source];
    if (![[NSFileManager defaultManager] fileExistsAtPath:fName]) {
        fName = [[NSBundle mainBundle] pathForResource:fragment_source ofType:nil];
    }
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:fName]) {
        frag_shader = [NSString stringWithContentsOfFile:fName encoding:NSUTF8StringEncoding error:nil];
        frag_shader = [self parse:frag_shader];
    } else {
        frag_shader = DEFAULT_FRAGMENTSHADER;
    }
    
    
    [self buildProgram:vertex_shader geom:geom_shader frag:frag_shader];
    
    return true;
}


- (void) buildProgram:(NSString*)vertex_source geom:(NSString*)geom_source frag:(NSString*)frag_source {
    
    
    if (!glIsProgram(__programObject))
    {
        __programObject = glCreateProgram();
        GL_CHECK_ERROR
    }
    
    if (!glIsShader(__vertexShader))
    {
        __vertexShader  = glCreateShader(GL_VERTEX_SHADER);
        GL_CHECK_ERROR
    }
    
    int nLen = (int)[vertex_source length];
    
    const GLchar * src = (GLchar *)[vertex_source UTF8String];
    glShaderSource(__vertexShader, 1, &src, &nLen);
    GL_CHECK_ERROR
    glCompileShader(__vertexShader);
    GL_CHECK_ERROR
    
    int cStatus = 0;
    GLsizei nLogLen = 0;
    glGetShaderiv(__vertexShader, GL_COMPILE_STATUS, &cStatus);
    GL_CHECK_ERROR
    glGetShaderiv(__vertexShader, GL_INFO_LOG_LENGTH, &nLogLen);
    if (nLogLen > 1)
    {
        GLchar *infoLog = (GLchar *)malloc(nLogLen + 1);
        memset(infoLog, 0, nLogLen + 1);
        glGetShaderInfoLog(__vertexShader, nLogLen, &nLogLen, infoLog);
        if (cStatus != GL_TRUE) {
            NSLog(@"%@ VertexShader %@", self.name,[NSString stringWithUTF8String:infoLog]);
        }
        
        free(infoLog);
    }
    
    if (cStatus)
    {
        glAttachShader(__programObject, __vertexShader);
        GL_CHECK_ERROR
        
        glBindAttribLocation(__programObject, RENDER_ATTRIB_POSITION,  "Vertex");
        GL_CHECK_ERROR
        
        glBindAttribLocation(__programObject, RENDER_ATTRIB_NORMAL,    "Normal");
        GL_CHECK_ERROR
        glBindAttribLocation(__programObject, RENDER_ATTRIB_TEXCOORD0, "TexCoord0");
        
        GL_CHECK_ERROR
        glBindAttribLocation(__programObject, RENDER_ATTRIB_TANGENT,   "Tangent");
        GL_CHECK_ERROR
    }
    
    ///////////////////////////////////////////////// GEOMETRY
    if (![geom_source isEqualToString:@"none"])
    {
        if (!glIsShader(__geometryShader))
        {
            __geometryShader = glCreateShader(GL_GEOMETRY_SHADER);
            GL_CHECK_ERROR
            nLen = (int)[geom_source length];
            src = [geom_source UTF8String];
            glShaderSource(__geometryShader, 1, &src, &nLen);
            
            GL_CHECK_ERROR
            
            cStatus = 0;
            nLogLen = 0;
            glCompileShader(__geometryShader);
            GL_CHECK_ERROR
            
            glGetShaderiv(__geometryShader, GL_COMPILE_STATUS, &cStatus);
            GL_CHECK_ERROR
            
            glGetShaderiv(__geometryShader, GL_INFO_LOG_LENGTH, &nLogLen);
            if (nLogLen > 1)
            {
                GLchar* infoLog = malloc(nLogLen + 1);
                memset(infoLog, 0, nLogLen + 1);
                glGetShaderInfoLog(__geometryShader, nLogLen, &nLogLen, infoLog);
                
                if (cStatus != GL_TRUE) {
                    NSLog(@" - %@ GeometryShader %@", self.name, [NSString stringWithUTF8String:infoLog]);
                }
                
                free(infoLog);
            }
            if (cStatus)
            {
                glAttachShader(__programObject, __geometryShader);
                GL_CHECK_ERROR
            }
        }
    }
    
    ///////////////////////////////////////////////// FRAGMENT
    if (!glIsShader(__fragmentShader))
    {
        __fragmentShader = glCreateShader(GL_FRAGMENT_SHADER);
        GL_CHECK_ERROR
    }
    
    nLen = (int)[frag_source length];
    src  = [frag_source UTF8String];
    
    glShaderSource(__fragmentShader, 1, &src, &nLen);
    GL_CHECK_ERROR
    
    glCompileShader(__fragmentShader);
    GL_CHECK_ERROR
    
    cStatus = 0;
    nLogLen = 0;
    glGetShaderiv(__fragmentShader, GL_COMPILE_STATUS, &cStatus);
    GL_CHECK_ERROR
    
    glGetShaderiv(__fragmentShader, GL_INFO_LOG_LENGTH, &nLogLen);
    if (nLogLen > 1)
    {
        GLchar* infoLog = malloc(nLogLen + 1);
        memset(infoLog, 0, nLogLen + 1);
        
        glGetShaderInfoLog(__fragmentShader, nLogLen, &nLogLen, infoLog);
        

        if (cStatus != GL_TRUE) {
            NSLog(@" - %@ FragmentShader %@", self.name, [NSString stringWithUTF8String:infoLog]);
        }
        
        free(infoLog);
    }
    
    if (cStatus)
    {
        glAttachShader(__programObject, __fragmentShader);
        GL_CHECK_ERROR
        glBindFragDataLocation(__programObject, 0, "FragColor");
        GL_CHECK_ERROR
        glBindFragDataLocation(__programObject, 1, "FragColor1");
        GL_CHECK_ERROR
        glBindFragDataLocation(__programObject, 2, "FragColor2");
        GL_CHECK_ERROR
        glBindFragDataLocation(__programObject, 3, "FragColor3");
        GL_CHECK_ERROR
        glBindFragDataLocation(__programObject, 4, "FragColor4");
        GL_CHECK_ERROR
    }
    
    glLinkProgram(__programObject);
    GL_CHECK_ERROR
    glGetProgramiv(__programObject, GL_LINK_STATUS, &cStatus);
    GL_CHECK_ERROR
    glGetProgramiv(__programObject, GL_INFO_LOG_LENGTH, &nLogLen);
    GL_CHECK_ERROR
    
    if (nLogLen > 1)
    {
        GLchar* infoLog = malloc(nLogLen + 1);
        memset(infoLog, 0, nLogLen + 1);
        glGetProgramInfoLog(__programObject, nLogLen, &nLogLen, infoLog);

        GL_CHECK_ERROR
        
        if (cStatus != GL_TRUE) {
            NSLog(@" - %@ ProgramObject %@", self.name, [NSString stringWithUTF8String:infoLog]);
        }
        free(infoLog);
    }

    if (cStatus)
    {
        int nMaxLen = 0;
        int nUniforms = 0;

        glGetProgramiv(__programObject, GL_ACTIVE_UNIFORMS, &nUniforms);
        glGetProgramiv(__programObject, GL_ACTIVE_UNIFORM_MAX_LENGTH, &nMaxLen);

        
        char * uName = malloc(nMaxLen);
        for (int i = 0; i < nUniforms; i++)
        {
            GLsizei nLen = 0;
            GLint  nSize = 0;
            
            VBUniform P = {0,0};
            
            
            glGetActiveUniform(__programObject, i, nMaxLen, &nLen, &nSize, &P.type, uName);
            P.location = glGetUniformLocation(__programObject, uName);
            
            NSValue *v = [NSValue valueWithBytes:&P objCType:@encode(VBUniform)];
            [_uniforms setObject:v forKey:[NSString stringWithUTF8String:uName]];
            
        }
        free(uName);


        VBUniform u = [self uniformWithName:@"mModelView"];
        if (!VBUniformIsZero(u)) {
            _mvm_loc = u.location;
        }

        u = [self uniformWithName:@"mModelViewProjection"];
        if (!VBUniformIsZero(u)) {
            _mvp_loc = u.location;
        }
        
        u = [self uniformWithName:@"vCamera"];
        if (!VBUniformIsZero(u)) {
            _cam_loc = u.location;
        }
        
        u = [self uniformWithName:@"vPrimaryLight"];
        if (!VBUniformIsZero(u)) {
            _l0_loc = u.location;
        }
        
        u = [self uniformWithName:@"mLightProjectionMatrix"];
        if (!VBUniformIsZero(u)) {
            _lp_loc = u.location;
        }
    
     
        GL_CHECK_ERROR
    }
    
}


- (NSString*) loadFromFile:(NSString*)file {
    
    file = [file stringByReplacingOccurrencesOfString:@"\\" withString:@"/"];
    
    NSString *fName = [_prog_folder stringByAppendingPathComponent:file];
    if (![[NSFileManager defaultManager] fileExistsAtPath:fName]) {
        fName = [[NSBundle mainBundle] pathForResource:file ofType:nil];
    }
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:fName]) {
        return [NSString stringWithContentsOfFile:fName encoding:NSUTF8StringEncoding error:nil];
    }
    return @"";
}


- (NSString *) parse:(NSString*)source {
        
    NSMutableString *newSource = [NSMutableString stringWithString:@"#version 150\nprecision highp float;\n"];
    
    NSArray *arrayDefines = [_defines componentsSeparatedByString:@", "];
    
    for (NSString *define in arrayDefines) {
        if ([define length] > 2) {
            [newSource appendString:@"\n#define "];
            [newSource appendString:define];
        }
    }
    
    [newSource appendString:@"\n"];
    [newSource appendString:source];
    
    NSRange range = [newSource rangeOfString:@"#include"];
    
    while (range.location != NSNotFound) {
        
        
        NSRange searchRange = range;
        searchRange.length += 50;
        NSRange r = [newSource rangeOfString:@"<" options:NSCaseInsensitiveSearch range:searchRange];
        
        NSRange include = NSMakeRange(NSNotFound, 0);
        
        if (r.location != NSNotFound) {
            include.location = r.location+1;
            r = [newSource rangeOfString:@">" options:NSCaseInsensitiveSearch range:searchRange];
            if (r.location != NSNotFound) {
                include.length = r.location-include.location;
            }
        } else {
            r = [newSource rangeOfString:@"\"" options:NSCaseInsensitiveSearch range:searchRange];
            if (r.location != NSNotFound) {
                searchRange.location = r.location+1;
                include.location = r.location+1;
                r = [newSource rangeOfString:@"\"" options:NSCaseInsensitiveSearch range:searchRange];
                if (r.location != NSNotFound) {
                    include.length = r.location-include.location;
                }
            }
        }
        
        if (include.location != NSNotFound && include.length > 0) {
            
            NSString *includeFile = [newSource substringWithRange:include];
            
            // here include file
            NSString *inc = [self loadFromFile:includeFile];
            
            if ([inc length] == 0) {
                NSLog(@"failed include %@", includeFile);
            }
            
            [newSource replaceCharactersInRange:NSMakeRange(range.location, r.location-range.location+1) withString:inc];
        }
        
        range = [newSource rangeOfString:@"#include"]; 
    }
    
    
    return newSource;
}



- (VBUniform) uniformWithName:(NSString*)uname {
    
    NSValue *value = [self.uniforms objectForKey:uname];
    
    VBUniform uniform = {0,0};
    [value getValue:&uniform];
    
    return uniform;
}


- (void) use {
    [self bind];
}

- (void) bind {
    glUseProgram(__programObject);
    GL_CHECK_ERROR
}


- (void) _uniformWithName:(NSString*)uname value:(void *)value {
    [self _uniformWithName:uname value:value count:1];
}

- (void) _uniformWithName:(NSString*)uname value:(void *)value count:(int)nCount {
    
    VBUniform uniform = [self uniformWithName:uname];
    
    
    if (VBUniformIsZero(uniform))
    {
        NSLog(@"Set missed uniform %@ for %@", uname, self.name);
        return;
    }

    switch(uniform.type)
    {
        case GL_FLOAT      : glUniform1fv(uniform.location, nCount, (GLfloat*)value); break;
        case GL_FLOAT_VEC2 : glUniform2fv(uniform.location, nCount, (GLfloat*)value); break;
        case GL_FLOAT_VEC3 : glUniform3fv(uniform.location, nCount, (GLfloat*)value); break;
        case GL_FLOAT_VEC4 : glUniform4fv(uniform.location, nCount, (GLfloat*)value); break;
        case GL_FLOAT_MAT2 : glUniformMatrix2fv(uniform.location, nCount, false, (GLfloat*)value); break;
        case GL_FLOAT_MAT3 : glUniformMatrix3fv(uniform.location, nCount, false, (GLfloat*)value); break;
        case GL_FLOAT_MAT4 : glUniformMatrix4fv(uniform.location, nCount, false, (GLfloat*)value); break;
        case GL_SAMPLER_1D:
        case GL_SAMPLER_1D_ARRAY:
        case GL_SAMPLER_1D_ARRAY_SHADOW:
        case GL_SAMPLER_1D_SHADOW:
        case GL_SAMPLER_2D:
        case GL_SAMPLER_2D_ARRAY:
        case GL_SAMPLER_2D_ARRAY_SHADOW:
        case GL_SAMPLER_2D_SHADOW:
        case GL_SAMPLER_2D_MULTISAMPLE:
        case GL_SAMPLER_2D_MULTISAMPLE_ARRAY:
        case GL_SAMPLER_2D_RECT:
        case GL_SAMPLER_2D_RECT_SHADOW:
        case GL_SAMPLER_3D:
        case GL_SAMPLER_BUFFER:
        case GL_SAMPLER_CUBE:  //0x8B60 = 35680
            
#ifdef GL_VERSION_4
        case GL_SAMPLER_CUBE_MAP_ARRAY:
        case GL_SAMPLER_CUBE_MAP_ARRAY_SHADOW:
#endif
        case GL_SAMPLER_CUBE_SHADOW : glUniform1iv(uniform.location, 1, (GLint*)value); break;
    }
    GL_CHECK_ERROR
}

- (void) setUniformTextures:(NSMutableArray*)names {
    [self bind];
    for (NSString *name in names) {
        int i = (int)[names indexOfObject:name];
        [self _uniformWithName:name value:&i];
    }
}

- (void) setPrimaryLightPosition:(GLKVector3)p {
    if (_l0_loc < 0) return;
    glUniform3fv(_l0_loc, 1, (GLfloat*)&p.v);
    GL_CHECK_ERROR
}

- (void) setMVPMatrix:(GLKMatrix4) m {
    if (_mvp_loc < 0) return;
    glUniformMatrix4fv(_mvp_loc, 1, false, (GLfloat*)&m.m);
    GL_CHECK_ERROR
}

- (void) setUniform:(NSString*)uname m:(GLKMatrix4)m {
//    [self _uniformWithName:uname value:&m];
    VBUniform uniform = [self uniformWithName:uname];
    glUniformMatrix4fv(uniform.location, 1, false, m.m);
}

- (void) setUniform:(NSString*)uname f:(float)f {
    VBUniform uniform = [self uniformWithName:uname];
    glUniform1f(uniform.location, f);
//    [self _uniformWithName:uname value:&f];
}

- (void) setUniform:(NSString*)uname v2:(GLKVector2)f {
    [self _uniformWithName:uname value:&f];
}

- (void) setUniform:(NSString*)uname v3:(GLKVector3)f {
    [self _uniformWithName:uname value:&f];
}

- (void) setUniform:(NSString*)uname v4:(GLKVector4)f {
    [self _uniformWithName:uname value:&f];
}

- (void) setUniform:(NSString*)uname m:(GLKMatrix4*)m  count:(int)count {
    [self _uniformWithName:uname value:m count:count];
}

//void setUniform(string name, mat4  value[], int nCount){_uniform(name, value, nCount);}


- (void) setCameraPosition:(GLKVector3)p {
    
    if (_cam_loc < 0) return;
    glUniform3fv(_cam_loc, 1, (GLfloat*)&p);

    GL_CHECK_ERROR
}

- (void) setModelViewMatrix:(GLKMatrix4)m {
    if (_mvm_loc < 0) return;
    glUniformMatrix4fv(_mvm_loc, 1, false, (GLfloat*)&m);
    GL_CHECK_ERROR
}

- (void) setLightProjectionMatrix:(GLKMatrix4)m {
    if (_lp_loc < 0) return;
    glUniformMatrix4fv(_lp_loc, 1, false, (GLfloat*)&m);
    GL_CHECK_ERROR
}


@end







#ifdef  __cplusplus_x_

bool Ce2ProgramObject::unload()
{
    Uniforms.clear();
    render()->unloadProgram(this);
    return true;
}


#endif
