#ifndef GRASS_COMPUTE_COMPUTESTRUCTS
#define GRASS_COMPUTE_COMPUTESTRUCTS

#include "Grass_Compute_CommonStructs.hlsl"

// contains information about the original mesh, which just provides vertex data
struct SourceMeshVertexData
{
    float3 positionOS;
    float3 normalOS;
    float3 tangentOS;
    float4 color;
    float2 uv;
};

GrassBladeTriangle GenerateTriangleData(float3 vertex0, float3 vertex1, float3 vertex2, float2 uv0, float2 uv1, float2 uv2, GrassBladeSpaceData space)
{
    GrassBladeVertex point0;
    point0.positionOS = vertex0;
    point0.uv = uv0;
    
    GrassBladeVertex point1;
    point1.positionOS = vertex1;
    point1.uv = uv1;
    
    GrassBladeVertex point2;
    point2.positionOS = vertex2;
    point2.uv = uv2;
    
    GrassBladeTriangle result;
    result.points[0] = point0;
    result.points[1] = point1;
    result.points[2] = point2;
    
    result.space = space;
    
    return result;
}

// information about the shape of the grass blades, only one is passed in per compute shader
struct GrassBladeProperties
{
    float width;
    float widthVariance;
    float height;
    float heightVariance;
    float rotationRangeX;
    float rotationRangeY;
    float tipOffsetZ;
    float curvature;
};

struct IndirectArgs
{
    uint verticesPerInstance;
    uint instances;
    uint startVertexIndex;
    uint startInstanceIndex;
};

#endif // GRASS_COMPUTE_COMPUTESTRUCTS