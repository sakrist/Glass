//
//  VBProgramObject.h
//  Glass
//
//  Created by Volodymyr Boichentsov on 27/05/2013.
//  Copyright (c) 2013 Volodymyr Boichentsov. All rights reserved.
//

#import <Foundation/Foundation.h>

union _VB_PROGRAM_UNIFORM
{
    struct {
        GLenum type;
        GLint  location;
    };
    int p[2];
};
typedef union _VB_PROGRAM_UNIFORM VBUniform;

static __inline__ bool VBUniformIsZero(VBUniform u) {
    if (u.p[0] == 0 && u.p[1] == 0) {
        return true;
    }
    return false;
}


@interface VBProgramObject : NSObject {
    int _mvm_loc;
    int _mvp_loc;
    int _cam_loc;
    int _l0_loc;
    int _lp_loc;
    
    GLint ProgramObject;
    GLint VertexShader;
    GLint GeometryShader;
    GLint FragmentShader;
    NSString *name;
    
    int ID;

}

@property (nonatomic, retain) NSMutableDictionary *uniforms;

+ (id) loadProgram:(NSString*)filename;
+ (id) loadProgram:(NSString*)filename param:(NSString*)param;

- (void) setUniformTextures:(NSMutableArray*)names;
- (VBUniform) uniformWithName:(NSString*)uname;

- (void) bind;
- (void) use;

- (void) setPrimaryLightPosition:(GLKVector3)p;
- (void) setMVPMatrix:(GLKMatrix4) m;

- (void) _uniformWithName:(NSString*)uname value:(void *)value;
- (void) _uniformWithName:(NSString*)uname value:(void *)value count:(int)nCount;

- (void) setUniform:(NSString*)uname m:(GLKMatrix4)m;
- (void) setUniform:(NSString*)uname f:(float)f;
- (void) setUniform:(NSString*)uname v2:(GLKVector2)f;
- (void) setUniform:(NSString*)uname v3:(GLKVector3)f;
- (void) setUniform:(NSString*)uname v4:(GLKVector4)f;

- (void) setUniform:(NSString*)uname m:(GLKMatrix4*)m  count:(int)count;

- (void) setCameraPosition:(GLKVector3)p;

- (void) setModelViewMatrix:(GLKMatrix4)m;
- (void) setLightProjectionMatrix:(GLKMatrix4)m;


//int& modelViewMatrixUniformLocation(){return _mvm_loc;}
//int& mvpMatrixUniformLocation()      {return _mvp_loc;}
//int& cameraUniformLocation()         {return _cam_loc;}
//int& primaryLightUniformLocation()   {return _l0_loc;}
//int& lightProjectionMatrixLocation() {return _lp_loc;}
//
//void setUniform(string name,                   float x, float y){float val[2] = {x, y};       _uniform(name, val);}
//void setUniform(string name,          float x, float y, float z){float val[3] = {x, y, z};    _uniform(name, val);}
//void setUniform(string name, float x, float y, float z, float w){float val[4] = {x, y, z, w}; _uniform(name, val);}
//void setUniform(string name, int count, void* value){_uniform(name, value, count);}
//
//// arrays
//void setUniform(string name, float value[], int nCount){_uniform(name, value, nCount);}
//void setUniform(string name, vec2  value[], int nCount){_uniform(name, value, nCount);}
//void setUniform(string name, vec3  value[], int nCount){_uniform(name, value, nCount);}
//void setUniform(string name, vec4  value[], int nCount){_uniform(name, value, nCount);}
//void setUniform(string name, mat4  value[], int nCount){_uniform(name, value, nCount);}
//
//// samplers
//void setUniform(string name, int value){_uniform(name, &value);}

@end
