#define MAX_SEGMENTS 10


int GetSegmentCount(float3 absoluteWorldPosition)
{
	int lod = GetLOD(absoluteWorldPosition);

	if (lod > 2)
		return 0;

	return _GrassLODSegments[lod];
}

PackedVaryingsToPS GenerateGrass(PackedVaryingsToPS base, float3 vertexPosition, float3 displacement, float width, float height, float forward, float2 uv, float2 originalUVs, float3 worldUp, float3 tangent, float3x3 transformMatrix)
{
	PackedVaryingsToPS result = base;

	vertexPosition += displacement;
	
	float3 _2dPoint = float3(width, forward, height);
	float3 tangentNormal = normalize(float3(0, -1, forward));
	float3 localNormal = mul(transformMatrix, tangentNormal);
	
    float3 localPosition = mul(transformMatrix, _2dPoint);
    
#ifdef NORMAL_TYPE_TRUE
	float3 normal = TransformObjectToWorldNormal(localNormal);
#else
    float3 normal = worldUp;
#endif
    
#ifdef BILLBOARD
    float projectedAngle = GetProjectedAngle(vertexPosition, float3(0, 0, 0), worldUp, tangent);
    float3x3 projectedRot = AngleAxis3x3(PI * 0.5 + projectedAngle, worldUp);
    
    float3 worldPosition = vertexPosition + mul(projectedRot, localPosition);
#else
    float3 worldPosition = vertexPosition + localPosition;
#endif
    
    // set position in world space
    SetPosition(result, worldPosition);
	SetUV0(result, uv);
	SetUV1(result, originalUVs);
	SetNormal(result, normal);

	return result;
}

// Attributes -> VaryingsToPS

