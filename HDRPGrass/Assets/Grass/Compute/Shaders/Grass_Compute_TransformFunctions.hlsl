#ifndef GRASS_COMPUTE_TRANSFORMFUNCTIONS
#define GRASS_COMPUTE_TRANSFORMFUNCTIONS

// note: this exists because when using drawprocedural, lots of necessary stuff isnt set up properly, such as local to world matrices etc. 
// so i set them manually and then use these replacement functions, which have separate defines for whether im drawing procedurally or via a mesh renderer
// most of them are basically copied from unity's shader library

#include "Grass_Compute_Properties.hlsl"

// float4x4 _ObjectToWorld;
// float4x4 _WorldToObject;
// float3 _GrassWorldSpaceCameraPos

// returns a matrix which scales relative to a given point.
// source: https://studylib.net/doc/5892312/scaling-relative-to-a-fixed-point-using-matrix-using-the
float4x4 GetRelativeScaleMatrix(float3 origin, float3 scale)
{
    float4x4 relativeScaleMatrix = { { scale.x, 0.0, 0.0, (1 - scale.x) * origin.x }, { 0.0, scale.y, 0.0, (1 - scale.y) * origin.y }, { 0.0, 0.0, scale.z, (1 - scale.z) * origin.z }, { 0.0, 0.0, 0.0, 1.0 } };
    return relativeScaleMatrix;
}

// returns a matrix which reverses scale relative to a given point.
// source: https://studylib.net/doc/5892312/scaling-relative-to-a-fixed-point-using-matrix-using-the
float4x4 GetInverseRelativeScaleMatrix(float3 origin, float3 scale)
{
    return transpose(GetRelativeScaleMatrix(origin, 1 / scale));
}

float3 ExtractScale(float4x4 mat)
{
    return float3(length(mat._m00_m10_m20), length(mat._m01_m11_m21), length(mat._m02_m12_m22));
}

float3 InverseScaleRelative(float3 position, float3 origin, float3 scale)
{
    return mul(float4(position, 1), GetInverseRelativeScaleMatrix(origin, scale)).xyz;
}

float3 ScaleRelative(float3 position, float3 origin, float3 scale)
{
    return mul(float4(position, 1), GetRelativeScaleMatrix(origin, scale)).xyz;
}

#define UNITY_MATRIX_M     ApplyCameraTranslationToMatrix(_ObjectToWorld)

float4x4 Grass_GetObjectToWorldMatrix()
{
#ifdef FROM_PROCEDURAL
    return UNITY_MATRIX_M;
#else
    return GetObjectToWorldMatrix();
#endif
}

float3 Grass_TransformObjectToWorld(float3 positionOS)
{
    return mul(Grass_GetObjectToWorldMatrix(), float4(positionOS, 1.0)).xyz;
}

#endif // GRASS_COMPUTE_TRANSFORMFUNCTIONS