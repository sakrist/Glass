#include <include\CookTorrance.h>
#include <include\Packing.h>

uniform sampler2D diffuse_texture;
uniform samplerCube cubemap_shadow;
uniform sampler2D caustic_texture;

uniform vec2 vTextureWrap = vec2(16.0);
uniform vec3 cLightColor;

in vec3 vLightWS;
in vec3 vNormalWS;
in vec2 TexCoord;
in vec4 LightProjectedVertex;

out vec4 FragColor;

#include "sampleShadow.h"
#include "sampleCaustic.h"

void main()
{
 vec3 vLightNormal = normalize(vLightWS);
 vec3 vNormal = normalize(vNormalWS);

 float fReference = length(vLightWS);
 float fShadow = sampleShadow(fReference, -vLightNormal, cubemap_shadow);

 float fCaustic = sampleCaustic(LightProjectedVertex, caustic_texture);

 float fDistanceAttenuation = exp(-0.0001 * fReference);
 fDistanceAttenuation = pow(fDistanceAttenuation, 8.0);

 float vLight = dot(vNormal, vLightNormal);
 vec4 cColor = texture(diffuse_texture, TexCoord * vTextureWrap);

 vec4 cColored = cLightColor.xyzz * cColor;
 vec4 vAmbientColor = 0.2 * cColored;
 vec4 vDiffuseColor = cColored * fDistanceAttenuation * fCaustic;

 FragColor = vAmbientColor + fShadow * vDiffuseColor;
}