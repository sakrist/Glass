vec3 reproject(vec3 position, mat4 projection, mat4 inverseProjection, sampler2D depthmap)
{
 vec4 vProjected = projection * vec4(position, 1.0);
 vec2 texCoord = vProjected.xy / vProjected.w;
 float fSampledDepth = 2.0 * texture(depthmap, vec2(0.5) + 0.5 * texCoord).x - 1.0;
 vec4 vWorldSpaceVertex = inverseProjection * vec4(texCoord, fSampledDepth, 1.0);
 return vWorldSpaceVertex.xyz / vWorldSpaceVertex.w;
}

vec3 estimateIntersection(vec3 startPoint, vec3 ray, mat4 projection, 
				mat4 inverseProjection, sampler2D depthmap)
{
 return reproject(startPoint + ray * distance(startPoint, 
	reproject(startPoint + ray, projection, inverseProjection, depthmap) ),
				    projection, inverseProjection, depthmap);
}
