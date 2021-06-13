//#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"

#include "../../Grass_Common.hlsl"
//#include "GrassShaderStructs.hlsl"
#include "Grass_Compute_TransformFunctions.hlsl"
#include "Grass_Compute_Properties.hlsl"

float3 ApplyWindAndDisplacementOS(float3 origin, float3 position, float height)
{
#ifdef GRASS_BLADE_SCALING
    // this line removes the scaling from the actual grass blades
    position = InverseScaleRelative(position, origin, ExtractScale(Grass_GetObjectToWorldMatrix()));
#endif
    
    // This return the camera relative position (if enabled)
    float3 absoluteVertexPos = GetAbsolutePositionWS(Grass_TransformObjectToWorld(position));
    float3 absolutePos = GetAbsolutePositionWS(Grass_TransformObjectToWorld(origin));
    
	//////////////// DISPLACEMENT SPHERES
    
    float3 totalSphereDisp = float3(0, 0, 0);
//#ifdef APPLY_DISPLACEMENT
    for (int i = 0; i < _GrassDisplacementSpheresBufferCount; i++)
    {
        float3 sphereDisp = float3(0, 0, 0);

        GrassDisplacement displacementData = _GrassDisplacementSpheresBuffer[i];
        float3 displacerPos = displacementData.position;

        float distance = length(displacerPos - absolutePos);
        float3 circle = 1 - saturate(distance * displacementData.inverseRadius);

        sphereDisp += (absolutePos - displacerPos) * circle;
        sphereDisp = clamp(sphereDisp.xyz * displacementData.power, -0.8, 0.8);

        totalSphereDisp += sphereDisp;
    }
//#endif
    
    absoluteVertexPos += totalSphereDisp * height;
    
	////////////////
    
	//////////////// WIND
    
    float2 windUV = absolutePos.xz * _WindDistortionMap_ST.xy + _WindDistortionMap_ST.zw + _WindFrequency * _Time.y;
    float2 windSample = (tex2Dlod(_WindDistortionMap, float4(windUV, 0, 0)).rg * 2 - 1) * max(0.000001, abs(_WindStrength));
    float3 wind = normalize(float3(windSample.x, windSample.y, 0));
    
    absoluteVertexPos += float3(windSample.x, 0, windSample.y) * height;
	////////////////
    
    return absoluteVertexPos;
}

#ifdef FROM_PROCEDURAL
#include "Grass_Compute_VertexProcedural.hlsl"
#else
#include "Grass_Compute_VertexMesh.hlsl"
#endif