[maxvertexcount(2 * (MAX_SEGMENTS * 2 + 1))]
void GrassGeometry(triangle PackedVaryingsToPS input[3], uint pid : SV_PrimitiveID, inout TriangleStream<PackedVaryingsToPS> outStream)
{
	PackedVaryingsToPS ps0 = input[0];
	PackedVaryingsToPS ps1 = input[1];
	PackedVaryingsToPS ps2 = input[2];

	// we get all the information about the first vertex of the triangle.
	// it's pretty much arbitrary that we use the first, we could use all three
	// vertices to get more accurate results but the tris are small enough that it should
	// be negligible.
	float3 position0 = GetPosition(ps0);
	float3 absolutePosition0 = GetAbsolutePositionWS(position0);

	int segmentCount = GetSegmentCount(absolutePosition0);

	if (segmentCount == 0)
		return;

	float3 normal0 = GetNormal(ps0);
	float4 tangent0 = GetTangent(ps0);
	float2 uv0 = GetUV0(ps0);
	float3 binormal0 = cross(normal0, tangent0.xyz) * tangent0.w;

	float3x3 tangentToLocal = float3x3
	(
		tangent0.x, binormal0.x, normal0.x,
		tangent0.y, binormal0.y, normal0.y,
		tangent0.z, binormal0.z, normal0.z
	);

    float3 idSeed = float3(pid, pid, pid);
    
	// randomly divide 1.0 in 3 ways in order to position the grass blade randomly on the tri
    half rand0 = smoothRand(absolutePosition0.yyz);
    half rand1 = smoothRand(absolutePosition0.yxz);
    half rand2 = smoothRand(absolutePosition0.xxz);
	half sum = rand0 + rand1 + rand2;

	half part0 = lerp(0.3333, rand0 / sum, _GrassOffset);
	half part1 = lerp(0.3333, rand1 / sum, _GrassOffset);
	half part2 = lerp(0.3333, rand2 / sum, _GrassOffset);
	
	float3 position = part0 * position0 + part1 * GetPosition(ps1) + part2 * GetPosition(ps2);
    float3 originalNormal = normal0;// part0 * normal0 + part1 * GetNormal(ps1) + part2 * GetNormal(ps2);
	half4 color = GetColor(ps0);//part0 * GetColor(ps0) + part1 * GetColor(ps1) + part2 * GetColor(ps2);

	half polybrush = color.r;

	// sampling from the grass map to scale the grass blades by the red channel at this position
	float2 grassMapUV = uv0 * _GrassMap_ST.xy + _GrassMap_ST.zw;
	float grassMapScale = tex2Dlod(_GrassMap, float4(grassMapUV, 0, 0)).r;
	
    half height = ((smoothRand(absolutePosition0.zyx) * 2 - 1) * _BladeHeightRandom + _BladeHeight) * grassMapScale * polybrush;
    half width = ((smoothRand(absolutePosition0.xzy) * 2 - 1) * _BladeWidthRandom + _BladeWidth) * grassMapScale * polybrush;

	if (height <= 0 || width <= 0)
		return;

    half forward = smoothRand(absolutePosition0.yzx) * _BladeForward;
    
	//////////////// WIND
	float2 windUV = absolutePosition0.xz * _WindDistortionMap_ST.xy + _WindDistortionMap_ST.zw + _WindFrequency * _Time.y;
	float2 windSample = (tex2Dlod(_WindDistortionMap, float4(windUV, 0, 0)).rg * 2 - 1) * max(0.000001, abs(_WindStrength));
	half3 wind = normalize(float3(windSample.x, windSample.y, 0));
	float3x3 windRotation = AngleAxis3x3(PI * length(windSample), wind);
	////////////////
    
#ifndef BILLBOARD
    float3x3 bendRotationMatrix = AngleAxis3x3(smoothRand(absolutePosition0.zzx) * _BendRotationRandom * PI * 0.5, float3(-1, 0, 0));
    float3x3 facingRotationMatrix = AngleAxis3x3(DegToRad(smoothRand(absolutePosition0) * _BladeRotationRange), float3(0, 0, 1));
    
    float3x3 transformationMatrix = mul(mul(mul(tangentToLocal, windRotation), facingRotationMatrix), bendRotationMatrix);
    float3x3 transformationMatrixFacing = mul(tangentToLocal, facingRotationMatrix);
#else
    float3x3 transformationMatrix = mul(tangentToLocal, windRotation);
    float3x3 transformationMatrixFacing = tangentToLocal;
#endif
    
	//////////////// DISPLACEMENT SPHERES

	half3 totalSphereDisp = float3(0, 0, 0);
#ifdef APPLY_DISPLACEMENT
	for	(int i = 0; i < _GrassDisplacementSpheresBufferCount; i++)
	{
		half3 sphereDisp = float3(0, 0, 0);

		GrassDisplacement displacementData =_GrassDisplacementSpheresBuffer[i];
		half3 displacerPos = displacementData.position;

		half3 distance = length(displacerPos - absolutePosition0);
		half3 circle = 1 - saturate(distance * displacementData.inverseRadius);

		sphereDisp += (absolutePosition0 - displacerPos) * circle;
		sphereDisp = clamp(sphereDisp.xyz * displacementData.power, -0.8, 0.8);

		totalSphereDisp += sphereDisp;
	}
#endif
	////////////////

	for (int j = 0; j < segmentCount; j++)
	{
		float t = j / (float)segmentCount;

		half segmentHeight = height * t;
        half segmentWidth = width;
        
#ifndef GENERATE_QUADS
        segmentWidth *= (1 - t);
#endif
        
		half segmentForward = pow(abs(t), _BladeCurve) * forward;

		float3x3 transformMatrix = j == 0 ? transformationMatrixFacing : transformationMatrix;
		half3 displacement = j == 0 ? float3(0, 0, 0) : totalSphereDisp;

#ifdef VISUALIZE_WIND
		float2 uvLeft = uv0;
		float2 uvRight = uv0;
#else
		float2 uvLeft = float2(0, t);
		float2 uvRight = float2(1, t);
#endif

        outStream.Append(GenerateGrass(ps0, position, displacement, segmentWidth, segmentHeight, segmentForward, uvLeft, uv0, originalNormal, tangent0, transformMatrix));
        outStream.Append(GenerateGrass(ps0, position, displacement, -segmentWidth, segmentHeight, segmentForward, uvRight, uv0, originalNormal, tangent0, transformMatrix));
    }

#ifdef VISUALIZE_WIND
		float2 uv = uv0;
#else
		float2 uv = float2(0.5, 1);
#endif

#ifndef GENERATE_QUADS
	// the tip of the grass blade
	outStream.Append(GenerateGrass(ps0, position, float3(totalSphereDisp.x * 1.5, totalSphereDisp.y, totalSphereDisp.z * 1.5), 0, height, forward, float2(0.5, 1), uv0, originalNormal, tangent0, transformationMatrix));
#else
    // the tip of the grass quad
	outStream.Append(GenerateGrass(ps0, position, float3(totalSphereDisp.x * 1.5, totalSphereDisp.y, totalSphereDisp.z * 1.5), width, height, forward, float2(0, 1), uv0, originalNormal, tangent0, transformationMatrix));
	outStream.Append(GenerateGrass(ps0, position, float3(totalSphereDisp.x * 1.5, totalSphereDisp.y, totalSphereDisp.z * 1.5), -width, height, forward, float2(1, 1), uv0, originalNormal, tangent0, transformationMatrix));
#endif
    
    outStream.RestartStrip();
}