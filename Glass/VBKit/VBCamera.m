//
//  VBCamera.m
//  Glass
//
//  Created by Volodymyr Boichentsov on 27/05/2013.
//  Copyright (c) 2013 Volodymyr Boichentsov. All rights reserved.
//

#import "VBCamera.h"

@interface VBCamera ()

@end

@implementation VBCamera


// camera ////////////////////////////////////////////////////////////
- (id) init {
    
    if (self = [super init]) {
        _lockUpVector = false;
        _modelViewMatrix   = GLKMatrix4Identity;
        _projectionMatrix = GLKMatrix4Identity;
        _position = GLKVector3Make(0, 0, 0);
        _view     = GLKVector3Make(0, 0, 0);
        return self;
    }
    return nil;
}


- (GLKMatrix4) projectionToTexutreMatrix {return _mat_lpr; }

- (GLKVector3) position {return _position;}
- (GLKVector3) sideVector {return GLKVector3Make( _modelViewMatrix.m00,  _modelViewMatrix.m10,  _modelViewMatrix.m20); }
- (GLKVector3) upVector {return GLKVector3Make( _modelViewMatrix.m01,  _modelViewMatrix.m11,  _modelViewMatrix.m21); }
- (GLKVector3) direction {return GLKVector3Make(-_modelViewMatrix.m02, -_modelViewMatrix.m12, -_modelViewMatrix.m22); }

- (float) nearClipplane {return _znear;}
- (float) farClipplane {return _zfar;}




- (void) lookAtFrom:(GLKVector3)from to:(GLKVector3)to up:(GLKVector3)up {
    _position = from;
    _view     = to;
    _modelViewMatrix   = GLKMatrix4Identity;
    
    GLKVector3 dir = GLKVector3Normalize(GLKVector3Subtract(to, from));
    
    GLKVector3 s = GLKVector3Normalize(GLKVector3CrossProduct(dir, up));
    GLKVector3 u = GLKVector3Normalize(GLKVector3CrossProduct(s, dir));
    
    GLKVector3 e = {
        -GLKVector3DotProduct(s, from),
        -GLKVector3DotProduct(u, from),
        GLKVector3DotProduct(dir, from)
    };
    
    
    _modelViewMatrix = GLKMatrix4SetColumn(_modelViewMatrix, 0, GLKVector4Make(s.x, u.x, -dir.x, 0.0));
    _modelViewMatrix = GLKMatrix4SetColumn(_modelViewMatrix, 1, GLKVector4Make(s.y, u.y, -dir.y, 0.0));
    _modelViewMatrix = GLKMatrix4SetColumn(_modelViewMatrix, 2, GLKVector4Make(s.z, u.z, -dir.z, 0.0));
    _modelViewMatrix = GLKMatrix4SetColumn(_modelViewMatrix, 3, GLKVector4Make(e.x, e.y,    e.z, 1.0));
    
    [self update];
}

- (void) perspectiveWithFov:(float)fov  aspect:(float)aspect near:(float)zNear far:(float) zFar {
    _aspect   = aspect;
    _fov      = fov;
    _znear    = zNear;
    _zfar     = zFar;
    _projectionMatrix = GLKMatrix4MakePerspective(fov, aspect, zNear, zFar);
    
    [self update];
}


- (void) setPosition:(GLKVector3)p {
    
    _position = p;
    GLKVector3 e = {
        GLKVector3DotProduct([self sideVector], p),
        GLKVector3DotProduct([self upVector], p),
        -GLKVector3DotProduct([self direction], p)
    };
    _modelViewMatrix = GLKMatrix4SetColumn(_modelViewMatrix, 3, GLKVector4Make(-e.x, -e.y, -e.z, 1.0));
    [self update];
}

- (void) update {
    
    _modelViewProjectionMatrix = GLKMatrix4Multiply(_projectionMatrix, _modelViewMatrix);
    _inverseMVPMatrix = GLKMatrix4Invert(_modelViewProjectionMatrix, NULL);
    _mat_lpr = GLKMatrix4Multiply(MATRIX_PROJECTION, _modelViewProjectionMatrix);
}


+ (GLKMatrix4Cube) cubemapMatrix:(GLKMatrix4)projectionMatrix pointOfView:(GLKVector3)pointOfView {
    
    GLKMatrix4Cube result;
    
    GLKMatrix4 translation = GLKMatrix4MakeTranslation(-pointOfView.x, -pointOfView.y, -pointOfView.z);
    
    GLKVector4 rX = GLKMatrix4GetColumn(projectionMatrix, 0);
    GLKVector4 rY = GLKMatrix4GetColumn(projectionMatrix, 1);
    GLKVector4 rZ = GLKMatrix4GetColumn(projectionMatrix, 2);
    GLKVector4 rW = GLKMatrix4GetColumn(projectionMatrix, 3);
    
    result.m[0] = GLKMatrix4Multiply(GLKMatrix4MakeWithColumns( GLKVector4Negate(rZ), GLKVector4Negate(rY), GLKVector4Negate(rX), rW), translation );
    result.m[1] = GLKMatrix4Multiply(GLKMatrix4MakeWithColumns(  rZ, GLKVector4Negate(rY),  rX, rW ), translation);
    result.m[2] = GLKMatrix4Multiply(GLKMatrix4MakeWithColumns(  rX, GLKVector4Negate(rZ),  rY, rW ), translation);
    result.m[3] = GLKMatrix4Multiply(GLKMatrix4MakeWithColumns(  rX,  rZ, GLKVector4Negate(rY), rW ), translation);
    result.m[4] = GLKMatrix4Multiply(GLKMatrix4MakeWithColumns(  rX, GLKVector4Negate(rY), GLKVector4Negate(rZ), rW ), translation);
    result.m[5] = GLKMatrix4Multiply(GLKMatrix4MakeWithColumns( GLKVector4Negate(rX), GLKVector4Negate(rY), rZ, rW ), translation);
    
    return result;
}


//
//void Ce2Camera::LookAt(float x, float y, float z, float vx, float vy, float vz, float ux, float uy, float uz)
//{
//    lookAt(
//           vec3( x,  y,  z),
//           vec3(vx, vy, vz),
//           vec3(ux, uy, uz) );
//}


@end
