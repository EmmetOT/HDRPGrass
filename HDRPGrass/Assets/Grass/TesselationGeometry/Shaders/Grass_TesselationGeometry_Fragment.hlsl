#include "../../Grass_Common_GBuffer.hlsl"

void GrassFragment(
            PackedVaryingsToPS packedInput,
            OUTPUT_GBUFFER(outGBuffer)
            #ifdef _DEPTHOFFSET_ON
            , out float outputDepth : SV_Depth
            #endif
            )
{
	// force this to 'none' so unity doesnt try to do any normal flipping
	_DoubleSidedConstants = float4(1, 1, 1, 1);

    FragInputs input = UnpackVaryingsMeshToFragInputs(packedInput.vmesh);
	
    // input.positionSS is SV_Position
    PositionInputs posInput = GetPositionInput(input.positionSS.xy, _ScreenSize.zw, input.positionSS.z, input.positionSS.w, input.positionRWS);

    float3 V = GetWorldSpaceNormalizeViewDir(input.positionRWS);

    SurfaceData surfaceData;
    BuiltinData builtinData;
    GetSurfaceAndBuiltinData(input, V, posInput, surfaceData, builtinData);
	
#ifdef NORMAL_TYPE_OVERRIDE
	surfaceData.normalWS = mul(normalize(_AbsoluteNormal).xyz, input.tangentToWorld).xyz;
#endif

#ifdef VISUALIZE_WIND

	float3 absolutePos = GetAbsolutePositionWS(input.positionRWS);
	float2 windUV = absolutePos.xz * _WindDistortionMap_ST.xy + _WindDistortionMap_ST.zw + _WindFrequency * _Time.y;
	half2 windSample = (tex2Dlod(_WindDistortionMap, float4(windUV, 0, 0)).xy);

	surfaceData.baseColor = float3(windSample, 0);

#elif VISUALIZE_DISPLACEMENT

	float3 absolutePos = GetAbsolutePositionWS(input.positionRWS);
	half3 sphereDisp = half3(0, 0, 0);
	for	(int i = 0; i < _GrassDisplacementSpheresBufferCount; i++)
	{
		GrassDisplacement displacementData = _GrassDisplacementSpheresBuffer[i];
		float3 position = _GrassDisplacementSpheresBuffer[i].position;

		float3 distance = length(position - absolutePos);
		float3 circle = 1 - saturate(distance * displacementData.inverseRadius);

		sphereDisp += (absolutePos - position) * circle;
		sphereDisp = clamp(sphereDisp.xyz * displacementData.power, -0.8, 0.8);
	}

	surfaceData.baseColor = sphereDisp;

#elif VISUALIZE_LODS

	int lod = GetLOD(GetAbsolutePositionWS(input.positionRWS));

	half3 col = half3(0, 0, 0);
	col = lerp(col, half3(1, 0, 0), lod == 0);
	col = lerp(col, half3(0, 1, 0), lod == 1);
	col = lerp(col, half3(0, 0, 1), lod == 2);

	surfaceData.baseColor = col;
#else
	
	#ifdef VARYINGS_NEED_TEXCOORD1
		float2 grassTextureUV = packedInput.vmesh.interpolators3.zw * _FieldTexture_ST.xy + _FieldTexture_ST.zw;
		surfaceData.baseColor = tex2Dlod(_FieldTexture, float4(grassTextureUV, 0, 0)).rgb;
	#else
		surfaceData.baseColor = half3(1, 1, 1);
	#endif

    float3 grassBladeTex = tex2Dlod(_BladeTexture, float4(input.texCoord0.xy, 0, 0)).rgb;

	surfaceData.baseColor *= grassBladeTex * lerp(_GrassBottomColour, _GrassTopColour, input.texCoord0.y).rgb;
	//surfaceData.baseColor = float3(1, 0, 0);

    builtinData.opacity = 0.5;

#endif

    /*GRASS_*/ENCODE_INTO_GBUFFER(surfaceData, builtinData, posInput.positionSS, outGBuffer);

#ifdef _DEPTHOFFSET_ON
    outputDepth = posInput.deviceDepth;
#endif
}