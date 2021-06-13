#ifndef GRASS_COMPUTE_COMMONSTRUCTS
#define GRASS_COMPUTE_COMMONSTRUCTS

// information about a specific grass vertex
struct GrassBladeVertex
{
    float3 positionOS;
    float2 uv;
};

// contains data for each blade of grass' local space.
struct GrassBladeSpaceData
{
    float3 positionOS;
    float3 normalOS;
    float3 tangentOS;
    float3 bitangentOS;
    float2 uv;
    
    float3x3 GetTangentToLocal()
    {
        return float3x3
	    (
		    tangentOS.x, bitangentOS.x, normalOS.x,
		    tangentOS.y, bitangentOS.y, normalOS.y,
		    tangentOS.z, bitangentOS.z, normalOS.z
	    );
    }
};

// this struct contains information about one entire blade of grass, ready 
// to be sent for rendering
struct GrassBladeTriangle
{
    GrassBladeVertex points[3];
    GrassBladeSpaceData space;
};

#endif // GRASS_COMPUTE_COMMONSTRUCTS