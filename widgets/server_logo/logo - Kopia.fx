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
texture gOrigTexure0 : TEXTURE0;
texture gCustomTex0 : CUSTOMTEX0;
float2 g_Pos;
float2 g_ScrSize;

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
//-- VertexShaderExample
//--  1. Read from VS structure
//--  2. Process
//--  3. Write to PS structure
//-----------------------------------------------------------------------------
PSInput LogoVertexShader(VSInput VS)
{
    PSInput PS = (PSInput)0;
	
    //-- Transform vertex position
	float angle = Time / 2.0f;
	float s = sin(angle);
    float c = cos(angle);
	
	float4x4 matScale = {
		0.1, 0, 0, 0,
		0, 0.1, 0, 0,
		0, 0, 0.1, 0,
		0, 0, 0, 1};
	float4x4 matRot = {
		c, 0, -s, 0,
		0, 1, 0, 0,
		s, 0, c, 0,
		0, 0, 0, 1};
	float4x4 matScale2 = {
		10, 0, 0, 0,
		0, 10, 0, 0,
		0, 0, 10, 0,
		0, 0, 0, 1};
	float4x4 matTrans = {
		1, 0, 0, 0,
		0, 1, 0, 0,
		0, 0, 1, 0,
		g_Pos.x, g_Pos.y, 0, 1};
	float4x4 matTrans2 = {
		1, 0, 0, 0,
		0, 1, 0, 0,
		0, 0, 1, 0,
		1, -1, 0, 1};
	float4x4 matView = {
		1, 0, 0, 0,
		0, 1, 0, 0,
		0, 0, 1, 0,
		0, 0, 1000, 1};
	
	float w = 1, h = 0.7, zn = 0.2, zf = 5000;
	float4x4 matProj = {
		2*zn/w, 0, 0, 0,
		0, 2*zn/h, 0, 0,
		0, 0, zf/(zf-zn), 1,
		0, 0, zn*zf/(zn-zf), 0};
	/*float4x4 matProj = {
		2/w, 0, 0, 0,
		0, 2/h, 0, 0,
		0, 0, -1/(zf-zn), 0,
		0, 0, zn/(zf-zn), 1};*/
	
	float4 pos = float4(VS.Position, 1);
	// Note: pos.z == 0
	//pos.z = 1000;
	
	
		//pos = mul(pos, matScale);
	pos = mul(pos, matRot);
	pos.x += g_ScrSize.x / 2.0f;
	pos.y += g_ScrSize.y / 2.0f;
	//pos = mul(pos, matScale2);
	//pos = mul(pos, matTrans);
	
		//pos = mul(pos, World);
	matView = View;
	matView[3] = float4(0, 0, 1000, 1);
	
	// Projection
	// 1.19x 0.0   0.0   0.0
	// 0.0   -1.9x 0.0   0.0
	// 0.0   0.0   1.01x 1.0
	// -1000 1000 -101.x 0.0
	
	pos = mul(pos, matView);
		//pos = mul(pos, matTrans);
	
	matProj = Projection;
	//matProj[2][3] = 0;
	//matProj[3][3] = 1;
	
	pos = mul(pos, matProj);
		//pos = mul(pos, matTrans2);
	
	// max(pos.z) = 97x
	// pos.w = 10xx
	
	pos.xyzw /= pos.w/100;
	
	pos.x += 0.8; //(g_Pos.x - g_ScrSize.x / 2)/g_ScrSize.x*2000;
	pos.y += 0.8; //(g_Pos.y - g_ScrSize.y / 2)/g_ScrSize.y*2000;
	
	PS.Position = pos;
	
	
	//PS.Position = mul(mul(float4(VS.Position, 1), matRot), WorldViewProjection);
	
    //-- Copy the color and texture coords so the pixel shader can use them
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
        Texture[0] = gCustomTex0;

		// Set vertex shader
		VertexShader = compile vs_2_0 LogoVertexShader();
    }
}

technique fallback
{
    pass P0
    {
    }
}
