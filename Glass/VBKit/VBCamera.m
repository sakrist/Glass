//
//  VBCamera.m
//  Glass
//
//  Created by Volodymyr Boichentsov on 27/05/2013.
//  Copyright (c) 2013 Volodymyr Boichentsov. All rights reserved.
//

#import "VBCamera.h"

#pragma mark - decompose matrix -

// decompose scale from matrix
static __inline__ GLKVector3 GLKVector3ScaleFromMatrix4(GLKMatrix4 m) {
    
    GLKVector3 v = GLKVector3Make(sqrt(m.m[0]*m.m[0] + m.m[1]*m.m[1] +m.m[2]*m.m[2]),
                                  sqrt(m.m[4]*m.m[4] + m.m[5]*m.m[5] +m.m[6]*m.m[6]),
                                  sqrt(m.m[8]*m.m[8] + m.m[9]*m.m[9] +m.m[10]*m.m[10]));
    
    return v;
}

// decompose rotation matrix from main matrix
static __inline__ GLKMatrix4 GLKMatrix4RotationFromMatrix(GLKMatrix4 m) {
    
    GLKVector3 s = GLKVector3ScaleFromMatrix4(m);
    
    GLKMatrix4 n_matrix;
    n_matrix.m[0] = m.m[0]/s.v[0];
    n_matrix.m[1] = m.m[1]/s.v[0];
    n_matrix.m[2] = m.m[2]/s.v[0];
    n_matrix.m[3] = 0;
    
    n_matrix.m[4] = m.m[4]/s.v[1];
    n_matrix.m[5] = m.m[5]/s.v[1];
    n_matrix.m[6] = m.m[6]/s.v[1];
    n_matrix.m[7] = 0;
    
    n_matrix.m[8] = m.m[8]/s.v[2];
    n_matrix.m[9] = m.m[9]/s.v[2];
    n_matrix.m[10] = m.m[10]/s.v[2];
    n_matrix.m[11] = 0;
    
    n_matrix.m[12] = 0;
    n_matrix.m[13] = 0;
    n_matrix.m[14] = 0;
    n_matrix.m[15] = 1;
    
    return n_matrix;
}

// decompose yaw rotation angle from matrix
static __inline__ float GLKMatrix4YawFromMatrixRotation(GLKMatrix4 _r){
    float _yaw = 0;
    if (_r.m[4] == 1 || _r.m[4] == -1) {
        _yaw = atan2(-_r.m[2],_r.m[10]);
    } else {
        _yaw = atan2(-_r.m[8],_r.m[0]);
    }
    
    return _yaw;
}


#pragma mark -  Quaternion -



static __inline__ GLKQuaternion GLKQuaternionFromMatrix(GLKMatrix4 rotationMatrix)
{
    
    float qw = 1;
    float qx = 0;
    float qy = 0;
    float qz = 0;
    
    float tr = rotationMatrix.m[0] + rotationMatrix.m[5] + rotationMatrix.m[10] + 1;
    
    //If the trace of the matrix is greater than zero, then
    //    perform an "instant" calculation.
    if (tr > 0) {
        float S = 0.5 / sqrt(tr);
        qw = 0.25 / S;
        
        qx = (rotationMatrix.m[6] - rotationMatrix.m[9]) * S;
        qy = (rotationMatrix.m[8] - rotationMatrix.m[2]) * S;
        qz = (rotationMatrix.m[1] - rotationMatrix.m[4]) * S;
    }
    /* If the trace of the matrix is less than or equal to zero
     then identify which major diagonal element has the greatest
     value.*/
    else if ((rotationMatrix.m[0] > rotationMatrix.m[5]) && (rotationMatrix.m[0] > rotationMatrix.m[10])) {
        float S = sqrt(1.0 + rotationMatrix.m[0] - rotationMatrix.m[5] - rotationMatrix.m[10]) * 2; // S=4*qx
        qx = 0.5 / S;
        qy = (rotationMatrix.m[4] + rotationMatrix.m[1]) / S;
        qz = (rotationMatrix.m[8] + rotationMatrix.m[2]) / S;
        qw = (rotationMatrix.m[9] + rotationMatrix.m[6]) / S;
    } else if (rotationMatrix.m[5] > rotationMatrix.m[10]) {
        float S = sqrt(1.0 + rotationMatrix.m[5] - rotationMatrix.m[0] - rotationMatrix.m[10]) * 2; // S=4*qy
        
        qx = (rotationMatrix.m[4] + rotationMatrix.m[1]) / S;
        qy = 0.5 / S;
        qz = (rotationMatrix.m[9] + rotationMatrix.m[6]) / S;
        qw = (rotationMatrix.m[8] + rotationMatrix.m[2]) / S;
        
    } else {
        float S = sqrt(1.0 + rotationMatrix.m[10] - rotationMatrix.m[5] - rotationMatrix.m[0]) * 2; // S=4*qz
        
        qx = (rotationMatrix.m[8] + rotationMatrix.m[2]) / S;
        qy = (rotationMatrix.m[9] + rotationMatrix.m[6]) / S;
        qz = 0.5 / S;
        qw = (rotationMatrix.m[4] + rotationMatrix.m[1]) / S;
    }
    
    return GLKQuaternionMake(qx, qy, qz, qw);
}

