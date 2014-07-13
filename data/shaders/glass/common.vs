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
out vec4 vProjectedVertex;
out vec4 vVertexWS;

void main()
{
 vVertexWS = mTransform * Vertex;

 vNormalWS = mat3(mTransform) * Normal;
 vLightWS = vPrimaryLight - vVertexWS.xyz;
 vViewWS = vCamera - vVertexWS.xyz;

 vProjectedVertex = mModelViewProjection * vVertexWS;
 gl_Position = vProjectedVertex;
}