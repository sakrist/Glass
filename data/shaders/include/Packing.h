vec4 packFloat(float value)
{
 float depthInteger = floor(value);
 float depthFraction = fract(value);
 float depthUpper = floor(depthInteger / 256.0f);
 float depthLower = depthInteger - (depthUpper * 256.0f);

 return vec4(depthUpper / 256.0f, depthLower / 256.0f, depthFraction, 1.0f);
}

float unpackFloat(vec4 value)
{
 return value.r * 256.0 * 256.0 + value.g * 256.0 + value.b;
}