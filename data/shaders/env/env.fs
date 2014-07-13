#include <include\CookTorrance.h>
#include <include\Packing.h>

uniform sampler2D diffuse_texture;
uniform samplerCube cubemap_shadow;
uniform sampler2D caustic_texture;
uniform vec2 vTextureWrap = vec2(1.0);
uniform vec3 cLightColor;

in vec3 vLightWS;
in vec3 vViewWS;
in vec3 vNormalWS;
in vec2 TexCoord;
in vec4 LightProjectedVertex;

out vec4 FragColor;

#include "sampleShadow.h"
#include "sampleCaustic.h"

void main()
{
 vec3 vLightNormal = normalize(vLightWS);
 vec3 vViewNormal = normalize(vViewWS);
 vec3 vNormal = normalize(vNormalWS);

 vec2 vLight = CookTorrance(vNormal, vLightNormal, vViewNormal, 0.0325);

 float fCaustic = sampleCaustic(LightProjectedVertex, caustic_texture);

 float fReference = length(vLightWS);
 float fShadow = sampleShadow(fReference, -vLightNormal, cubemap_shadow);

 vec4 cColor = texture(diffuse_texture, TexCoord * vTextureWrap);

 vec4 cColored = cLightColor.xyzz * cColor;

 vec4 vAmbientColor = 0.2 * cColored;
 vec4 vDiffuseColor = cColored * vLight.x * fCaustic;
 vec4 vSpecularColor = cLightColor.xyzz * vLight.y;
 
 FragColor = vAmbientColor + fShadow * (vDiffuseColor + vSpecularColor);
}