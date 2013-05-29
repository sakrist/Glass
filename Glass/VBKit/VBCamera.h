//
//  VBCamera.h
//  Glass
//
//  Created by Volodymyr Boichentsov on 27/05/2013.
//  Copyright (c) 2013 Volodymyr Boichentsov. All rights reserved.
//

#import <Foundation/Foundation.h>

#define MATRIX_PROJECTION (GLKMatrix4){ 0.5, 0.0, 0.0, 0.0, 0.0, 0.5, 0.0, 0.0, 0.0, 0.0, 0.5, 0.0, 0.5, 0.5, 0.5, 1.0 }

GLK_INLINE GLKVector4 GLKVector4MakeOne(float v)
{
    GLKVector4 vector = { v, v, v, v };
    return vector;
}

union _GLKMatrix4Cube
{
    GLKMatrix4 m[6];
    float v[96];
};
typedef union _GLKMatrix4Cube GLKMatrix4Cube;


@interface VBCamera : NSObject {

@public
    GLKVector3 _position;
    GLKVector3 _view;
    GLKMatrix4 _mat_mv;
    GLKMatrix4 _mat_proj;
    GLKMatrix4 _mat_mvp;
    GLKMatrix4 _mat_lpr;
    GLKMatrix4 _mat_inv_mvp;
    float _fov;
    float _aspect;
    float _znear;
    float _zfar;
    
}

@property (nonatomic) bool lockUpVector;
@property (nonatomic) GLKMatrix4 modelViewMatrix;
@property (nonatomic) GLKMatrix4 modelViewProjectionMatrix;
@property (nonatomic) GLKMatrix4 projectionMatrix;
@property (nonatomic) GLKMatrix4 inverseMVPMatrix;

- (GLKMatrix4) projectionToTexutreMatrix;
- (GLKVector3) position;
- (GLKVector3) sideVector;
- (GLKVector3) upVector;
- (GLKVector3) direction;

- (float) nearClipplane;
- (float) farClipplane;


- (void) lookAtFrom:(GLKVector3)from to:(GLKVector3)to up:(GLKVector3)up;

- (void) perspectiveWithFov:(float)fov  aspect:(float)aspect near:(float)zNear far:(float) zFar;

- (void) setPosition:(GLKVector3)p;

- (void) update;

+ (GLKMatrix4Cube) cubemapMatrix:(GLKMatrix4)projectionMatrix pointOfView:(GLKVector3)pointOfView;

@end
