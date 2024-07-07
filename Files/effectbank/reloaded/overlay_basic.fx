string Description = "Overlay Shader";

float4x4 World : World;
float4x4 WorldView : WorldView;
float4x4 WorldViewProj : WorldViewProjection;

float4 ColorTone[1] : Diffuse
<   string UIName =  "Color Tone";    
> = {
   float4(1.0f, 1.0f, 1.0f, 1.0f),
};

// RENDERCOLORTARGET simply indicates that we are using an RT (depth texture at bottom)
texture DiffuseMap : RENDERCOLORTARGET
<
    string Name = "D.dds";
    string type = "2D";
    string ResourceName = ""; 
>;

sampler2D DiffuseSampler = sampler_state
{
    Texture   = <DiffuseMap>;
    MipFilter = LINEAR;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
};

struct appdata 
{
    float4 Position   : POSITION;
    float4 UV      : TEXCOORD0;
    float4 Normal   : NORMAL;
};

struct vertexOutput
{
    float4 Position    : POSITION;
    float2 UV          : TEXCOORD0;
    float4 WPos        : TEXCOORD1;
	float vDepth       : TEXCOORD2;
};

vertexOutput mainVS(appdata IN)   
{
   vertexOutput OUT;
   float4 tempPos = mul(IN.Position, WorldViewProj);
   OUT.Position = tempPos;
   OUT.UV = IN.UV;
   OUT.WPos = float4(mul(IN.Position, World).xyz,7000-mul(IN.Position, WorldView).z);
   OUT.vDepth = tempPos.z;
   return OUT;
}

float4 mainPS(vertexOutput IN) : COLOR
{
    float4 diffuse = tex2D(DiffuseSampler,IN.UV.xy);
    return diffuse * ColorTone[0];
}

float4 mainPS_renderdepth(vertexOutput IN) : COLOR
{
   clip(-1);
   return IN.WPos.wxyz;
}

float4 blackPS(vertexOutput IN) : COLOR
{
   if( tex2D(DiffuseSampler,IN.UV.xy).a < 1.0f ) 
   {
       clip(-1);
	   return IN.vDepth;
   }
   return IN.vDepth;
}

technique Highest
{
   pass RenderDepthPixelsPass
   <
      string RenderColorTarget = "[depthtexture]";
   >
   {
      VertexShader = compile vs_3_0 mainVS();
      PixelShader  = compile ps_3_0 mainPS_renderdepth();
      AlphaTestEnable = false;
   }
   pass MainPass
   <
      string RenderColorTarget = "";
   >
   {
      VertexShader = compile vs_3_0 mainVS();
      PixelShader  = compile ps_3_0 mainPS();
      Lighting         = false;
      FogEnable        = false;
      AlphaBlendEnable = true;
      AlphaTestEnable  = false;
      ZWriteEnable     = false;
   }
}

technique Medium
{
   pass RenderDepthPixelsPass
   <
      string RenderColorTarget = "[depthtexture]";
   >
   {
      VertexShader = compile vs_3_0 mainVS();
      PixelShader  = compile ps_3_0 mainPS_renderdepth();
      AlphaTestEnable = false;
   }
   pass MainPass
   <
      string RenderColorTarget = "";
   >
   {
      VertexShader = compile vs_3_0 mainVS();
      PixelShader  = compile ps_3_0 mainPS();
      Lighting         = false;
      FogEnable        = false;
      AlphaBlendEnable = true;
      AlphaTestEnable  = false;
      ZWriteEnable     = false;
   }
}

technique Lowest
{
   pass RenderDepthPixelsPass
   <
      string RenderColorTarget = "[depthtexture]";
   >
   {
      VertexShader = compile vs_3_0 mainVS();
      PixelShader  = compile ps_3_0 mainPS_renderdepth();
      AlphaTestEnable = false;
   }
   pass MainPass
   <
      string RenderColorTarget = "";
   >
   {
      VertexShader = compile vs_3_0 mainVS();
      PixelShader  = compile ps_3_0 mainPS();
      Lighting         = false;
      FogEnable        = false;
      AlphaBlendEnable = true;
      AlphaTestEnable  = false;
      ZWriteEnable     = false;
   }
}

technique DepthMap
{
    pass p0
    {      
        VertexShader = compile vs_2_0 mainVS();
        PixelShader  = compile ps_2_0 blackPS();
        CullMode = CCW;
        AlphaBlendEnable = false;
        AlphaTestEnable = false;
   }
}

