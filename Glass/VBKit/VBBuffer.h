//
//  VBBuffer.h
//  Glass
//
//  Created by Volodymyr Boichentsov on 28/05/2013.
//  Copyright (c) 2013 Volodymyr Boichentsov. All rights reserved.
//

#import <Foundation/Foundation.h>


typedef enum {
	VBBufferAttrTypeV2 = 0,
    VBBufferAttrTypeV2_T2,
    VBBufferAttrTypeV3,
	VBBufferAttrTypeV3_N3,
    VBBufferAttrTypeV3_N3_T2,
    VBBufferAttrTypeV3_T2
} VBBufferAttrType;


typedef struct
{
    GLKVector3 vPosition;
    GLKVector3 vNormal;
    GLKVector2 vTexCoord;
} VERT_V3_N3_T2;


union _GLKVector2I
{
    struct { int x, y; };
    struct { int s, t; };
    int v[2];
};
typedef union _GLKVector2I GLKVector2I;


static __inline__ GLKVector3 fromSphericalRotated(float theta, float phi) {
    float fSinTheta = sin(theta);
    return GLKVector3Make(fSinTheta * cos(phi), cos(theta), fSinTheta * sin(phi));
}

static __inline__ GLKVector3 fromSpherical(float theta, float phi) {
    float fCosTheta = cos(theta);
    return GLKVector3Make( fCosTheta * cos(phi),
                sin(theta),
                fCosTheta * sin(phi) );
}

@interface VBBuffer : NSObject

//struct Ce2Buffer
//{
@property (nonatomic, retain) NSString *name;
@property (nonatomic)    int ID;
@property (nonatomic)    int nIndices;
@property (nonatomic)    int nDrawMode;
@property (nonatomic)    GLuint vertexArrayObject;
@property (nonatomic)    GLuint vertexBuffer;
@property (nonatomic)    GLuint indexBuffer;
@property (nonatomic)    int nAttribs;
@property (nonatomic) GLKVector3 center;

// backward compatibility
@property (nonatomic, retain) NSData *bufferData;
@property (nonatomic, retain) NSData * indexData;
    
- (void) bind;
- (void) renderAll;
- (void) drawAllElements;

- (void) unbind;

+ (instancetype) loadModel:(NSString*)modelFilePath;

+ (instancetype) loadModel:(NSString*)modelFilePath scale:(float)scale;


+ (instancetype) createPhotonMap:(NSString*)name size:(GLKVector2)size;

+ (instancetype) createVertexBuffer:(NSString *)name
                               type:(VBBufferAttrType)type
                           vertices:(NSData*)vData
                            indices:(NSData*)iData
                         indicesNum:(int)nIndices
                           drawMode:(int)nDrawMode;

+ (instancetype) createBox:(NSString*)name
                 dimension:(GLKVector3)vDimension
                 inNormals:(bool)invertNormals;

+ (instancetype) createSphere:(NSString *)name
                       radius:(float)radius
                          ver:(int)nVer
                          hor:(int)nHor;

@end
