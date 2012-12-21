//
// Server logo shader
//

//-- These variables are set automatically by MTA
float4x4 World;
float4x4 View;
float4x4 Projection;
float4x4 WorldViewProjection;
float Time;

///////////////////////////////////////////////////////////////////////////////
// Global variables
///////////////////////////////////////////////////////////////////////////////
float2 g_Pos;
float2 g_ScrSize;
texture g_Texture;
float g_fAngle;

//---------------------------------------------------------------------
//-- Structure of data sent to the vertex shader
//---------------------------------------------------------------------
struct VSInput
{
    float3 Position : POSITION;
    float4 Diffuse  : COLOR0;
    float2 TexCoord : TEXCOORD0;
};
 
//---------------------------------------------------------------------
//-- Structure of data sent to the pixel shader ( from the vertex shader )
//---------------------------------------------------------------------
struct PSInput
{
  float4 Position : POSITION0;
  float4 Diffuse  : COLOR0;
  float2 TexCoord : TEXCOORD0;
};

//-----------------------------------------------------------------------------
// LogoVertexShader
//  1. Read from VS structure
//  2. Process
//  3. Write to PS structure
//-----------------------------------------------------------------------------
PSInput LogoVertexShader(VSInput VS)
{
    PSInput PS = (PSInput)0;
	
    // Transform vertex position
	float4 pos = float4(VS.Position, 1);
	
	// Move to orgin
	pos.x -= g_Pos.x;
	pos.y -= g_Pos.y;
	
	// Rotate
	float s = sin(g_fAngle);
    float c = cos(g_fAngle);
	
	float4x4 matRot = {
		c, 0, -s, 0,
		0, 1, 0, 0,
		s, 0, c, 0,
		0, 0, 0, 1};
	
	pos = mul(pos, matRot);
	
	// Move to the center of the screen
	pos.x += g_ScrSize.x / 2.0f;
	pos.y += g_ScrSize.y / 2.0f;
	
	// Transform
	pos = mul(pos, WorldViewProjection);
	
	// Normalize W
	pos.xyzw /= pos.w;
	
	// Move to the proper place
	pos.x += g_Pos.x/g_ScrSize.x*2 - 1;
	pos.y -= g_Pos.y/g_ScrSize.y*2 - 1;
	
    // Copy to output
	PS.Position = pos;
    PS.Diffuse = VS.Diffuse;
    PS.TexCoord = VS.TexCoord;
	
    return PS;
}


///////////////////////////////////////////////////////////////////////////////
// Techniques
///////////////////////////////////////////////////////////////////////////////
technique main
{
    pass P0
    {
        // Set the texture
        Texture[0] = g_Texture;
		
		// Set vertex shader
		VertexShader = compile vs_2_0 LogoVertexShader();
    }
}

technique fallback
{
    pass P0
    {
		// Only set the texture
        Texture[0] = g_Texture;
    }
}
