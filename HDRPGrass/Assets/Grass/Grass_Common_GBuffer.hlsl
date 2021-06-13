
#ifndef GRASS_COMMON_GBUFFER
#define GRASS_COMMON_GBUFFER

// Note:
// For standard we have chose to always encode fresnel0. Even when we use metal/baseColor parametrization. This avoid
// compiler optimization problem that was using VGPR to deal with the various combination of metal non metal.

// For SSS, we move diffusionProfile(4) / subsurfaceMask(4) in GBuffer0.a so the forward SSS code only need to write into one RT
// and the SSS postprocess only need to read one RT
// We duplicate diffusionProfile / subsurfaceMask in GBuffer2.b so the compiler don't need to read the GBuffer0 before PostEvaluateBSDF
// The lighting code have been adapted to only apply diffuseColor at the end.
// This save VGPR as we don' need to keep the GBuffer0 value in register.

// The layout is also design to only require one RT for the material classification. All the material feature flags are deduced from GBuffer2.

// Encode SurfaceData (BSDF parameters) into GBuffer
// Must be in sync with RT declared in HDRenderPipeline.cs ::Rebuild
void Grass_EncodeIntoGBuffer( SurfaceData surfaceData
                        , BuiltinData builtinData
                        , uint2 positionSS
                        , out GBufferType0 outGBuffer0
                        , out GBufferType1 outGBuffer1
                        , out GBufferType2 outGBuffer2
                        , out GBufferType3 outGBuffer3
#if GBUFFERMATERIAL_COUNT > 4
                        , out GBufferType4 outGBuffer4
#endif
#if GBUFFERMATERIAL_COUNT > 5
                        , out GBufferType5 outGBuffer5
#endif
                        )
{
    // This encode normalWS and PerceptualSmoothness into GBuffer1
    EncodeIntoNormalBuffer(ConvertSurfaceDataToNormalData(surfaceData), positionSS, outGBuffer1);
    
    // colour, the important bit :O
    outGBuffer0 = float4(surfaceData.baseColor, 0.0); //surfaceData.specularOcclusion);
    
    // fresnel
    outGBuffer2 = 0.0;
    
    // RT3 - 11f:11f:10f
    // In deferred we encode emissive color with bakeDiffuseLighting. We don't have the room to store emissiveColor.
    // It mean that any futher process that affect bakeDiffuseLighting will also affect emissiveColor, like SSAO for example.
    outGBuffer3 = float4(builtinData.bakeDiffuseLighting * surfaceData.ambientOcclusion + builtinData.emissiveColor, 0.0);

    // Pre-expose lighting buffer
    outGBuffer3 *= GetCurrentExposureMultiplier();

#ifdef LIGHT_LAYERS
    // Note: we need to mask out only 8bits of the layer mask before encoding it as otherwise any value > 255 will map to all layers active
    OUT_GBUFFER_LIGHT_LAYERS = float4(0.0, 0.0, 0.0, (builtinData.renderingLayers & 0x000000FF) / 255.0);
#endif

#ifdef SHADOWS_SHADOWMASK
    OUT_GBUFFER_SHADOWMASK = BUILTIN_DATA_SHADOW_MASK;
#endif
}

#ifdef GBUFFERMATERIAL_COUNT

#if GBUFFERMATERIAL_COUNT == 2

//#define OUTPUT_GBUFFER(NAME)                            \
//        out GBufferType0 MERGE_NAME(NAME, 0) : SV_Target0,    \
//        out GBufferType1 MERGE_NAME(NAME, 1) : SV_Target1

#define GRASS_ENCODE_INTO_GBUFFER(SURFACE_DATA, BUILTIN_DATA, UNPOSITIONSS, NAME) Grass_EncodeIntoGBuffer(SURFACE_DATA, BUILTIN_DATA, UNPOSITIONSS, MERGE_NAME(NAME,0), MERGE_NAME(NAME,1))

#elif GBUFFERMATERIAL_COUNT == 3

//#define OUTPUT_GBUFFER(NAME)                            \
//        out GBufferType0 MERGE_NAME(NAME, 0) : SV_Target0,    \
//        out GBufferType1 MERGE_NAME(NAME, 1) : SV_Target1,    \
//        out GBufferType2 MERGE_NAME(NAME, 2) : SV_Target2

#define GRASS_ENCODE_INTO_GBUFFER(SURFACE_DATA, BUILTIN_DATA, UNPOSITIONSS, NAME) Grass_EncodeIntoGBuffer(SURFACE_DATA, BUILTIN_DATA, UNPOSITIONSS, MERGE_NAME(NAME,0), MERGE_NAME(NAME,1), MERGE_NAME(NAME,2))

#elif GBUFFERMATERIAL_COUNT == 4

//#define OUTPUT_GBUFFER(NAME)                            \
//        out GBufferType0 MERGE_NAME(NAME, 0) : SV_Target0,    \
//        out GBufferType1 MERGE_NAME(NAME, 1) : SV_Target1,    \
//        out GBufferType2 MERGE_NAME(NAME, 2) : SV_Target2,    \
//        out GBufferType3 MERGE_NAME(NAME, 3) : SV_Target3

