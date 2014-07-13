#ifndef WITH_GS
uniform mat4 mModelViewProjection;
#endif

uniform vec3 vCamera;
uniform vec3 vPrimaryLight;
uniform mat4 mLightProjectionMatrix;
uniform mat4 mTransform;

in vec4 Vertex;
in vec3 Normal;
in vec2 TexCoord0;
    
#ifdef WITH_GS
 out vec3 gs_vLightWS;
 out vec3 gs_vViewWS;
 out vec3 gs_vNormalWS;
 out vec2 gs_TexCoord;
 out vec4 gs_LightProjectedVertex;
#else
 out vec3 vLightWS;
 out vec3 vViewWS;
 out vec3 vNormalWS;
 out vec2 TexCoord;
 out vec4 LightProjectedVertex;
#endif

void main()
{
 vec4 vTransformedVertex = mTransform * Vertex;

#ifdef WITH_GS

 gs_TexCoord = TexCoord0;
 gs_vNormalWS = mat3(mTransform) * Normal;
 gs_vLightWS = vPrimaryLight - vTransformedVertex.xyz;
 gs_vViewWS = vCamera - vTransformedVertex.xyz;
 gs_LightProjectedVertex = mLightProjectionMatrix * vTransformedVertex;
 gl_Position = vTransformedVertex;

#else

 TexCoord = TexCoord0;
 vNormalWS = mat3(mTransform) * Normal;
 vLightWS = vPrimaryLight - vTransformedVertex.xyz;
 vViewWS = vCamera - vTransformedVertex.xyz;
 LightProjectedVertex = mLightProjectionMatrix * vTransformedVertex;
 gl_Position = mModelViewProjection * vTransformedVertex;

#endif
}