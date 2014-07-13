float sampleCaustic(vec4 texCoords, sampler2D causticmap)
{
 return (texCoords.w > 0.0) ? 
   sqrt(texture(caustic_texture, vec2(0.5) + 0.5 * texCoords.xy / texCoords.w).x) : 1.0;
}