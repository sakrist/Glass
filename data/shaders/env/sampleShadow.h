float sampleShadow(float reference, vec3 direction, samplerCube distance_map)
{
 vec4 vSample = texture(distance_map, direction);
 float fSampledDistance = unpackFloat(vSample) + 1.0;
 return (fSampledDistance < reference) ? 0.0 : 1.0;
}