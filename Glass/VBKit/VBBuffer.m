//
//  VBBuffer.m
//  Glass
//
//  Created by Volodymyr Boichentsov on 28/05/2013.
//  Copyright (c) 2013 Volodymyr Boichentsov. All rights reserved.
//

#import "VBBuffer.h"

#define BUFFER_OFFSET(i) ((GLfloat *)NULL + (i))

@implementation VBBuffer


-(void) drawAllElements {

    glDrawElements(_nDrawMode, _nIndices, GL_UNSIGNED_INT, NULL);
    
//    if (render()->supportVertexBuffers())
//        DrawElements(nDrawMode, nIndices, GL_UNSIGNED_INT, NULL);
//    else
//        DrawElements(nDrawMode, nIndices, GL_UNSIGNED_INT, (GLvoid*)indexData);
}

- (void) renderAll {
    [self bind];
    [self drawAllElements];
//    unbind();
}

- (void) genVertexBuffer {
    glGenBuffers(1, &_vertexBuffer);
}

- (void) genIndexBuffer {
    glGenBuffers(1, &_indexBuffer);
}

- (void) genVAOBuffer {
    glGenVertexArrays(1, &_vertexArrayObject);
}

- (void) bind {
    glBindVertexArray(_vertexArrayObject);
}

- (void) unbind {
    glBindVertexArray(0);
}

+ (VBBuffer*) createVertexBuffer:(NSString *)name type:(VBBufferAttrType)type
                        vertices:(NSData*)vData indices:(NSData*)iData
                      indicesNum:(int)nIndices drawMode:(int)nDrawMode {
    
    VBBuffer* Buffer = [[VBBuffer alloc] init];
    
    Buffer.name = name;
    Buffer.nDrawMode = nDrawMode;
    Buffer.bufferData = vData;
    Buffer.indexData = iData;
    Buffer.nIndices = nIndices;
    

    [Buffer genVAOBuffer];
    [Buffer bind];
    
    GL_CHECK_ERROR
    
    [Buffer genVertexBuffer];
    GL_CHECK_ERROR
    
    glBindBuffer(GL_ARRAY_BUFFER, Buffer.vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, [vData length], [vData bytes], GL_STATIC_DRAW);
    GL_CHECK_ERROR
    
//#define RENDER_ATTRIB_POSITION  0
//#define RENDER_ATTRIB_NORMAL    1
//#define RENDER_ATTRIB_TEXCOORD0 2
//#define RENDER_ATTRIB_TANGENT   3
    
    if (type == VBBufferAttrTypeV2) {
        glEnableVertexAttribArray(RENDER_ATTRIB_POSITION);
        glVertexAttribPointer(RENDER_ATTRIB_POSITION, 2, GL_FLOAT, GL_FALSE, 8, BUFFER_OFFSET(0));
    }
    
    if (type == VBBufferAttrTypeV3_N3 || type == VBBufferAttrTypeV3_N3_T2) {
        
        int size = (type == VBBufferAttrTypeV3_N3)? 24 : 32;
        
        glEnableVertexAttribArray(RENDER_ATTRIB_POSITION);
        glVertexAttribPointer(RENDER_ATTRIB_POSITION, 3, GL_FLOAT, GL_FALSE, size, BUFFER_OFFSET(0));
        
        glEnableVertexAttribArray(RENDER_ATTRIB_NORMAL);
        glVertexAttribPointer(RENDER_ATTRIB_NORMAL, 3, GL_FLOAT, GL_FALSE, size, BUFFER_OFFSET(3));
        
        if (type == VBBufferAttrTypeV3_N3_T2) {
            glEnableVertexAttribArray(RENDER_ATTRIB_TEXCOORD0);
            glVertexAttribPointer(RENDER_ATTRIB_TEXCOORD0, 2, GL_FLOAT, GL_FALSE, size, BUFFER_OFFSET(6));
        }
    }
    
    GL_CHECK_ERROR
    
    [Buffer genIndexBuffer];
    GL_CHECK_ERROR
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, Buffer.indexBuffer);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, [iData length], [iData bytes], GL_STATIC_DRAW);
    GL_CHECK_ERROR
    
    glBindVertexArray(0);
    
    return Buffer;
}

