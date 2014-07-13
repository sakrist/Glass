#define Light CookTorrance
#define shininess 0.0325

uniform samplerCube environment_map;

#ifdef DOUBLE_REFRACTION
 uniform sampler2D backface_texture;
 uniform sampler2D backface_depth;
 uniform mat4 mModelViewProjection;
 uniform mat4 mModelViewProjectionInverse;
 uniform vec3 vCamera;
#endif

uniform vec3 cLightColor;
uniform float indexOfRefraction;

in vec3 vLightWS;
in vec3 vViewWS;
in vec3 vNormalWS;
in vec2 TexCoord;
in vec4 vProjectedVertex;
in vec4 vVertexWS;

out vec4 FragColor;

#include <include\Phong.h>
#include <include\CookTorrance.h>
#include <include\ImageSpaceIntersection.h>

float calculateFresnel(float VdotN)
{
 float value = 1.0 - VdotN;
 return value;
}

float calculateBackfaceFresnel(float VdotN)
{
 float value = min(1.0, VdotN + 0.2);
 value *= value;
 return value * value;
}

void main()
{
 vec3 vNormal = normalize(vNormalWS);
 vec3 vLightNormal = normalize(vLightWS);
 vec3 vViewNormal = normalize(vViewWS);

 float VdotN = max(0.0, dot(vViewNormal, vNormal));
 float fFresnel = calculateFresnel(VdotN);

 vec3 vReflected = reflect(-vViewNormal, vNormal);
 vec4 cReflection = texture(environment_map, vReflected);

 vec3 vRefracted = refract(-vViewNormal, vNormal, indexOfRefraction);

#ifdef DOUBLE_REFRACTION
 vec3 vBackfaceIntersection = estimateIntersection(vVertexWS.xyz, vRefracted,
				mModelViewProjection, mModelViewProjectionInverse, backface_depth);
 vec4 vProjectedBI = mModelViewProjection * vec4(vBackfaceIntersection, 1.0);
 vProjectedBI /= vProjectedBI.w;
 vec3 vBackfaceNormal = vec3(1.0) - 2.0 * texture(backface_texture, vec2(0.5) + 0.5 * vProjectedBI.xy).xyz;
 vBackfaceNormal = normalize(vBackfaceNormal);
 vec3 vBackfaceRefracted = refract(vRefracted, vBackfaceNormal.xyz, 1.0 / indexOfRefraction);
 if (dot(vBackfaceRefracted, vBackfaceRefracted) > 1.0e-5)
  vBackfaceRefracted = normalize(vBackfaceRefracted);
 vec3 vBackfaceReflected = reflect(vRefracted, vBackfaceNormal.xyz);
 float fBackfaceFresnel = calculateBackfaceFresnel( -dot(vBackfaceNormal.xyz, vBackfaceRefracted) );
 vec4 cBackfaceRefraction = texture(environment_map, vBackfaceRefracted);
 vec4 cBackfaceReflection = texture(environment_map, vBackfaceReflected);
 vec4 cBackfaceColor = mix(cBackfaceReflection, cBackfaceRefraction, fBackfaceFresnel);
#else
 vec4 cBackfaceColor = texture(environment_map, vRefracted);
#endif

 vec4 cColor = mix(cBackfaceColor, cReflection, fFresnel);
 vec2 vLight = Light(vNormal, vLightNormal, vViewNormal, shininess);
 vec4 vSpecularColor = cLightColor.xyzz * vLight.y;

 FragColor = cColor + vSpecularColor;
}