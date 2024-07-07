float4x4 WorldView;
float4x4 WorldViewProjection;

struct VS_IN
{
	float4 Position : POSITION0;
};

struct PS_IN
{
    float4 Position : POSITION0;
	float Depth     : TEXCOORD0;
};

PS_IN VS( VS_IN input )
{
	PS_IN output;
	
    // Transform the position into screen space.
    output.Position = mul(input.Position, WorldViewProjection);

    // Record the depth value to pass to the pixel shader
    //output.Depth = output.Position.z / output.Position.w; //always pure white mostly..
    float4 ViewSpacePos = mul(input.Position, WorldView);
    output.Depth = ViewSpacePos.z/10000.0f;
	
	return output;
}

float4 PS( PS_IN input ) : COLOR0
{
	return float4(input.Depth, input.Depth, input.Depth, 1);
}

technique Render
{
	pass Pass0
	{
		VertexShader = compile vs_3_0 VS();
        PixelShader = compile ps_3_0 PS();
        CullMode = ccw;
        AlphaBlendEnable = FALSE;
        AlphaTestEnable = FALSE;
		ZEnable = TRUE;
        ZWriteEnable = TRUE;
	}
}