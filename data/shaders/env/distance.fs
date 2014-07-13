in vec3 vLightWS;
out vec4 FragColor;

#include <include\Packing.h>

void main()
{
 FragColor = packFloat( length(vLightWS) );
}