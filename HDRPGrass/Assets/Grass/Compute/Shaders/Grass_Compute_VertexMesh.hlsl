// in 'mesh mode' the data just comes from a standard mesh
// todo: write the 'grass origin' into one of the UV channels
PackedVaryingsType GrassVertex(AttributesMesh inputMesh)
{
    float3 grassBladeOrigin = float3(inputMesh.uv2.x, inputMesh.uv2.y, inputMesh.uv3.x);
    float3 grassBladeVertexPos = inputMesh.positionOS;
    float height = inputMesh.uv0.y;
    
    inputMesh.positionOS = TransformWorldToObject(GetCameraRelativePositionWS(ApplyWindAndDisplacementOS(grassBladeOrigin, grassBladeVertexPos, height)));
    
    VaryingsType varyingsType;
    varyingsType.vmesh = VertMesh(inputMesh);
    return PackVaryingsType(varyingsType);
}