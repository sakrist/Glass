uniform sampler2D refractive_normals;
uniform sampler2D refractive_depth;
uniform sampler2D receiver_depth;
uniform sampler2D refractive_backface_normals;
uniform sampler2D refractive_backface_depth;

uniform vec3 vCamera;
uniform mat4 mModelViewProjection;
uniform mat4 mInverseModelViewProjection;

#include <include\ImageSpaceIntersection.h>

in vec2 Vertex;
out vec4 LightColor;

vec3 sampleRefractivePosition(vec2 texCoords, sampler2D depthmap)
{
 float fSampledDepth = 2.0 * texture(depthmap, texCoords).x - 1.0;
 vec4 vWorldSpaceVertex = mInverseModelViewProjection * vec4(2.0 * texCoords - vec2(1.0), fSampledDepth, 1.0);
 return vWorldSpaceVertex.xyz / vWorldSpaceVertex.w;
}

void main()
{
 LightColor = vec4(1.0);

 if (texture(refractive_depth, Vertex).x == 1.0) 
 {
   gl_Position = vec4(2.0 * Vertex - vec2(1.0), 0.0, 1.0);
   return;
 }

 vec4 vSampledNormal = texture(refractive_normals, Vertex);
 if (vSampledNormal.a == 1.0) 
 {
   gl_Position = vec4(2.0 * Vertex - vec2(1.0), 0.0, 1.0);
   return;
 }

 vec3 vRefractivePosition = sampleRefractivePosition(Vertex, refractive_depth);
 vec3 vNormal = 2.0 * vSampledNormal.xyz - vec3(1.0); 
 vec3 vLightVector = normalize(vRefractivePosition - vCamera);
 vLightVector = refract(vLightVector, vNormal, vSampledNormal.a);

#ifdef DOUBLE_REFRACTION
 vec3 vFirstIntersectedVertex = estimateIntersection(vRefractivePosition, vLightVector,
				     mModelViewProjection, mInverseModelViewProjection, refractive_backface_depth);

 vec4 vProjectedIntersection = mModelViewProjection * vec4(vFirstIntersectedVertex, 1.0);
 vec2 vProjectedIntersectionTC = vec2(0.5) + 0.5 * vProjectedIntersection.xy / vProjectedIntersection.w;

 vec3 vBackfaceSampledNormal = vec3(1.0) - 2.0 * texture(refractive_backface_normals, vProjectedIntersectionTC).xyz; 
 vLightVector = refract(vLightVector, vBackfaceSampledNormal, 1.0 / vSampledNormal.a);

 if (dot(vLightVector, vLightVector) < 1.0e-5)
 {
  LightColor = vec4(0.0);
  gl_Position = vec4(Vertex, 0.0, 1.0);
  return;
 }

 vRefractivePosition = sampleRefractivePosition(vProjectedIntersectionTC, refractive_backface_depth);

 vec3 vIntersectedVertex = estimateIntersection(vRefractivePosition, vLightVector,
				mModelViewProjection, mInverseModelViewProjection, receiver_depth);

#else
 vec3 vIntersectedVertex = estimateIntersection(vRefractivePosition, vLightVector,
				mModelViewProjection, mInverseModelViewProjection, receiver_depth);
#endif

 gl_Position = mModelViewProjection * vec4(vIntersectedVertex, 1.0);
 LightColor.y = 0.5 + 0.5 * gl_Position.z / gl_Position.w, 128.0;
}