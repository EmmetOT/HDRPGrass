//#include "GrassShaderStructs.hlsl"
#include "../../Grass_Common_GBuffer.hlsl"

void GrassFragment(PackedVaryingsToPS packedInput,
            OUTPUT_GBUFFER( outGBuffer)
            #ifdef _DEPTHOFFSET_ON
            , out float outputDepth : SV_Depth
            #endif
            )
{
	// force this to 'none' so unity doesnt try to do any normal flipping
	_DoubleSidedConstants = float4(1, 1, 1, 1);

    UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(packedInput);
FragInputs input = UnpackVaryingsMeshToFragInputs(packedInput.vmesh);

    // input.positionSS is SV_Position
PositionInputs posInput = GetPositionInput(input.positionSS.xy, _ScreenSize.zw, input.positionSS.z, input.positionSS.w, input.positionRWS);

#ifdef VARYINGS_NEED_POSITION_WS
    float3 V = GetWorldSpaceNormalizeViewDir(input.positionRWS);
#else
    // Unused
float3 V = float3(1.0, 1.0, 1.0); // Avoid the division by 0
#endif

    SurfaceData surfaceData;
    BuiltinData builtinData;
    GetSurfaceAndBuiltinData(input, V, posInput, surfaceData, builtinData);

    float3 color = lerp(_GrassBottomColour, _GrassTopColour, input.texCoord0.y);
	surfaceData.baseColor = color;

    builtinData.opacity = 0;

    /*GRASS_*/ENCODE_INTO_GBUFFER(surfaceData, builtinData, posInput.positionSS, outGBuffer);

#ifdef _DEPTHOFFSET_ON
    outputDepth = posInput.deviceDepth;
#endif
}