+ (VBBuffer*) createPhotonMap:(NSString*)name size:(GLKVector2)size {
    
    int numPhotons = size.x * size.y;
    GLKVector2 texel = GLKVector2Make(1.0f / size.x, 1.0f / size.y);
    GLKVector2 dxdy = GLKVector2Make(0.5f / size.x, 0.5f / size.y);
    
    NSMutableData *vData = [NSMutableData data];
    NSMutableData *iData = [NSMutableData data];
    //    vec2* photons = new vec2[numPhotons];
    //    Index* indices = new Index[numPhotons];
    
    int k = 0;
    for (int i = 0; i < (int)size.y; ++i) {
        for (int j = 0; j < (int)size.x; ++j) {
            GLKVector2 p = GLKVector2Make(j * texel.x, i * texel.y);
            p = GLKVector2Add(p, dxdy);
            
            [vData appendBytes:&p length:sizeof(GLKVector2)];
            [iData appendBytes:&k length:4];
            k++;
        }
    }
    
    VBBuffer *photonBuffer = [VBBuffer createVertexBuffer:name type:VBBufferAttrTypeV2
                                                 vertices:vData indices:iData
                                               indicesNum:numPhotons drawMode:GL_POINTS];
    
    return photonBuffer;
}


+ (VBBuffer *) createBox:(NSString*)name dimension:(GLKVector3)vDimension  inNormals:(bool)invertNormals {
    
    const int num_verts = 36;
    
    VERT_V3_N3_T2 vert[num_verts];
    int index[num_verts];
    
    float fInv = invertNormals ? -1.0f : 1.0f;
    
    for (int i =  0; i <  6; ++i) vert[i].vNormal = GLKVector3MultiplyScalar(GLKVector3Make( 0.0, -1.0,  0.0), fInv);
    for (int i =  6; i < 12; ++i) vert[i].vNormal = GLKVector3MultiplyScalar(GLKVector3Make( 0.0,  1.0,  0.0), fInv);
    for (int i = 12; i < 18; ++i) vert[i].vNormal = GLKVector3MultiplyScalar(GLKVector3Make(-1.0,  0.0,  0.0), fInv);
    for (int i = 18; i < 24; ++i) vert[i].vNormal = GLKVector3MultiplyScalar(GLKVector3Make( 1.0,  0.0,  0.0), fInv);
    for (int i = 24; i < 30; ++i) vert[i].vNormal = GLKVector3MultiplyScalar(GLKVector3Make( 0.0,  0.0,  1.0), fInv);
    for (int i = 30; i < 36; ++i) vert[i].vNormal = GLKVector3MultiplyScalar(GLKVector3Make( 0.0,  0.0, -1.0), fInv);
    
    for (int i = 0; i < 6; ++i)
    {
        vert[6*i+0].vTexCoord = GLKVector2Make(1.0, 1.0);
        vert[6*i+1].vTexCoord = GLKVector2Make(0.0, 1.0);
        vert[6*i+2].vTexCoord = GLKVector2Make(0.0, 0.0);
        vert[6*i+3].vTexCoord = GLKVector2Make(1.0, 0.0);
        vert[6*i+4].vTexCoord = GLKVector2Make(1.0, 1.0);
        vert[6*i+5].vTexCoord = GLKVector2Make(0.0, 0.0);
    }
    
    vert[ 0].vPosition = GLKVector3Make( vDimension.x, -vDimension.y,  vDimension.z);
    vert[ 1].vPosition = GLKVector3Make(-vDimension.x, -vDimension.y,  vDimension.z);
    vert[ 2].vPosition = GLKVector3Make(-vDimension.x, -vDimension.y, -vDimension.z);
    vert[ 3].vPosition = GLKVector3Make( vDimension.x, -vDimension.y, -vDimension.z);
    vert[ 4].vPosition = GLKVector3Make( vDimension.x, -vDimension.y,  vDimension.z);
    vert[ 5].vPosition = GLKVector3Make(-vDimension.x, -vDimension.y, -vDimension.z);
    vert[ 6].vPosition = GLKVector3Make(-vDimension.x,  vDimension.y,  vDimension.z);
    vert[ 7].vPosition = GLKVector3Make( vDimension.x,  vDimension.y,  vDimension.z);
    vert[ 8].vPosition = GLKVector3Make( vDimension.x,  vDimension.y, -vDimension.z);
    vert[ 9].vPosition = GLKVector3Make(-vDimension.x,  vDimension.y, -vDimension.z);
    vert[10].vPosition = GLKVector3Make(-vDimension.x,  vDimension.y,  vDimension.z);
    vert[11].vPosition = GLKVector3Make( vDimension.x,  vDimension.y, -vDimension.z);
    vert[12].vPosition = GLKVector3Make(-vDimension.x,  vDimension.y, -vDimension.z);
    vert[13].vPosition = GLKVector3Make(-vDimension.x, -vDimension.y, -vDimension.z);
    vert[14].vPosition = GLKVector3Make(-vDimension.x, -vDimension.y,  vDimension.z);
    vert[15].vPosition = GLKVector3Make(-vDimension.x,  vDimension.y,  vDimension.z);
    vert[16].vPosition = GLKVector3Make(-vDimension.x,  vDimension.y, -vDimension.z);
    vert[17].vPosition = GLKVector3Make(-vDimension.x, -vDimension.y,  vDimension.z);
    vert[18].vPosition = GLKVector3Make( vDimension.x,  vDimension.y,  vDimension.z);
    vert[19].vPosition = GLKVector3Make( vDimension.x, -vDimension.y,  vDimension.z);
    vert[20].vPosition = GLKVector3Make( vDimension.x, -vDimension.y, -vDimension.z);
    vert[21].vPosition = GLKVector3Make( vDimension.x,  vDimension.y, -vDimension.z);
    vert[22].vPosition = GLKVector3Make( vDimension.x,  vDimension.y,  vDimension.z);
    vert[23].vPosition = GLKVector3Make( vDimension.x, -vDimension.y, -vDimension.z);
    vert[24].vPosition = GLKVector3Make(-vDimension.x,  vDimension.y,  vDimension.z);
    vert[25].vPosition = GLKVector3Make(-vDimension.x, -vDimension.y,  vDimension.z);
    vert[26].vPosition = GLKVector3Make( vDimension.x, -vDimension.y,  vDimension.z);
    vert[27].vPosition = GLKVector3Make( vDimension.x,  vDimension.y,  vDimension.z);
    vert[28].vPosition = GLKVector3Make(-vDimension.x,  vDimension.y,  vDimension.z);
    vert[29].vPosition = GLKVector3Make( vDimension.x, -vDimension.y,  vDimension.z);
    vert[30].vPosition = GLKVector3Make( vDimension.x,  vDimension.y, -vDimension.z);
    vert[31].vPosition = GLKVector3Make( vDimension.x, -vDimension.y, -vDimension.z);
    vert[32].vPosition = GLKVector3Make(-vDimension.x, -vDimension.y, -vDimension.z);
    vert[33].vPosition = GLKVector3Make(-vDimension.x,  vDimension.y, -vDimension.z);
    vert[34].vPosition = GLKVector3Make( vDimension.x,  vDimension.y, -vDimension.z);
    vert[35].vPosition = GLKVector3Make(-vDimension.x, -vDimension.y, -vDimension.z);
    
    for (int i = 0; i < num_verts; i++) {
        index[i] = i;
    }
    
    NSData *vData = [NSData dataWithBytes:&vert length:sizeof(vert)];
    NSData *iData = [NSData dataWithBytes:&index length:sizeof(index)];
    
    VBBuffer *b = [VBBuffer createVertexBuffer:name
                                          type:VBBufferAttrTypeV3_N3_T2
                                      vertices:vData indices:iData indicesNum:36 drawMode:GL_TRIANGLES];
    return b;
//    return createVertexBuffer(name, VERT_V3_N3_T2::getRA(), num_verts, vert, num_verts, index, GL_TRIANGLES);
}

