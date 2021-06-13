Shader "Grass/Grass_TesselationGeometry"
{
    Properties
    {
		//_GrassDensity("Grass Density", Float) = 1
		_GrassOffset("Position Randomization", Range(0, 5)) = 0
		
		//[Header(Textures)] [Space(7)]

		_GrassMap("Grass Map", 2D) = "white" {}
		
		_FieldTexture("Field Texture", 2D) = "white" {}

		_BladeTexture("Blade Texture", 2D) = "white" {}

		//[Header(Grass Blade Shapes)] [Space(7)]

		_BladeWidth("Median Blade Width", Float) = 0.05
		_BladeWidthRandom("Max Random Width Offset", Float) = 0.02

		//[Space(5)]

		_BladeHeight("Median Blade Height", Float) = 0.5
		_BladeHeightRandom("Max Random Height Offset", Float) = 0.3
		
		//[Space(5)]
		
		_BladeRotationRange("Rotation Range", Range(0, 360)) = 360
		_BendRotationRandom("Max Downward Rotation", Range(0, 1)) = 0.2
		_BladeCurve("Curvature", Range(1, 4)) = 2
		_BladeForward("Max Random Curvature Offset (aka Grass Untidiness)", Float) = 0.4

		//[Header(Grass Blade Colour Properties)] [Space(7)]

		_GrassBottomColour("Grass Bottom Colour", Color) = (1, 1, 1, 1)
		_GrassTopColour("Grass Top Colour", Color) = (1, 1, 1, 1)
        _Metallic("Metallic", Range(0.0, 1.0)) = 0
        _Smoothness("Smoothness", Range(0.0, 1.0)) = 0.5

		//[Header(Wind)] [Space(7)]

		_WindDistortionMap("Wind Distortion Map", 2D) = "white" {}
		_WindFrequency("Wind Frequency", Vector) = (0.05, 0.05, 0, 0)
		_WindStrength("Wind Strength", Float) = 1
		
		//[Header(Normals)] [Space(7)]

		[Toggle(NORMAL_TYPE_TRUE)]
		_NormalTypeTrue("Normal Type: True", Float) = 0
		
		[Toggle(NORMAL_TYPE_FROM_SOURCE)]
		_NormalTypeFromSource("Normal Type: From Source", Float) = 0

		[Toggle(NORMAL_TYPE_OVERRIDE)]
		_NormalTypeAbsolute("Normal Type: Override", Float) = 0
		
		_GrassLODSqrDistances("Grass LOD Square Distances (Nearest to Farthest)", Vector) = (15, 30, 45, 0)
		_GrassLODSegments("Grass LOD Segments", Vector) = (7, 1, 1, 0)
		_GrassLODDensities("Grass LOD Densities", Vector) = (1, 0, 0, 0)

		_AbsoluteNormal("Absolute Normal", Vector) = (0, 1, 0, 0)

		//_FrustumCullingScreenSpaceMargin("Frustum Culling Screen Space Margin", Float) = 0

		//[Header(Debug)] [Space(7)]
		
		[Toggle(BILLBOARD)]
		_Billboard("Billboard", Float) = 0
		
		[Toggle(GENERATE_QUADS)]
		_GenerateQuads("Generate Quads", Float) = 0
		
		[Toggle(VISUALIZE_WIND)]
		_DebugWind("Visualize Wind", Float) = 0
		
		[Toggle(VISUALIZE_DISPLACEMENT)]
		_DebugDisplacement("Visualize Displacement", Float) = 0

		[Toggle(VISUALIZE_LODS)]
		_DebugLODs("Visualize LODs", Float) = 0

		[Toggle(DRAW_SOURCE_GEOMETRY)]
		_DrawSourceGeometry("Draw Source Geometry", Float) = 0

		//[HideInInspector] _GrassDisplacementSpheresBufferCount("_GrassDisplacementSpheresBufferCount", int) = 0

        // Following set of parameters represent the parameters node inside the MaterialGraph.
        // They are use to fill a SurfaceData. With a MaterialGraph this should not exist.

        // Reminder. Color here are in linear but the UI (color picker) do the conversion sRGB to linear
        [HideInInspector] _BaseColor("BaseColor", Color) = (1,1,1,1)
        [HideInInspector] _BaseColorMap("BaseColorMap", 2D) = "white" {}
        [HideInInspector] _BaseColorMap_MipInfo("_BaseColorMap_MipInfo", Vector) = (0, 0, 0, 0)

        [HideInInspector] _MaskMap("MaskMap", 2D) = "white" {}
        [HideInInspector] _SmoothnessRemapMin("SmoothnessRemapMin", Float) = 0.0
        [HideInInspector] _SmoothnessRemapMax("SmoothnessRemapMax", Float) = 1.0
        [HideInInspector] _AORemapMin("AORemapMin", Float) = 0.0
        [HideInInspector] _AORemapMax("AORemapMax", Float) = 1.0

        [HideInInspector] _NormalMap("NormalMap", 2D) = "bump" {}     // Tangent space normal map
        [HideInInspector] _NormalMapOS("NormalMapOS", 2D) = "white" {} // Object space normal map - no good default value
        [HideInInspector] _NormalScale("_NormalScale", Range(0.0, 8.0)) = 1

        [HideInInspector] _BentNormalMap("_BentNormalMap", 2D) = "bump" {}
        [HideInInspector] _BentNormalMapOS("_BentNormalMapOS", 2D) = "white" {}

       [HideInInspector]  _HeightMap("HeightMap", 2D) = "black" {}
        // Caution: Default value of _HeightAmplitude must be (_HeightMax - _HeightMin) * 0.01
        // Those two properties are computed from the ones exposed in the UI and depends on the displaement mode so they are separate because we don't want to lose information upon displacement mode change.
        [HideInInspector] _HeightAmplitude("Height Amplitude", Float) = 0.02 // In world units. This will be computed in the UI.
        [HideInInspector] _HeightCenter("Height Center", Range(0.0, 1.0)) = 0.5 // In texture space

        [HideInInspector] [Enum(MinMax, 0, Amplitude, 1)] _HeightMapParametrization("Heightmap Parametrization", Int) = 0
        // These parameters are for vertex displacement/Tessellation
        [HideInInspector] _HeightOffset("Height Offset", Float) = 0
        // MinMax mode
        [HideInInspector] _HeightMin("Heightmap Min", Float) = -1
        [HideInInspector] _HeightMax("Heightmap Max", Float) = 1
        // Amplitude mode
        [HideInInspector] _HeightTessAmplitude("Amplitude", Float) = 2.0 // in Centimeters
        [HideInInspector] _HeightTessCenter("Height Center", Range(0.0, 1.0)) = 0.5 // In texture space

        // These parameters are for pixel displacement
       [HideInInspector] _HeightPoMAmplitude("Height Amplitude", Float) = 2.0 // In centimeters

        [HideInInspector] _DetailMap("DetailMap", 2D) = "linearGrey" {}
       [HideInInspector] _DetailAlbedoScale("_DetailAlbedoScale", Range(0.0, 2.0)) = 1
       [HideInInspector] _DetailNormalScale("_DetailNormalScale", Range(0.0, 2.0)) = 1
        [HideInInspector] _DetailSmoothnessScale("_DetailSmoothnessScale", Range(0.0, 2.0)) = 1

        [HideInInspector] _TangentMap("TangentMap", 2D) = "bump" {}
        [HideInInspector] _TangentMapOS("TangentMapOS", 2D) = "white" {}
        [HideInInspector] _Anisotropy("Anisotropy", Range(-1.0, 1.0)) = 0
       [HideInInspector] _AnisotropyMap("AnisotropyMap", 2D) = "white" {}

       [HideInInspector] _SubsurfaceMask("Subsurface Radius", Range(0.0, 1.0)) = 1.0
       [HideInInspector] _SubsurfaceMaskMap("Subsurface Radius Map", 2D) = "white" {}
        [HideInInspector] _Thickness("Thickness", Range(0.0, 1.0)) = 1.0
        [HideInInspector] _ThicknessMap("Thickness Map", 2D) = "white" {}
       [HideInInspector] _ThicknessRemap("Thickness Remap", Vector) = (0, 1, 0, 0)

       [HideInInspector] _IridescenceThickness("Iridescence Thickness", Range(0.0, 1.0)) = 1.0
       [HideInInspector] _IridescenceThicknessMap("Iridescence Thickness Map", 2D) = "white" {}
       [HideInInspector] _IridescenceThicknessRemap("Iridescence Thickness Remap", Vector) = (0, 1, 0, 0)
       [HideInInspector] _IridescenceMask("Iridescence Mask", Range(0.0, 1.0)) = 1.0
        [HideInInspector] _IridescenceMaskMap("Iridescence Mask Map", 2D) = "white" {}

       [HideInInspector] _CoatMask("Coat Mask", Range(0.0, 1.0)) = 0.0
        [HideInInspector] _CoatMaskMap("CoatMaskMap", 2D) = "white" {}

        [HideInInspector] [ToggleUI] _EnergyConservingSpecularColor("_EnergyConservingSpecularColor", Float) = 1.0
        [HideInInspector] _SpecularColor("SpecularColor", Color) = (1, 1, 1, 1)
       [HideInInspector] _SpecularColorMap("SpecularColorMap", 2D) = "white" {}

        // Following options are for the GUI inspector and different from the input parameters above
        // These option below will cause different compilation flag.
        [HideInInspector] [Enum(Off, 0, From Ambient Occlusion, 1, From Bent Normals, 2)]  _SpecularOcclusionMode("Specular Occlusion Mode", Int) = 1

        [HideInInspector] [HDR] _EmissiveColor("EmissiveColor", Color) = (0, 0, 0)
        // Used only to serialize the LDR and HDR emissive color in the material UI,
        // in the shader only the _EmissiveColor should be used
        [HideInInspector] _EmissiveColorLDR("EmissiveColor LDR", Color) = (0, 0, 0)
        [HideInInspector] _EmissiveColorMap("EmissiveColorMap", 2D) = "white" {}
        [HideInInspector] [ToggleUI] _AlbedoAffectEmissive("Albedo Affect Emissive", Float) = 0.0
        [HideInInspector] _EmissiveIntensityUnit("Emissive Mode", Int) = 0
        [HideInInspector] [ToggleUI] _UseEmissiveIntensity("Use Emissive Intensity", Int) = 0
        [HideInInspector] _EmissiveIntensity("Emissive Intensity", Float) = 1
       [HideInInspector] _EmissiveExposureWeight("Emissive Pre Exposure", Range(0.0, 1.0)) = 1.0

       [HideInInspector]  _DistortionVectorMap("DistortionVectorMap", 2D) = "black" {}
        [HideInInspector] [ToggleUI] _DistortionEnable("Enable Distortion", Float) = 0.0
       [HideInInspector]  [ToggleUI] _DistortionDepthTest("Distortion Depth Test Enable", Float) = 1.0
       [HideInInspector]  [Enum(Add, 0, Multiply, 1, Replace, 2)] _DistortionBlendMode("Distortion Blend Mode", Int) = 0
        [HideInInspector] _DistortionSrcBlend("Distortion Blend Src", Int) = 0
        [HideInInspector] _DistortionDstBlend("Distortion Blend Dst", Int) = 0
        [HideInInspector] _DistortionBlurSrcBlend("Distortion Blur Blend Src", Int) = 0
        [HideInInspector] _DistortionBlurDstBlend("Distortion Blur Blend Dst", Int) = 0
        [HideInInspector] _DistortionBlurBlendMode("Distortion Blur Blend Mode", Int) = 0
       [HideInInspector] _DistortionScale("Distortion Scale", Float) = 1
       [HideInInspector] _DistortionVectorScale("Distortion Vector Scale", Float) = 2
       [HideInInspector] _DistortionVectorBias("Distortion Vector Bias", Float) = -1
       [HideInInspector] _DistortionBlurScale("Distortion Blur Scale", Float) = 1
       [HideInInspector] _DistortionBlurRemapMin("DistortionBlurRemapMin", Float) = 0.0
       [HideInInspector] _DistortionBlurRemapMax("DistortionBlurRemapMax", Float) = 1.0

[ToggleUI]  _UseShadowThreshold("_UseShadowThreshold", Float) = 0.0
        [ToggleUI]  _AlphaCutoffEnable("Alpha Cutoff Enable", Float) = 0.0
        _AlphaCutoff("Alpha Cutoff", Range(0.0, 1.0)) = 0.5
 _AlphaCutoffShadow("_AlphaCutoffShadow", Range(0.0, 1.0)) = 0.5
_AlphaCutoffPrepass("_AlphaCutoffPrepass", Range(0.0, 1.0)) = 0.5
 _AlphaCutoffPostpass("_AlphaCutoffPostpass", Range(0.0, 1.0)) = 0.5
     [ToggleUI] _TransparentDepthPrepassEnable("_TransparentDepthPrepassEnable", Float) = 0.0
[ToggleUI] _TransparentBackfaceEnable("_TransparentBackfaceEnable", Float) = 0.0
[ToggleUI] _TransparentDepthPostpassEnable("_TransparentDepthPostpassEnable", Float) = 0.0
_TransparentSortPriority("_TransparentSortPriority", Float) = 0

        // Transparency
        [HideInInspector] [Enum(None, 0, Box, 1, Sphere, 2, Thin, 3)]_RefractionModel("Refraction Model", Int) = 0
        [HideInInspector] [Enum(Proxy, 1, HiZ, 2)]_SSRefractionProjectionModel("Refraction Projection Model", Int) = 0
        [HideInInspector] _Ior("Index Of Refraction", Range(1.0, 2.5)) = 1.5
        [HideInInspector] _TransmittanceColor("Transmittance Color", Color) = (1.0, 1.0, 1.0)
        [HideInInspector] _TransmittanceColorMap("TransmittanceColorMap", 2D) = "white" {}
        [HideInInspector] _ATDistance("Transmittance Absorption Distance", Float) = 1.0
        [HideInInspector] [ToggleUI] _TransparentWritingMotionVec("_TransparentWritingMotionVec", Float) = 0.0

        // Stencil state

        // Forward
        [HideInInspector] _StencilRef("_StencilRef", Int) = 0 // StencilUsage.Clear
        [HideInInspector] _StencilWriteMask("_StencilWriteMask", Int) = 3 // StencilUsage.RequiresDeferredLighting | StencilUsage.SubsurfaceScattering
        // GBuffer
        [HideInInspector] _StencilRefGBuffer("_StencilRefGBuffer", Int) = 2 // StencilUsage.RequiresDeferredLighting
        [HideInInspector] _StencilWriteMaskGBuffer("_StencilWriteMaskGBuffer", Int) = 3 // StencilUsage.RequiresDeferredLighting | StencilUsage.SubsurfaceScattering
        // Depth prepass
        [HideInInspector] _StencilRefDepth("_StencilRefDepth", Int) = 0 // Nothing
        [HideInInspector] _StencilWriteMaskDepth("_StencilWriteMaskDepth", Int) = 8 // StencilUsage.TraceReflectionRay
        // Motion vector pass
        [HideInInspector] _StencilRefMV("_StencilRefMV", Int) = 32 // StencilUsage.ObjectMotionVector
        [HideInInspector] _StencilWriteMaskMV("_StencilWriteMaskMV", Int) = 32 // StencilUsage.ObjectMotionVector
        // Distortion vector pass
        [HideInInspector] _StencilRefDistortionVec("_StencilRefDistortionVec", Int) = 4 // StencilUsage.DistortionVectors
        [HideInInspector] _StencilWriteMaskDistortionVec("_StencilWriteMaskDistortionVec", Int) = 4 // StencilUsage.DistortionVectors

        // Blending state
_SurfaceType("__surfacetype", Float) = 1.0
        [HideInInspector] _BlendMode("__blendmode", Float) = 0.0
        [HideInInspector] _SrcBlend("__src", Float) = 1.0
        [HideInInspector] _DstBlend("__dst", Float) = 0.0
        [HideInInspector] _AlphaSrcBlend("__alphaSrc", Float) = 1.0
        [HideInInspector] _AlphaDstBlend("__alphaDst", Float) = 0.0
        [HideInInspector][ToggleUI] _ZWrite("__zw", Float) = 1.0
[ToggleUI] _TransparentZWrite("_TransparentZWrite", Float) = 0.0
        [HideInInspector] _CullMode("__cullmode", Float) = 2.0
        [HideInInspector] _CullModeForward("__cullmodeForward", Float) = 2.0 // This mode is dedicated to Forward to correctly handle backface then front face rendering thin transparent
[Enum(UnityEditor.Rendering.HighDefinition.TransparentCullMode)] _TransparentCullMode("_TransparentCullMode", Int) = 2 // Back culling by default
        [HideInInspector] _ZTestDepthEqualForOpaque("_ZTestDepthEqualForOpaque", Int) = 4 // Less equal
        [HideInInspector] _ZTestModeDistortion("_ZTestModeDistortion", Int) = 8
        [HideInInspector] _ZTestGBuffer("_ZTestGBuffer", Int) = 4
        [HideInInspector] [Enum(UnityEngine.Rendering.CompareFunction)] _ZTestTransparent("Transparent ZTest", Int) = 4 // Less equal

        [HideInInspector] [ToggleUI] _EnableFogOnTransparent("Enable Fog", Float) = 1.0
        [HideInInspector] [ToggleUI] _EnableBlendModePreserveSpecularLighting("Enable Blend Mode Preserve Specular Lighting", Float) = 1.0

		[HideInInspector] [ToggleUI] _DoubleSidedEnable("Double sided enable", Float) = 0.0
       [HideInInspector]  [Enum(Flip, 0, Mirror, 1, None, 2)] _DoubleSidedNormalMode("Double sided normal mode", Float) = 1
       [HideInInspector]  _DoubleSidedConstants("_DoubleSidedConstants", Vector) = (1, 1, -1, 0)

        [HideInInspector] [Enum(UV0, 0, UV1, 1, UV2, 2, UV3, 3, Planar, 4, Triplanar, 5)] _UVBase("UV Set for base", Float) = 0
        [HideInInspector] _TexWorldScale("Scale to apply on world coordinate", Float) = 1.0
        [HideInInspector] _InvTilingScale("Inverse tiling scale = 2 / (abs(_BaseColorMap_ST.x) + abs(_BaseColorMap_ST.y))", Float) = 1
        [HideInInspector] _UVMappingMask("_UVMappingMask", Color) = (1, 0, 0, 0)
        [HideInInspector] [Enum(TangentSpace, 0, ObjectSpace, 1)] _NormalMapSpace("NormalMap space", Float) = 0

        // Following enum should be material feature flags (i.e bitfield), however due to Gbuffer encoding constrain many combination exclude each other
        // so we use this enum as "material ID" which can be interpreted as preset of bitfield of material feature
        // The only material feature flag that can be added in all cases is clear coat
        [HideInInspector] [Enum(Subsurface Scattering, 0, Standard, 1, Anisotropy, 2, Iridescence, 3, Specular Color, 4, Translucent, 5)] _MaterialID("MaterialId", Int) = 1 // MaterialId.Standard
        [HideInInspector] [ToggleUI] _TransmissionEnable("_TransmissionEnable", Float) = 1.0

        [HideInInspector] [Enum(None, 0, Vertex displacement, 1, Pixel displacement, 2)] _DisplacementMode("DisplacementMode", Int) = 0
        [HideInInspector] [ToggleUI] _DisplacementLockObjectScale("displacement lock object scale", Float) = 1.0
        [HideInInspector] [ToggleUI] _DisplacementLockTilingScale("displacement lock tiling scale", Float) = 1.0
        [HideInInspector] [ToggleUI] _DepthOffsetEnable("Depth Offset View space", Float) = 0.0

        [HideInInspector] [ToggleUI] _EnableGeometricSpecularAA("EnableGeometricSpecularAA", Float) = 0.0
        [HideInInspector] _SpecularAAScreenSpaceVariance("SpecularAAScreenSpaceVariance", Range(0.0, 1.0)) = 0.1
        [HideInInspector] _SpecularAAThreshold("SpecularAAThreshold", Range(0.0, 1.0)) = 0.2

        [HideInInspector] _PPDMinSamples("Min sample for POM", Range(1.0, 64.0)) = 5
        [HideInInspector] _PPDMaxSamples("Max sample for POM", Range(1.0, 64.0)) = 15
        [HideInInspector] _PPDLodThreshold("Start lod to fade out the POM effect", Range(0.0, 16.0)) = 5
        [HideInInspector] _PPDPrimitiveLength("Primitive length for POM", Float) = 1
        [HideInInspector] _PPDPrimitiveWidth("Primitive width for POM", Float) = 1
        [HideInInspector] _InvPrimScale("Inverse primitive scale for non-planar POM", Vector) = (1, 1, 0, 0)

        [HideInInspector] [Enum(UV0, 0, UV1, 1, UV2, 2, UV3, 3)] _UVDetail("UV Set for detail", Float) = 0
        [HideInInspector] _UVDetailsMappingMask("_UVDetailsMappingMask", Color) = (1, 0, 0, 0)
        [HideInInspector] [ToggleUI] _LinkDetailsWithBase("LinkDetailsWithBase", Float) = 1.0

        [HideInInspector] [Enum(Use Emissive Color, 0, Use Emissive Mask, 1)] _EmissiveColorMode("Emissive color mode", Float) = 1
        [HideInInspector] [Enum(UV0, 0, UV1, 1, UV2, 2, UV3, 3, Planar, 4, Triplanar, 5)] _UVEmissive("UV Set for emissive", Float) = 0
        [HideInInspector] _TexWorldScaleEmissive("Scale to apply on world coordinate", Float) = 1.0
        [HideInInspector] _UVMappingMaskEmissive("_UVMappingMaskEmissive", Color) = (1, 0, 0, 0)

        // Caution: C# code in BaseLitUI.cs call LightmapEmissionFlagsProperty() which assume that there is an existing "_EmissionColor"
        // value that exist to identify if the GI emission need to be enabled.
        // In our case we don't use such a mechanism but need to keep the code quiet. We declare the value and always enable it.
        // TODO: Fix the code in legacy unity so we can customize the beahvior for GI
        [HideInInspector] _EmissionColor("Color", Color) = (1, 1, 1)

        // HACK: GI Baking system relies on some properties existing in the shader ("_MainTex", "_Cutoff" and "_Color") for opacity handling, so we need to store our version of those parameters in the hard-coded name the GI baking system recognizes.
        [HideInInspector] _MainTex("Albedo", 2D) = "white" {}
        [HideInInspector] _Color("Color", Color) = (1,1,1,1)
        [HideInInspector] _Cutoff("Alpha Cutoff", Range(0.0, 1.0)) = 0.5

        [HideInInspector] [ToggleUI] _SupportDecals("Support Decals", Float) = 1.0
        [HideInInspector] [ToggleUI] _ReceivesSSR("Receives SSR", Float) = 1.0
        [HideInInspector] [ToggleUI] _AddPrecomputedVelocity("AddPrecomputedVelocity", Float) = 0.0

        [HideInInspector] _DiffusionProfile("Obsolete, kept for migration purpose", Int) = 0
        [HideInInspector] _DiffusionProfileAsset("Diffusion Profile Asset", Vector) = (0, 0, 0, 0)
        [HideInInspector] _DiffusionProfileHash("Diffusion Profile Hash", Float) = 0
    }

    HLSLINCLUDE
	
    #pragma target 4.5

    #pragma require geometry
	#pragma require tessellation tessHW

    //-------------------------------------------------------------------------------------
    // Variant
    //-------------------------------------------------------------------------------------

    // enable dithering LOD crossfade
    #pragma multi_compile _ LOD_FADE_CROSSFADE
	#pragma multi_compile NORMAL_TYPE_TRUE NORMAL_TYPE_FROM_SOURCE NORMAL_TYPE_OVERRIDE

    //enable GPU instancing support
    //#pragma multi_compile_instancing
    //#pragma instancing_options renderinglayer
	
	#pragma shader_feature CAST_SHADOWS
	#pragma shader_feature APPLY_DISPLACEMENT
	#pragma shader_feature DRAW_SOURCE_GEOMETRY
	#pragma shader_feature PROPORTIONAL_TESSELATION
	#pragma shader_feature FRUSTUM_CULLING
	#pragma shader_feature LODS_ENABLED
	#pragma shader_feature BILLBOARD
	#pragma shader_feature GENERATE_QUADS

	#pragma shader_feature DISABLE_TESSELATION
			
	// Keyword for transparent
    #pragma shader_feature _SURFACE_TYPE_TRANSPARENT
    #pragma shader_feature_local _ _BLENDMODE_ALPHA _BLENDMODE_ADD _BLENDMODE_PRE_MULTIPLY
    #pragma shader_feature_local _BLENDMODE_PRESERVE_SPECULAR_LIGHTING
    #pragma shader_feature_local _ENABLE_FOG_ON_TRANSPARENT
    #pragma shader_feature_local _TRANSPARENT_WRITES_MOTION_VEC

    //-------------------------------------------------------------------------------------
    // Define
    //-------------------------------------------------------------------------------------

    #define TESSELLATION_ON
	#define _DOUBLESIDED_ON

	#define HAVE_TESSELLATION_MODIFICATION

	#define ATTRIBUTES_NEED_TANGENT
	#define ATTRIBUTES_NEED_TEXCOORD0
			
	#define VARYINGS_NEED_POSITION_WS
	#define VARYINGS_NEED_TANGENT_TO_WORLD

	#define ATTRIBUTES_NEED_COLOR
	#define VARYINGS_NEED_COLOR

    //-------------------------------------------------------------------------------------
    // Include
    //-------------------------------------------------------------------------------------

    #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
    #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/GeometricTools.hlsl"
    #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Tessellation.hlsl"
    #include "Packages/com.unity.render-pipelines.high-definition/Runtime/ShaderLibrary/ShaderVariables.hlsl"
    #include "Packages/com.unity.render-pipelines.high-definition/Runtime/RenderPipeline/ShaderPass/FragInputs.hlsl"
    #include "Packages/com.unity.render-pipelines.high-definition/Runtime/RenderPipeline/ShaderPass/ShaderPass.cs.hlsl"
    #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Material.hlsl"
    #include "Grass_TesselationGeometry_Properties.hlsl"
	
    ENDHLSL

    SubShader
    {
        // This tags allow to use the shader replacement features
        Tags{ "RenderPipeline"="HDRenderPipeline" "RenderType" = "HDLitShader" }
		
        Pass
        {
            Name "SceneSelectionPass"
            Tags { "LightMode" = "SceneSelectionPass" }

            Cull Off
            ZWrite On

            HLSLPROGRAM

            #pragma only_renderers d3d11 ps4 xboxone vulkan metal switch
            //enable GPU instancing support
            #pragma multi_compile_instancing
            #pragma instancing_options renderinglayer

            // Note: Require _ObjectId and _PassValue variables

            // We reuse depth prepass for the scene selection, allow to handle alpha correctly as well as tessellation and vertex animation
            #define SHADERPASS SHADERPASS_DEPTH_ONLY
            #define SCENESELECTIONPASS // This will drive the output of the scene selection shader
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Material.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Lit/Lit.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Lit/ShaderPass/LitDepthPass.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Lit/LitData.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/RenderPipeline/ShaderPass/ShaderPassDepthOnly.hlsl"
			
			#include "Grass_TesselationGeometry_Common.hlsl"
            #include "Grass_TesselationGeometry_Tesselation.hlsl"

		#ifdef DRAW_SOURCE_GEOMETRY
			#include "Grass_TesselationGeometry_GeometryPassthrough.hlsl"
		#else
			#include "Grass_TesselationGeometry_Geometry.hlsl"
		#endif
			
            #pragma vertex Vert
            #pragma fragment Frag
            #pragma hull GrassHull
            #pragma domain GrassDomain
			#pragma geometry GrassGeometry

            #pragma editor_sync_compilation

            ENDHLSL
        }
		
        // Caution: The outline selection in the editor use the vertex shader/hull/domain shader of the first pass declare. So it should not bethe  meta pass.
        Pass
        {
            Name "Grass"
            Tags { "LightMode" = "GBuffer" } // This will be only for opaque object based on the RenderQueue index

            Cull Off
            ZTest LEqual

            Stencil
            {
                WriteMask [_StencilWriteMaskGBuffer]
                Ref  [_StencilRefGBuffer]
                Comp Always
                Pass Replace
            }

            HLSLPROGRAM

            #pragma only_renderers d3d11 ps4 xboxone vulkan metal switch

            //enable GPU instancing support
            //#pragma multi_compile_instancing
            //#pragma instancing_options renderinglayer

			#define ATTRIBUTES_NEED_NORMAL

			#define VARYINGS_NEED_POSITION

			#pragma multi_compile _ VISUALIZE_DISPLACEMENT VISUALIZE_WIND VISUALIZE_LODS
			
        #ifndef DEBUG_DISPLAY
            // When we have alpha test, we will force a depth prepass so we always bypass the clip instruction in the GBuffer
            // Don't do it with debug display mode as it is possible there is no depth prepass in this case
            #define SHADERPASS_GBUFFER_BYPASS_ALPHA_TEST
        #endif

            #define SHADERPASS SHADERPASS_GBUFFER

            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Material.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Lit/Lit.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Lit/ShaderPass/LitSharePass.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Lit/LitData.hlsl"

            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/RenderPipeline/ShaderPass/ShaderPassGBuffer.hlsl"
			
			#include "Grass_TesselationGeometry_Common.hlsl"
            #include "Grass_TesselationGeometry_Fragment.hlsl"
            #include "Grass_TesselationGeometry_Tesselation.hlsl"

		#ifdef DRAW_SOURCE_GEOMETRY
			#include "Grass_TesselationGeometry_GeometryPassthrough.hlsl"
		#else
			#include "Grass_TesselationGeometry_Geometry.hlsl"
		#endif

            #pragma vertex Vert
            #pragma fragment GrassFragment
            #pragma hull GrassHull
            #pragma domain GrassDomain
			#pragma geometry GrassGeometry

            ENDHLSL
        }

        Pass
        {
            Name "ShadowCaster"
            Tags { "LightMode" = "ShadowCaster" }

            Cull Off

            ZClip [_ZClip]
            ZWrite On
            ZTest LEqual

            ColorMask 0

            HLSLPROGRAM
			
            #pragma only_renderers d3d11 ps4 xboxone vulkan metal switch

            //enable GPU instancing support
            //#pragma multi_compile_instancing
            //#pragma instancing_options renderinglayer

            #define SHADERPASS SHADERPASS_SHADOWS

            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Material.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Lit/Lit.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Lit/ShaderPass/LitDepthPass.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Lit/LitData.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/RenderPipeline/ShaderPass/ShaderPassDepthOnly.hlsl"
			
			#include "Grass_TesselationGeometry_Common.hlsl"
            #include "Grass_TesselationGeometry_Tesselation.hlsl"
            #include "Grass_TesselationGeometry_Fragment.hlsl"
			
		#if defined(DRAW_SOURCE_GEOMETRY) || !defined(CAST_SHADOWS)
			#include "Grass_TesselationGeometry_GeometryPassthrough.hlsl"
		#else
			#include "Grass_TesselationGeometry_Geometry.hlsl"
		#endif

		#ifdef APPLY_DISPLACEMENT

            #pragma vertex Vert
            #pragma fragment Frag
            #pragma hull GrassHull
            #pragma domain GrassDomain
			#pragma geometry GrassGeometry
		#endif

            ENDHLSL
        }

        Pass
        {
            Name "DepthOnly"
            Tags{ "LightMode" = "DepthOnly" }

            Cull Off

            // To be able to tag stencil with disableSSR information for forward
            Stencil
            {
                WriteMask [_StencilWriteMaskDepth]
                Ref [_StencilRefDepth]
                Comp Always
                Pass Replace
            }

            ZWrite On

            HLSLPROGRAM

            #pragma only_renderers d3d11 ps4 xboxone vulkan metal switch

            //enable GPU instancing support
            //#pragma multi_compile_instancing
            //#pragma instancing_options renderinglayer

            // In deferred, depth only pass don't output anything.
            // In forward it output the normal buffer
            #pragma multi_compile _ WRITE_NORMAL_BUFFER
            #pragma multi_compile _ WRITE_MSAA_DEPTH

            #define SHADERPASS SHADERPASS_DEPTH_ONLY

			#define VARYINGS_NEED_TEXCOORD0

            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Material.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Lit/Lit.hlsl"

            #ifdef WRITE_NORMAL_BUFFER // If enabled we need all regular interpolator
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Lit/ShaderPass/LitSharePass.hlsl"
            #else
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Lit/ShaderPass/LitDepthPass.hlsl"
            #endif

            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Lit/LitData.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/RenderPipeline/ShaderPass/ShaderPassDepthOnly.hlsl"
			
			#include "Grass_TesselationGeometry_Common.hlsl"
            #include "Grass_TesselationGeometry_Fragment.hlsl"
            #include "Grass_TesselationGeometry_Tesselation.hlsl"
			
		#ifdef DRAW_SOURCE_GEOMETRY
			#include "Grass_TesselationGeometry_GeometryPassthrough.hlsl"
		#else
			#include "Grass_TesselationGeometry_Geometry.hlsl"
		#endif

            #pragma vertex Vert
            #pragma fragment Frag
            #pragma hull GrassHull
            #pragma domain GrassDomain
			#pragma geometry GrassGeometry

            ENDHLSL
        }

	
        Pass
        {
            Name "TransparentDepthPrepass"
            Tags{ "LightMode" = "TransparentDepthPrepass" }

            Cull[_CullMode]
            ZWrite On
            ColorMask 0

            HLSLPROGRAM

            #pragma only_renderers d3d11 ps4 xboxone vulkan metal switch

            //enable GPU instancing support
            #pragma multi_compile_instancing
            #pragma instancing_options renderinglayer
			
			#define ATTRIBUTES_NEED_NORMAL

			#define VARYINGS_NEED_POSITION

			#pragma multi_compile _ VISUALIZE_DISPLACEMENT VISUALIZE_WIND VISUALIZE_LODS

            #define SHADERPASS SHADERPASS_DEPTH_ONLY
            #define CUTOFF_TRANSPARENT_DEPTH_PREPASS
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Material.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Lit/Lit.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Lit/ShaderPass/LitDepthPass.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Lit/LitData.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/RenderPipeline/ShaderPass/ShaderPassDepthOnly.hlsl"

			#include "Grass_TesselationGeometry_Common.hlsl"
            #include "Grass_TesselationGeometry_Fragment.hlsl"
            #include "Grass_TesselationGeometry_Tesselation.hlsl"
			
		#ifdef DRAW_SOURCE_GEOMETRY
			#include "Grass_TesselationGeometry_GeometryPassthrough.hlsl"
		#else
			#include "Grass_TesselationGeometry_Geometry.hlsl"
		#endif

            #pragma vertex Vert
            #pragma fragment Frag
            #pragma hull GrassHull
            #pragma domain GrassDomain
			#pragma geometry GrassGeometry

            ENDHLSL
        }

        // Caution: Order is important: TransparentBackface, then Forward/ForwardOnly
        Pass
        {
            Name "TransparentBackface"
            Tags { "LightMode" = "TransparentBackface" }

            Blend [_SrcBlend] [_DstBlend], [_AlphaSrcBlend] [_AlphaDstBlend]
            ZWrite [_ZWrite]
            Cull Front
            ColorMask [_ColorMaskTransparentVel] 1
            ZTest [_ZTestTransparent]

            HLSLPROGRAM

            #pragma only_renderers d3d11 ps4 xboxone vulkan metal switch

            //enable GPU instancing support
            #pragma multi_compile_instancing
            #pragma instancing_options renderinglayer

            #pragma multi_compile _ DEBUG_DISPLAY
            #pragma multi_compile _ LIGHTMAP_ON
            #pragma multi_compile _ DIRLIGHTMAP_COMBINED
            #pragma multi_compile _ DYNAMICLIGHTMAP_ON
            #pragma multi_compile _ SHADOWS_SHADOWMASK
            // Setup DECALS_OFF so the shader stripper can remove variants
            #pragma multi_compile DECALS_OFF DECALS_3RT DECALS_4RT

            // Supported shadow modes per light type
            #pragma multi_compile SHADOW_LOW SHADOW_MEDIUM SHADOW_HIGH

            #define USE_CLUSTERED_LIGHTLIST // There is not FPTL lighting when using transparent
			
			#define ATTRIBUTES_NEED_NORMAL

			#define VARYINGS_NEED_POSITION

			#pragma multi_compile _ VISUALIZE_DISPLACEMENT VISUALIZE_WIND VISUALIZE_LODS

            #define SHADERPASS SHADERPASS_FORWARD
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Material.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Lighting/Lighting.hlsl"

        #ifdef DEBUG_DISPLAY
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Debug/DebugDisplay.hlsl"
        #endif

            // The light loop (or lighting architecture) is in charge to:
            // - Define light list
            // - Define the light loop
            // - Setup the constant/data
            // - Do the reflection hierarchy
            // - Provide sampling function for shadowmap, ies, cookie and reflection (depends on the specific use with the light loops like index array or atlas or single and texture format (cubemap/latlong))

            #define HAS_LIGHTLOOP

            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Lighting/LightLoop/LightLoopDef.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Lit/Lit.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Lighting/LightLoop/LightLoop.hlsl"

            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Lit/ShaderPass/LitSharePass.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Lit/LitData.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/RenderPipeline/ShaderPass/ShaderPassForward.hlsl"

			#include "Grass_TesselationGeometry_Common.hlsl"
            #include "Grass_TesselationGeometry_Fragment.hlsl"
            #include "Grass_TesselationGeometry_Tesselation.hlsl"

		#ifdef DRAW_SOURCE_GEOMETRY
			#include "Grass_TesselationGeometry_GeometryPassthrough.hlsl"
		#else
			#include "Grass_TesselationGeometry_Geometry.hlsl"
		#endif

            #pragma vertex Vert
            #pragma fragment GrassFragment
            #pragma hull GrassHull
            #pragma domain GrassDomain
			#pragma geometry GrassGeometry

            ENDHLSL
        }

        Pass
        {
            Name "Forward"
            Tags { "LightMode" = "Forward" } // This will be only for transparent object based on the RenderQueue index

            Stencil
            {
                WriteMask [_StencilWriteMask]
                Ref [_StencilRef]
                Comp Always
                Pass Replace
            }

            Blend [_SrcBlend] [_DstBlend], [_AlphaSrcBlend] [_AlphaDstBlend]
            // In case of forward we want to have depth equal for opaque mesh
            ZTest [_ZTestDepthEqualForOpaque]
            ZWrite [_ZWrite]
            Cull [_CullModeForward]
            ColorMask [_ColorMaskTransparentVel] 1

            HLSLPROGRAM

            #pragma only_renderers d3d11 ps4 xboxone vulkan metal switch

            //enable GPU instancing support
            #pragma multi_compile_instancing
            #pragma instancing_options renderinglayer

			#define ATTRIBUTES_NEED_NORMAL

			#define VARYINGS_NEED_POSITION

			#pragma multi_compile _ VISUALIZE_DISPLACEMENT VISUALIZE_WIND VISUALIZE_LODS

            #pragma multi_compile _ DEBUG_DISPLAY
            #pragma multi_compile _ LIGHTMAP_ON
            #pragma multi_compile _ DIRLIGHTMAP_COMBINED
            #pragma multi_compile _ DYNAMICLIGHTMAP_ON
            #pragma multi_compile _ SHADOWS_SHADOWMASK
            // Setup DECALS_OFF so the shader stripper can remove variants
            #pragma multi_compile DECALS_OFF DECALS_3RT DECALS_4RT

            // Supported shadow modes per light type
            #pragma multi_compile SHADOW_LOW SHADOW_MEDIUM SHADOW_HIGH

            #pragma multi_compile USE_FPTL_LIGHTLIST USE_CLUSTERED_LIGHTLIST

            #define SHADERPASS SHADERPASS_FORWARD
            // In case of opaque we don't want to perform the alpha test, it is done in depth prepass and we use depth equal for ztest (setup from UI)
            // Don't do it with debug display mode as it is possible there is no depth prepass in this case
            #if !defined(_SURFACE_TYPE_TRANSPARENT) && !defined(DEBUG_DISPLAY)
                #define SHADERPASS_FORWARD_BYPASS_ALPHA_TEST
            #endif
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Material.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Lighting/Lighting.hlsl"

        #ifdef DEBUG_DISPLAY
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Debug/DebugDisplay.hlsl"
        #endif

            // The light loop (or lighting architecture) is in charge to:
            // - Define light list
            // - Define the light loop
            // - Setup the constant/data
            // - Do the reflection hierarchy
            // - Provide sampling function for shadowmap, ies, cookie and reflection (depends on the specific use with the light loops like index array or atlas or single and texture format (cubemap/latlong))

            #define HAS_LIGHTLOOP

            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Lighting/LightLoop/LightLoopDef.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Lit/Lit.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Lighting/LightLoop/LightLoop.hlsl"

            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Lit/ShaderPass/LitSharePass.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Lit/LitData.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/RenderPipeline/ShaderPass/ShaderPassForward.hlsl"

			#include "Grass_TesselationGeometry_Common.hlsl"
            //#include "Grass_TesselationGeometry_FragmentForward.hlsl"
            #include "Grass_TesselationGeometry_Tesselation.hlsl"
			#include "Grass_TesselationGeometry_FragmentForward.hlsl"

		#ifdef DRAW_SOURCE_GEOMETRY
			#include "Grass_TesselationGeometry_GeometryPassthrough.hlsl"
		#else
			#include "Grass_TesselationGeometry_Geometry.hlsl"
		#endif

            #pragma vertex Vert
            #pragma fragment Frag2
            #pragma hull GrassHull
            #pragma domain GrassDomain
			#pragma geometry GrassGeometry

            ENDHLSL
        }

        Pass
        {
            Name "TransparentDepthPostpass"
            Tags { "LightMode" = "TransparentDepthPostpass" }

            Cull[_CullMode]
            ZWrite On
            ColorMask 0

            HLSLPROGRAM

            #pragma only_renderers d3d11 ps4 xboxone vulkan metal switch

            //enable GPU instancing support
            #pragma multi_compile_instancing
            #pragma instancing_options renderinglayer
			
			#define ATTRIBUTES_NEED_NORMAL

			#define VARYINGS_NEED_POSITION

			#pragma multi_compile _ VISUALIZE_DISPLACEMENT VISUALIZE_WIND VISUALIZE_LODS

            #define SHADERPASS SHADERPASS_DEPTH_ONLY
            #define CUTOFF_TRANSPARENT_DEPTH_POSTPASS
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Material.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Lit/Lit.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Lit/ShaderPass/LitDepthPass.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Lit/LitData.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/RenderPipeline/ShaderPass/ShaderPassDepthOnly.hlsl"

			#include "Grass_TesselationGeometry_Common.hlsl"
            #include "Grass_TesselationGeometry_Fragment.hlsl"
            #include "Grass_TesselationGeometry_Tesselation.hlsl"
			
		#ifdef DRAW_SOURCE_GEOMETRY
			#include "Grass_TesselationGeometry_GeometryPassthrough.hlsl"
		#else
			#include "Grass_TesselationGeometry_Geometry.hlsl"
		#endif

            #pragma vertex Vert
            #pragma fragment Frag
            #pragma hull GrassHull
            #pragma domain GrassDomain
			#pragma geometry GrassGeometry

            ENDHLSL
        }
	}

    CustomEditor "Grass.Editor.GrassGUI"    
	//CustomEditor "Rendering.HighDefinition.LitGUI"
}