static __inline__ float GLKQuaternionPitch(GLKQuaternion q) {
    float _pitch = atan2(2*(q.q[1]*q.q[2] + q.q[3]*q.q[0]), q.q[3]*q.q[3] - q.q[0]*q.q[0] - q.q[1]*q.q[1] + q.q[2]*q.q[2]);
    return _pitch;
}

static __inline__ float GLKQuaternionRoll(GLKQuaternion q) {
    float roll = atan2(2*(q.q[0]*q.q[1] + q.q[3]*q.q[2]), q.q[3]*q.q[3] + q.q[0]*q.q[0] - q.q[1]*q.q[1] - q.q[2]*q.q[2]);
    return roll;
}

static __inline__ float GLKQuaternionYaw(GLKQuaternion q) {
    float yaw = asin(-2*(q.q[0]*q.q[2] - q.q[3]*q.q[1]));
    return yaw;
}

@interface VBCamera ()

@end

@implementation VBCamera

- (id) init {
    
    if (self = [super init]) {
        _lockUpVector = false;
        _modelViewMatrix   = GLKMatrix4Identity;
        _projectionMatrix = GLKMatrix4Identity;
        self.position = GLKVector3Make(0, 0, 0);
        _view     = GLKVector3Make(0, 0, 0);
        return self;
    }
    return nil;
}



- (GLKVector3) sideVector {
    return GLKVector3Make( _modelViewMatrix.m00,  _modelViewMatrix.m10,  _modelViewMatrix.m20);
}

- (GLKVector3) upVector {
    return GLKVector3Make( _modelViewMatrix.m01,  _modelViewMatrix.m11,  _modelViewMatrix.m21);
}

- (GLKVector3) direction {
    return GLKVector3Make(-_modelViewMatrix.m02, -_modelViewMatrix.m12, -_modelViewMatrix.m22);
}



- (void) rotateWithVector:(GLKVector3)rotationVector aroundPoint:(GLKVector3)center {
    
    // first step: extracting rotation angles
    
    GLKMatrix4 temp = GLKMatrix4TranslateWithVector3(_modelViewMatrix, center);
    GLKMatrix4 _rm = GLKMatrix4RotationFromMatrix(temp);
    
    double _yaw = GLKMatrix4YawFromMatrixRotation(_rm);
    _rm = GLKMatrix4RotateY(_rm, _yaw);
    
    
    GLKQuaternion q = GLKQuaternionNormalize(GLKQuaternionFromMatrix(_rm));
    double _pitch = GLKQuaternionPitch(q);
    
    double _roll = GLKQuaternionRoll(q);
    
    
    float _pitchRotation = -_pitch;
    float  _yawRotation = -_yaw;
    
    // applying rotation delta to angles
    
    _yawRotation += rotationVector.x;
    _pitchRotation += rotationVector.y;
    _roll += rotationVector.z;
    
    
    if(_pitchRotation <= -M_PI_2) {
        _pitchRotation = -M_PI_2;
    } else if(_pitchRotation >= M_PI_2) {
        _pitchRotation = M_PI_2;
    }
    
    GLKMatrix4 _rotMatrix = GLKMatrix4Multiply(GLKMatrix4MakeXRotation(-_pitchRotation), GLKMatrix4MakeYRotation(_yawRotation));
    _rotMatrix = GLKMatrix4Multiply(_rotMatrix, GLKMatrix4MakeZRotation(_roll));
    // appluing new rotation matrix
    
    _rm = _modelViewMatrix;
    
    _rm = GLKMatrix4TranslateWithVector3(_rm, center);
    
    _rm = GLKMatrix4Multiply(_rm, GLKMatrix4Invert(GLKMatrix4RotationFromMatrix(_rm), nil));
    _rm = GLKMatrix4Multiply(_rm, _rotMatrix);
    
    _rm = GLKMatrix4TranslateWithVector3(_rm, GLKVector3Negate(center));
    
    _modelViewMatrix = _rm;
    
    [self update];
}



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



@end