+ (VBBuffer*) createSphere:(NSString *)name radius:(float)radius ver:(int)nVer hor:(int)nHor {
    
    GLKVector2I dimension = {MAX(4, nHor), MAX(3, nVer)};
        
    NSMutableData *vData = [VBBuffer createSphere_v3n3t2:radius density:dimension];
    NSMutableData *iData = [NSMutableData data];
    int num_index = [VBBuffer buildTriangleStripIndexes:iData dim:dimension];
    
    VBBuffer *R = [VBBuffer createVertexBuffer:name
                                          type:VBBufferAttrTypeV3_N3_T2
                                      vertices:vData
                                       indices:iData
                                    indicesNum:num_index
                                      drawMode:GL_TRIANGLE_STRIP];
    
    return R;
}

+ (int) buildTriangleStripIndexes:(NSMutableData*)idata dim:(GLKVector2I)dim {
    
    int k = 0;
    int i = 0;
    for (int v = 0; v < dim.y - 1; v++)
    {
        if (v % 2)
            for (int u = dim.x - 1; u >= 0; u--)
            {
                
                i = u + ( v ) * dim.x; k++;
                [idata appendBytes:&i length:4];
                
                i = u + (v+1) * dim.x; k++;
                [idata appendBytes:&i length:4];
            }
        else
            for (int u = 0; u < dim.x; u++)
            {
                i = u + (v+1) * dim.x; k++;
                [idata appendBytes:&i length:4];
                
                i = u + ( v ) * dim.x;  k++;
                [idata appendBytes:&i length:4];
            }
    }
    
    return k;
}



