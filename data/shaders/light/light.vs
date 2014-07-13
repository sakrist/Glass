uniform mat4 mModelViewProjection;
uniform vec3 vCamera;
uniform vec3 vPrimaryLight;
uniform mat4 mLightProjectionMatrix;
uniform mat4 mTransform;

in vec4 Vertex;
in vec3 Normal;
in vec2 TexCoord0;
    
out vec3 vLightWS;
out vec3 vViewWS;
out vec3 vNormalWS;
out vec2 TexCoord;

void main()
{
 vec4 vTransformedVertex = mTransform * Vertex;

 TexCoord = TexCoord0;
 vNormalWS = mat3(mTransform) * Normal;
 vLightWS = vPrimaryLight - vTransformedVertex.xyz;
 vViewWS = vCamera - vTransformedVertex.xyz;

 gl_Position = mModelViewProjection * vTransformedVertex;
}