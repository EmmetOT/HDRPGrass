[maxvertexcount(3)]
void GrassGeometry(triangle PackedVaryingsToPS input[3], uint pid : SV_PrimitiveID, inout TriangleStream<PackedVaryingsToPS> outStream)
{
    outStream.Append(input[0]);
    outStream.Append(input[1]);
    outStream.Append(input[2]);

    outStream.RestartStrip();
}