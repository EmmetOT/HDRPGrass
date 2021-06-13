#include "../../Grass_Common.hlsl"

//uniform StructuredBuffer<GrassDisplacement> _GrassDisplacementSpheresBuffer : register(t1);
//uniform int _GrassDisplacementSpheresBufferCount;

//#define MAX_GRASS_DISPLACEMENT_SPHERES 10

//// Simple noise function, sourced from http://answers.unity.com/answers/624136/view.html
//// Extended discussion on this function can be found at the following link:
//// https://forum.unity.com/threads/am-i-over-complicating-this-random-function.454887/#post-2949326
//// Returns a number in the 0...1 range.
//float rand(float3 co)
//{
//	// smooths out floating point weirdness
//	co = round(co * 100);

//	return frac(sin(dot(co.xyz, float3(12.9898, 78.233, 53.539))) * 43758.5453);
//}

//// Construct a rotation matrix that rotates around the provided axis, sourced from:
//// https://gist.github.com/keijiro/ee439d5e7388f3aafc5296005c8c3f33
//float3x3 AngleAxis3x3(float angle, float3 axis)
//{
//	float c, s;
//	sincos(angle, s, c);

//	float t = 1 - c;
//	float x = axis.x;
//	float y = axis.y;
//	float z = axis.z;

//	return float3x3(
//		t * x * x + c, t * x * y - s * z, t * x * z + s * y,
//		t * x * y + s * z, t * y * y + c, t * y * z - s * x,
//		t * x * z - s * y, t * y * z + s * x, t * z * z + c
//		);
//}

void SetPosition(inout PackedVaryingsToPS ps, float3 offset)
{
#ifdef VARYINGS_NEED_POSITION_WS
	ps.vmesh.interpolators0 = offset;
#endif
    ps.vmesh.positionCS = TransformWorldToHClip(ps.vmesh.interpolators0);
}

void SetNormal(inout PackedVaryingsToPS ps, float3 normal)
{
#ifdef VARYINGS_NEED_TANGENT_TO_WORLD
	ps.vmesh.interpolators1 = normal;
#endif
}

void SetUV0(inout PackedVaryingsToPS ps, float2 uv)
{
#ifdef VARYINGS_NEED_TEXCOORD0
	ps.vmesh.interpolators3.xy = uv;
#endif
}

void SetUV1(inout PackedVaryingsToPS ps, float2 uv)
{
#ifdef VARYINGS_NEED_TEXCOORD1
	ps.vmesh.interpolators3.zw = uv;
#endif
}

float2 GetUV0(inout PackedVaryingsToPS ps)
{
#ifdef VARYINGS_NEED_TEXCOORD0
	return ps.vmesh.interpolators3.xy;
#else
    return float2(0, 0);
#endif
}

float2 GetUV1(inout PackedVaryingsToPS ps)
{
#ifdef VARYINGS_NEED_TEXCOORD1
	return ps.vmesh.interpolators3.zw;
#else
    return float2(0, 0);
#endif
}

float2 GetUV2(inout PackedVaryingsToPS ps)
{
#ifdef VARYINGS_NEED_TEXCOORD2
	return ps.vmesh.interpolators4.xy;
#else
    return float2(0, 0);
#endif
}

float2 GetUV3(inout PackedVaryingsToPS ps)
{
#ifdef VARYINGS_NEED_TEXCOORD3
	return ps.vmesh.interpolators4.zw;
#else
    return float2(0, 0);
#endif
}

float4 GetColor(inout PackedVaryingsToPS ps)
{
#ifdef VARYINGS_NEED_COLOR
	return ps.vmesh.interpolators5;
#else
    return float4(0, 0, 0, 0);
#endif
}

float3 GetPosition(inout PackedVaryingsToPS ps)
{
#ifdef VARYINGS_NEED_POSITION_WS
	return ps.vmesh.interpolators0;
#else
    return float3(0, 0, 0);
#endif
}

float3 GetNormal(inout PackedVaryingsToPS ps)
{
#ifdef VARYINGS_NEED_TANGENT_TO_WORLD
	return ps.vmesh.interpolators1;
#else
    return float3(0, 0, 0);
#endif
}

float4 GetTangent(inout PackedVaryingsToPS ps)
{
#ifdef VARYINGS_NEED_TANGENT_TO_WORLD
	return ps.vmesh.interpolators2;
#else
    return float4(0, 0, 0, 0);
#endif
}

int GetLOD(float3 absoluteWorldPosition)
{
#ifndef LODS_ENABLED
	return 0;
#else

	float3 disp = absoluteWorldPosition - _WorldSpaceCameraPos;
	float sqrDist = dot(disp, disp);

	int result = 3;
	result = lerp(result, 2, sqrDist < _GrassLODSqrDistances[2]);
	result = lerp(result, 1, sqrDist < _GrassLODSqrDistances[1]);
	result = lerp(result, 0, sqrDist < _GrassLODSqrDistances[0]);

	return result;
#endif
}