#if defined(SHADER_API_XBOXONE) || defined(SHADER_API_PSSL)
// AMD recommand this value for GCN http://amd-dev.wpengine.netdna-cdn.com/wordpress/media/2013/05/GCNPerformanceTweets.pdf
#define MAX_TESSELLATION_FACTORS 15.0
#else
#define MAX_TESSELLATION_FACTORS 64.0
#endif

struct TessellationFactorsCust
{
    float edge[3] : SV_TessFactor;
    float inside : SV_InsideTessFactor;
};

float UnityDistanceFromPlane(float3 pos, float4 plane)
{
    return dot(float4(pos, 1), plane);
}

float GetDensity(float3 absoluteWorldPosition)
{
	int lod = GetLOD(absoluteWorldPosition);

	return lerp(_GrassLODDensities[lod], 0, lod > 2);
}

// Returns true if triangle with given 3 world positions is outside of camera's view frustum.
// cullEps is distance outside of frustum that is still considered to be inside (i.e. max displacement)
bool UnityWorldViewFrustumCull (float3 wpos0, float3 wpos1, float3 wpos2, float cullEps)
{
	float4 left = _FrustumPlanes[0];
	float4 right = _FrustumPlanes[1];
	float4 top = _FrustumPlanes[2];
	float4 bottom = _FrustumPlanes[3];

    // has to pass all 4 plane tests to be visible
    return !all(float4
	(
		// left
		(UnityDistanceFromPlane(wpos0, left) > 0) +
		(UnityDistanceFromPlane(wpos1, left) > 0) +
		(UnityDistanceFromPlane(wpos2, left) > 0),

		// right
		(UnityDistanceFromPlane(wpos0, right) > 0) +
        (UnityDistanceFromPlane(wpos1, right) > 0) +
        (UnityDistanceFromPlane(wpos2, right) > 0),

		// top
		(UnityDistanceFromPlane(wpos0, top) > 0) +
		(UnityDistanceFromPlane(wpos1, top) > 0) +
		(UnityDistanceFromPlane(wpos2, top) > 0),
	
		// bottom
		(UnityDistanceFromPlane(wpos0, bottom) > 0) +
		(UnityDistanceFromPlane(wpos1, bottom) > 0) +
		(UnityDistanceFromPlane(wpos2, bottom) > 0)
	));
}

TessellationFactorsCust HullConstantC(InputPatch<PackedVaryingsToDS, 3> input)
{
	TessellationFactorsCust output;

    // don't do anything if it's the shadow pass and we're not casting shadows
#if !defined(CAST_SHADOWS) && SHADERPASS == SHADERPASS_SHADOWS
    output.edge[0] = 0;
    output.edge[1] = 0;
    output.edge[2] = 0;
    output.inside  = 0;
	return output;
#else

	VaryingsToDS varying0 = UnpackVaryingsToDS(input[0]);
    VaryingsToDS varying1 = UnpackVaryingsToDS(input[1]);
    VaryingsToDS varying2 = UnpackVaryingsToDS(input[2]);

    float3 p0 = varying0.vmesh.positionRWS;
    float3 p1 = varying1.vmesh.positionRWS;
    float3 p2 = varying2.vmesh.positionRWS;
	
	float density = clamp(GetDensity(GetAbsolutePositionWS(p0)), 0, MAX_TESSELLATION_FACTORS);
	
#ifdef FRUSTUM_CULLING
	if (UnityWorldViewFrustumCull(p0, p1, p2, _FrustumCullingScreenSpaceMargin))
	{
		output.edge[0] = 0;
		output.edge[1] = 0;
		output.edge[2] = 0;
		output.inside  = 0;
		return output;
	}
#endif

#ifdef PROPORTIONAL_TESSELATION
	float length12 = distance(p1, p2) * density;
	float length20 = distance(p2, p0) * density;
	float length01 = distance(p0, p1) * density;

	// ref: https://catlikecoding.com/unity/tutorials/advanced-rendering/tessellation/

    output.edge[0] = length12;
    output.edge[1] = length20;
    output.edge[2] = length01;
    output.inside  = (length12 + length20 + length01) * 0.333;
#else
    output.edge[0] = density;
    output.edge[1] = density;
    output.edge[2] = density;
    output.inside  = density;
#endif

    return output;
#endif
}

[maxtessfactor(MAX_TESSELLATION_FACTORS)]
[domain("tri")]
//[partitioning("fractional_odd")]
[partitioning("integer")]
[outputtopology("triangle_cw")]
[patchconstantfunc("HullConstantC")]
[outputcontrolpoints(3)]
PackedVaryingsToDS GrassHull(InputPatch<PackedVaryingsToDS, 3> input, uint id : SV_OutputControlPointID)
{
    // Pass-through
    return input[id];
}

[domain("tri")]
PackedVaryingsToPS GrassDomain(TessellationFactorsCust tessFactors, const OutputPatch<PackedVaryingsToDS, 3> input, float3 baryCoords : SV_DomainLocation)
{
    VaryingsToDS varying0 = UnpackVaryingsToDS(input[0]);
    VaryingsToDS varying1 = UnpackVaryingsToDS(input[1]);
    VaryingsToDS varying2 = UnpackVaryingsToDS(input[2]);

    VaryingsToDS varying = InterpolateWithBaryCoordsToDS(varying0, varying1, varying2, baryCoords);

//#ifdef HAVE_TESSELLATION_MODIFICATION
//    ApplyTessellationModification(varying.vmesh, varying.vmesh.normalWS, varying.vmesh.positionRWS);
//#endif

   return VertTesselation(varying);
}
