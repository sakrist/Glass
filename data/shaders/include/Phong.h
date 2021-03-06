vec2 Phong(vec3 _normal, vec3 _light, vec3 _view, float roughness_val)
{
 float Rs = 0.0;
 float NdotL = max( dot( _normal, _light ), 0.0 );
 
 if (roughness_val > 0.0)
  {
   vec3 vReflected = reflect(-_light, _normal);
   float VdotR     = max(0.0, dot(vReflected, _view));
   Rs              = pow( VdotR, 7.5 / roughness_val );
  }
 return vec2( NdotL, Rs );
}
