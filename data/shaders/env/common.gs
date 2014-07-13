layout(triangles) in;
layout(triangle_strip, max_vertices = 18) out;

uniform mat4 mModelViewProjection[6];

in vec3 gs_vLightWS[];
in vec3 gs_vViewWS[];
in vec3 gs_vNormalWS[];
in vec2 gs_TexCoord[];
in vec4 gs_LightProjectedVertex[];

out vec3 vLightWS;
out vec3 vViewWS;
out vec3 vNormalWS;
out vec2 TexCoord;
out vec4 LightProjectedVertex;

void main()
{
 for (int layer = 0; layer < 6; layer++)
 {
  gl_Layer = layer;

  vViewWS   = gs_vViewWS[0];
  vLightWS  = gs_vLightWS[0];
  vNormalWS = gs_vNormalWS[0];
  TexCoord = gs_TexCoord[0];
  LightProjectedVertex = gs_LightProjectedVertex[0];
  gl_Position = mModelViewProjection[layer] * gl_in[0].gl_Position;
  EmitVertex();

  vViewWS   = gs_vViewWS[1];
  vLightWS  = gs_vLightWS[1];
  vNormalWS = gs_vNormalWS[1];
  TexCoord =  gs_TexCoord[1];
  LightProjectedVertex = gs_LightProjectedVertex[1];
  gl_Position = mModelViewProjection[layer] * gl_in[1].gl_Position;
  EmitVertex();

  vViewWS   = gs_vViewWS[2];
  vLightWS  = gs_vLightWS[2];
  vNormalWS = gs_vNormalWS[2];
  TexCoord =  gs_TexCoord[2];
  LightProjectedVertex = gs_LightProjectedVertex[2];
  gl_Position = mModelViewProjection[layer] * gl_in[2].gl_Position;
  EmitVertex();

  EndPrimitive();
 }

}
