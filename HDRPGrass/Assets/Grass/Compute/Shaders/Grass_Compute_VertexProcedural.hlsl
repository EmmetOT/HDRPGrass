#include "Grass_Compute_CommonStructs.hlsl"

StructuredBuffer<GrassBladeTriangle> _OutMesh;

PackedVaryingsType ToPackedVaryingsType(AttributesMesh inputMesh)
{
    VaryingsType varyingsType;
    varyingsType.vmesh = VertMesh(inputMesh);
    return PackVaryingsType(varyingsType);
}


// Vertex input attributes
struct Attributes
{
    uint vertexID : SV_VertexID;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

AttributesMesh GrassToAttributesMesh(Attributes input, GrassBladeVertex vertex, GrassBladeTriangle tri)
{
            // Imitate a common vertex vertex.
    AttributesMesh am;
    am.positionOS = vertex.positionOS;
    
#ifdef ATTRIBUTES_NEED_NORMAL
    am.normalOS = float3(0, 1, 0);//vertex.normalOS;
#endif
#ifdef ATTRIBUTES_NEED_TANGENT
    am.tangentOS = 0;
#endif
//#ifdef ATTRIBUTES_NEED_TEXCOORD0
    am.uv0 = vertex.uv;
//#endif
//#ifdef ATTRIBUTES_NEED_TEXCOORD1
    am.uv1 = tri.space.uv;
//#endif
#ifdef ATTRIBUTES_NEED_TEXCOORD2
    am.uv2 = 0;
#endif
#ifdef ATTRIBUTES_NEED_TEXCOORD3
    am.uv3 = 0;
#endif
#ifdef ATTRIBUTES_NEED_COLOR
    am.color = 0;
#endif
    UNITY_TRANSFER_INSTANCE_ID(input, am);
    
    return am;
}

// in 'procedural mode', the vertex data comes from a graphics.drawprocedural
PackedVaryingsType GrassVertex(Attributes input)
{
    int vertexID = input.vertexID;
    
    // get the vertex from the buffer.
    // since the buffer is triangles, we need to divide the vertex ID by 3
    // to get the triangle, and then modulo by 3 to get the specific vertex on that triangle.
    GrassBladeTriangle tri = _OutMesh[vertexID / 3];
    GrassBladeVertex vertex = tri.points[vertexID % 3];
    
    float3 grassBladeOrigin = tri.space.positionOS;
    float3 grassBladeVertexPos = vertex.positionOS;
    float height = vertex.uv.y;
    
    vertex.positionOS = ApplyWindAndDisplacementOS(grassBladeOrigin, grassBladeVertexPos, height);
    
    // convert the data into a form HDRP understands
    return ToPackedVaryingsType(GrassToAttributesMesh(input, vertex, tri));
}