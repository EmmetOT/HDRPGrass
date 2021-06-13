#ifndef GRASS_COMMON
#define GRASS_COMMON

#define EPSILON 0.00000001
#define RANDOM_SMOOTHING 4.5

#include "Grass_CommonStructs.hlsl"

uniform StructuredBuffer<GrassDisplacement> _GrassDisplacementSpheresBuffer : register(t1);
uniform int _GrassDisplacementSpheresBufferCount;

#define MAX_GRASS_DISPLACEMENT_SPHERES 10

#ifndef UNITY_COMMON_INCLUDED

#define PI 3.1415926

float DegToRad(float deg)
{
    return deg * (PI / 180.0);
}

float RadToDeg(float rad)
{
    return rad * (180.0 / PI);
}

#endif

// Construct a rotation matrix that rotates around the provided axis, sourced from:
// https://gist.github.com/keijiro/ee439d5e7388f3aafc5296005c8c3f33
float3x3 AngleAxis3x3(float angle, float3 axis)
{
    float c, s;
    sincos(angle, s, c);

    float t = 1 - c;
    float x = axis.x;
    float y = axis.y;
    float z = axis.z;

    return float3x3(
		t * x * x + c, t * x * y - s * z, t * x * z + s * y,
		t * x * y + s * z, t * y * y + c, t * y * z - s * x,
		t * x * z - s * y, t * y * z + s * x, t * z * z + c
		);
}

//float3x3 AngleAxisDerp(float3 source, float3 target, float3 axis)
//{
//    axis = abs(axis);
//    target -= source;

//    float3 projectedTarget = target - dot(target, axis) * axis;
//    float3 forward = normalize(projectedTarget);
    
//    float3x3 x = AngleAxis3x3(-atan2(forward.y, forward.z), axis);
//    float3x3 y = AngleAxis3x3(atan2(forward.x, forward.z), axis);
//    float3x3 z = AngleAxis3x3(-atan2(forward.x, forward.y), axis);
    
//    return y;
//}

//float GetAngleInvariant(float3 cameraPos, float3 origin, float3 axis)
//{
//    float3 transformedCameraPos = cameraPos - dot(cameraPos, axis) * axis;
//    float3 transformedPos = origin - dot(origin, axis) * axis;
//    float3 dir = normalize(transformedCameraPos - transformedPos);
//    return atan2(dir.z, dir.x);
//}

//float3x3 AxisBillboard(float3 upAxis, float3 viewDirection)
//{
//    float3 rightAxis = normalize(cross(upAxis, viewDirection));
//    float3 forwardAxis = cross(rightAxis, upAxis);

//    float3x3 result;
//    result[0].xyz = rightAxis;
//    result[1].xyz = upAxis;
//    result[2].xyz = forwardAxis;
    
//    return result;
//}

//// Returns a 'pseudo-LookAt' matrix which only rotates around the given axis.
//float3x3 FlatLookAt(float3 source, float3 target, float3 axis)
//{
//    target -= source;

//    float3 projectedTarget = target - dot(target, axis) * axis;
    
//    float3 forward = normalize(projectedTarget);
//    float3 right = cross(axis, forward);
//    float3 up = cross(forward, right);
    
//    float3x3 result;
//    result[0].xyz = right;
//    result[1].xyz = up;
//    result[2].xyz = forward;
    
//    return result;
//}

float SignedAngle(float3 from, float3 to, float3 axis)
{
    float unsignedAngle = acos(dot(from, to));

    float cross_x = from.y * to.z - from.z * to.y;
    float cross_y = from.z * to.x - from.x * to.z;
    float cross_z = from.x * to.y - from.y * to.x;
    float signOfAngle = sign(axis.x * cross_x + axis.y * cross_y + axis.z * cross_z);
    return unsignedAngle * signOfAngle;
}

float3 ProjectOnPlane(float3 vec, float3 normal, float3 planePos)
{
    return vec - normal * dot(vec, normal) + dot(planePos, normal) * normal;
}

float GetProjectedAngle(float3 pos, float3 cameraPos, float3 up, float3 right)
{
    float3 projectedPoint = ProjectOnPlane(cameraPos, up, pos);

    float3 dir = normalize(projectedPoint - pos);

    return SignedAngle(right, dir, up);
}


float randSin(float p)
{
    p = sin(p * 0.1031f);
    p *= p + 33.33f;
    p *= p + p;
    return frac(p);
}

// Simple noise function, sourced from http://answers.unity.com/answers/624136/view.html
// Extended discussion on this function can be found at the following link:
// https://forum.unity.com/threads/am-i-over-complicating-this-random-function.454887/#post-2949326
// Returns a number in the 0...1 range.
float rand(float3 co)
{
    return frac(sin(dot(co.xyz, float3(12.9898, 78.233, 53.539))) * 43758.5453);
}

float rand(float co)
{
    return rand(float3(co * 3832.33, co * 11.8322, co * 0.38723));
}

float smooth(float val)
{
    return (int) (val * RANDOM_SMOOTHING);

}

float smoothRand(float3 co)
{
    co = float3(smooth(co.x), smooth(co.y), smooth(co.z));
    return frac(sin(dot(co.xyz, float3(12.9898, 78.233, 53.539))) * 43758.5453);
}

float smoothRand(float co)
{
    co = smooth(co);
    return rand(float3(co * 3832.33, co * 11.8322, co * 0.38723));
}


int when_eq(float x, float y)
{
    return 1 - abs(sign(x - y));
}

int when_neq(float x, float y)
{
    return abs(sign(x - y));
}

int when_gt(float x, float y)
{
    return max(sign(x - y), 0);
}

int when_lt(float x, float y)
{
    return max(sign(y - x), 0);
}

int when_ge(float x, float y)
{
    return 1 - when_lt(x, y);
}

int when_le(float x, float y)
{
    return 1 - when_gt(x, y);
}

int and(int a, int b)
{
    return a * b;
}

int or(int a, int b)
{
    return min(a + b, 1);
}

int xor(int a, int b)
{
    return (a + b) % 2;
}

int not(int a)
{
    return 1 - a;
}

#endif // GRASS_COMMON