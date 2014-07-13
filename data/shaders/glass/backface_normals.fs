uniform float indexOfRefraction;

in vec3 vNormalWS;

out vec4 FragColor;

void main()
{
 vec3 vNormal = normalize(vNormalWS);
 FragColor = vec4(vec3(0.5) + 0.5 * vNormal, indexOfRefraction);
}