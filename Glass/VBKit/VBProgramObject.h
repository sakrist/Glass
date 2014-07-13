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
    
}

@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSMutableDictionary *uniforms;

+ (instancetype) loadProgram:(NSString*)filename;
+ (instancetype) loadProgram:(NSString*)filename param:(NSString*)param;

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


@end