#define GRASS_ENCODE_INTO_GBUFFER(SURFACE_DATA, BUILTIN_DATA, UNPOSITIONSS, NAME) Grass_EncodeIntoGBuffer(SURFACE_DATA, BUILTIN_DATA, UNPOSITIONSS, MERGE_NAME(NAME, 0), MERGE_NAME(NAME, 1), MERGE_NAME(NAME, 2), MERGE_NAME(NAME, 3))

#elif GBUFFERMATERIAL_COUNT == 5

//#define OUTPUT_GBUFFER(NAME)                            \
//        out GBufferType0 MERGE_NAME(NAME, 0) : SV_Target0,    \
//        out GBufferType1 MERGE_NAME(NAME, 1) : SV_Target1,    \
//        out GBufferType2 MERGE_NAME(NAME, 2) : SV_Target2,    \
//        out GBufferType3 MERGE_NAME(NAME, 3) : SV_Target3,    \
//        out GBufferType4 MERGE_NAME(NAME, 4) : SV_Target4

#define GRASS_ENCODE_INTO_GBUFFER(SURFACE_DATA, BUILTIN_DATA, UNPOSITIONSS, NAME) Grass_EncodeIntoGBuffer(SURFACE_DATA, BUILTIN_DATA, UNPOSITIONSS, MERGE_NAME(NAME, 0), MERGE_NAME(NAME, 1), MERGE_NAME(NAME, 2), MERGE_NAME(NAME, 3), MERGE_NAME(NAME, 4))

#elif GBUFFERMATERIAL_COUNT == 6

//#define OUTPUT_GBUFFER(NAME)                            \
//        out GBufferType0 MERGE_NAME(NAME, 0) : SV_Target0,    \
//        out GBufferType1 MERGE_NAME(NAME, 1) : SV_Target1,    \
//        out GBufferType2 MERGE_NAME(NAME, 2) : SV_Target2,    \
//        out GBufferType3 MERGE_NAME(NAME, 3) : SV_Target3,    \
//        out GBufferType4 MERGE_NAME(NAME, 4) : SV_Target4,    \
//        out GBufferType5 MERGE_NAME(NAME, 5) : SV_Target5

#define GRASS_ENCODE_INTO_GBUFFER(SURFACE_DATA, BUILTIN_DATA, UNPOSITIONSS, NAME) Grass_EncodeIntoGBuffer(SURFACE_DATA, BUILTIN_DATA, UNPOSITIONSS, MERGE_NAME(NAME, 0), MERGE_NAME(NAME, 1), MERGE_NAME(NAME, 2), MERGE_NAME(NAME, 3), MERGE_NAME(NAME, 4), MERGE_NAME(NAME, 5))

#elif GBUFFERMATERIAL_COUNT == 7

//#define OUTPUT_GBUFFER(NAME)                            \
//        out GBufferType0 MERGE_NAME(NAME, 0) : SV_Target0,    \
//        out GBufferType1 MERGE_NAME(NAME, 1) : SV_Target1,    \
//        out GBufferType2 MERGE_NAME(NAME, 2) : SV_Target2,    \
//        out GBufferType3 MERGE_NAME(NAME, 3) : SV_Target3,    \
//        out GBufferType4 MERGE_NAME(NAME, 4) : SV_Target4,    \
//        out GBufferType5 MERGE_NAME(NAME, 5) : SV_Target5,    \
//        out GBufferType6 MERGE_NAME(NAME, 6) : SV_Target6

#define GRASS_ENCODE_INTO_GBUFFER(SURFACE_DATA, BUILTIN_DATA, UNPOSITIONSS, NAME) Grass_EncodeIntoGBuffer(SURFACE_DATA, BUILTIN_DATA, UNPOSITIONSS, MERGE_NAME(NAME, 0), MERGE_NAME(NAME, 1), MERGE_NAME(NAME, 2), MERGE_NAME(NAME, 3), MERGE_NAME(NAME, 4), MERGE_NAME(NAME, 5), MERGE_NAME(NAME, 6))

#elif GBUFFERMATERIAL_COUNT == 8

//#define OUTPUT_GBUFFER(NAME)                            \
//        out GBufferType0 MERGE_NAME(NAME, 0) : SV_Target0,    \
//        out GBufferType1 MERGE_NAME(NAME, 1) : SV_Target1,    \
//        out GBufferType2 MERGE_NAME(NAME, 2) : SV_Target2,    \
//        out GBufferType3 MERGE_NAME(NAME, 3) : SV_Target3,    \
//        out GBufferType4 MERGE_NAME(NAME, 4) : SV_Target4,    \
//        out GBufferType5 MERGE_NAME(NAME, 5) : SV_Target5,    \
//        out GBufferType6 MERGE_NAME(NAME, 6) : SV_Target6,    \
//        out GBufferType7 MERGE_NAME(NAME, 7) : SV_Target7

#define GRASS_ENCODE_INTO_GBUFFER(SURFACE_DATA, BUILTIN_DATA, UNPOSITIONSS, NAME) Grass_EncodeIntoGBuffer(SURFACE_DATA, BUILTIN_DATA, UNPOSITIONSS, MERGE_NAME(NAME, 0), MERGE_NAME(NAME, 1), MERGE_NAME(NAME, 2), MERGE_NAME(NAME, 3), MERGE_NAME(NAME, 4), MERGE_NAME(NAME, 5), MERGE_NAME(NAME, 6), MERGE_NAME(NAME, 7))

#endif

#endif

#endif // GRASS_COMMON_GBUFFER