+ (NSMutableData*) createSphere_v3n3t2:(float)radius density:(GLKVector2I)gridDensity {
    
    
    NSMutableData *data = [NSMutableData data];
    
    VERT_V3_N3_T2 buffer;
    
    float dPhi = M2_PI / (gridDensity.x - 1.0f);
    float dTheta = M_PI / (gridDensity.y - 1.0f);
    
    float theta = 0;
    for (int i = 0; i < gridDensity.y; i++)
    {
        float phi = 0;
        for (int j = 0; j < gridDensity.x; j++)
        {
            buffer.vPosition = fromSphericalRotated(theta, phi);
            buffer.vPosition = GLKVector3MultiplyScalar(buffer.vPosition, radius);
            
            buffer.vNormal = GLKVector3Normalize(buffer.vPosition);
            buffer.vTexCoord = GLKVector2Make(j / (gridDensity.x - 1), 1.0f - i / (gridDensity.y - 1));
            
            [data appendBytes:&buffer length:sizeof(VERT_V3_N3_T2)];
            
            phi += dPhi;
        }
        theta += dTheta;
    } 
    return data;
}


+ (id) loadModel:(NSString*)modelFilePath  {
    return [VBBuffer loadModel:modelFilePath withScale:1];
}

+ (id) loadModel:(NSString*)modelFilePath withScale:(float)scale {
    
    NSData *data = [NSData dataWithContentsOfFile:modelFilePath];
    
    int bytesOffset = 0;
    
    GLKVector3 min_vec;
    [data getBytes:&min_vec range:NSMakeRange(bytesOffset, 4*3)];
    bytesOffset += sizeof(min_vec);
    
//    NSLog(@"min %f %f %f", min_vec[0], min_vec[1], min_vec[2]);
    
    GLKVector3 max_vec;
    [data getBytes:&max_vec range:NSMakeRange(bytesOffset, 4*3)];
    bytesOffset += sizeof(max_vec);
    
    GLKVector3 size = GLKVector3Subtract(max_vec, min_vec);
    GLKVector3 center = GLKVector3MultiplyScalar(GLKVector3Add(max_vec, min_vec), 0.5);
    
    float size_mag = GLKVector3Length(size);
    float m_scale = 250.0f / size_mag;
//    NSLog(@"model %f %f", size_mag, m_scale);
    
    if (scale < m_scale) {
        m_scale = scale;
    }
    
//    NSLog(@"min %f %f %f", max_vec[0], max_vec[1], max_vec[2]);
    
    int icount = 0;
    [data getBytes:&icount range:NSMakeRange(bytesOffset, 4)];
    bytesOffset += 4;
    
//    NSLog(@"index count %d", icount);
    
    // read indices
    NSMutableData *indicesData = [NSMutableData dataWithData:[data subdataWithRange:NSMakeRange(bytesOffset,  sizeof(GLuint) * icount)]];
    bytesOffset += sizeof(GLuint) * icount;
    
    int vcount = 0;
    [data getBytes:&vcount range:NSMakeRange(bytesOffset, 4)];
    bytesOffset += 4;
    
    NSMutableData *verticesData = [NSMutableData dataWithData:[data subdataWithRange:NSMakeRange(bytesOffset, vcount*(3+3)*4)]];
    
    if (m_scale != 1) {
        GLKVector3 *v = (GLKVector3*)[verticesData bytes];
        
//        GLKVector3 max_new = GLKVector3Make(-10000.0,-10000.0,-10000.0);
//        GLKVector3 min_new = GLKVector3Make( 10000.0, 10000.0, 10000.0);
        
        int all_vn = vcount*2;
        for (int i = 0; i < all_vn; i += 2) {
            v[i] = GLKVector3MultiplyScalar(GLKVector3Subtract(v[i], center), m_scale);
//            max_new = GLKVector3Maximum(max_new, v[i]);
//            min_new = GLKVector3Minimum(min_new, v[i]);
        }
        
    }
    
//    NSLog(@"vertices count %d", vcount);
    bytesOffset += vcount*(3+3)*4; // end
    
//    NSLog(@" %d %d", bytesOffset, data.length);
    
    
    VBBuffer *R = [VBBuffer createVertexBuffer:[modelFilePath lastPathComponent]
                                          type:VBBufferAttrTypeV3_N3
                                      vertices:verticesData
                                       indices:indicesData
                                    indicesNum:icount
                                      drawMode:GL_TRIANGLES];
    
    center = GLKVector3MultiplyScalar(center, m_scale);
    center = GLKVector3Add(center, GLKVector3Make(0.0, -10.0, -5.0));
    
    R.center = center;
    
    GL_CHECK_ERROR
    return R;
    
    
}



@end
