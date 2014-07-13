#include <include\CookTorrance.h>

uniform sampler2D diffuse_texture;
uniform vec2 vTextureWrap = vec2(16.0);
uniform vec3 cLightColor;

in vec3 vLightWS;
in vec3 vViewWS;
in vec3 vNormalWS;
in vec2 TexCoord;

out vec4 FragColor;

void main()
{
 FragColor = vec4(cLightColor, 1.0);
}