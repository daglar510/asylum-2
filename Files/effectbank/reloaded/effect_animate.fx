string Description = "Effect Animate Shader";

float4x4 World : WORLD;
float4x4 WorldViewProj : WorldViewProjection;
float4x4 WorldIT : WorldInverseTranspose;
float4x4 ViewInv : ViewInverse;
float4 eyePos : CameraPosition;
float Time: Time;
float sintime : SinTime;

float SpriteRows : Power
<
    string UIName =  "Rows";
    string UIWidget = "slider";
    float UIMin = 1.0;
    float UIMax = 16.0;
    float UIStep = 1.0;
> = 8.000000;

float SpriteColumns : Power
<
    string UIName =  "Columns";
    string UIWidget = "slider";
    float UIMin = 1.0;
    float UIMax = 16.0;
    float UIStep = 1.0;
> = 8.000000;

float FramesPerSec : Power
<
    string UIName =  "Frames Per Second";
    string UIWidget = "slider";
    float UIMin = 0.0;
    float UIMax = 30.0;
    float UIStep = 0.5;
    
> = 25.000000;

float Looptime : Power
<
    string UIName =  "Loop Time";
    string UIWidget = "slider";
    float UIMin = 1.0;
    float UIMax = 200.0;
    float UIStep = 1.0;
> = 100.000000;

float4 AmbiColor : Ambient
<
    string UIName =  "Ambient Light Color";
> = { 0.010000, 0.010000, 0.010000, 1.000000 };

float4 SurfColor : Diffuse
<
    string UIName =  "Surface Color";
    string UIType = "Color";
> = { 0.050000, 0.050000, 0.050000, 1.000000 };

texture DiffuseMap : DiffuseMap
<
    string Name = "D.dds";
    string type = "2D";
    string ResourceName = ""; 
>;
texture OcclusionMap : DiffuseMap
<
    string Name = "O.dds";
    string type = "2D";
    string ResourceName = ""; 
>;
texture SpriteMap : DiffuseMap
<
    string Name = "N.dds";
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
sampler2D OcclusionSampler = sampler_state
{
    Texture   = <OcclusionMap>;
    MipFilter = LINEAR;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
};
sampler2D SpriteSampler = sampler_state
{
    Texture   = <SpriteMap>;
    MipFilter = LINEAR;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
};

struct appdata 
{
    float4 Position	: POSITION;
    float4 UV0		: TEXCOORD0;
    float4 UV1		: TEXCOORD1;
    float4 Normal	: NORMAL;
};

struct vertexOutput
{
    float4 Position    : POSITION;
    float2 TexCoord    : TEXCOORD0;
    float2 TexCoordLM  : TEXCOORD1;
    float3 WorldNormal : TEXCOORD3;
    float4 WPos        : TEXCOORD4;
    float2 atlasUV     :TEXCOORD5;
};

vertexOutput mainVS(appdata IN)   
{
	vertexOutput OUT;
    
    float4 worldSpacePos = mul(IN.Position, World);
    
    OUT.WorldNormal = normalize(mul(IN.Normal, WorldIT).xyz);
    OUT.Position = mul(IN.Position, WorldViewProj);
    OUT.TexCoord  = IN.UV0; 
    OUT.TexCoordLM  = IN.UV1; 
    OUT.WPos =   worldSpacePos;   
    
	float2 DimensionsXY = float2(SpriteRows,SpriteColumns); 
	float2 atlasUVtemp = IN.UV0; 				
	float loopcounter  = floor(Time/Looptime);
	float offset = Looptime*loopcounter;
	float speed =(Time*FramesPerSec) - (offset*FramesPerSec);
	float index = floor( speed);
	float rowCount = floor( (index / DimensionsXY.y) );
	float2 offsetVector = float2(index, rowCount);
	float2 atlas = (1.0 / DimensionsXY) ;
	float2 move = (offsetVector + atlasUVtemp);
	
	OUT.atlasUV = (atlas.xy *move);

    return OUT;
}

float4 mainPS(vertexOutput IN) : COLOR
{
    float4 diffuse = tex2D(DiffuseSampler,IN.TexCoord.xy);
    float4 diffuseContrib = (diffuse*SurfColor) + (diffuse*AmbiColor);
    float4 spriteContrib = tex2D(SpriteSampler,IN.atlasUV.xy);
	float4 result = diffuseContrib + spriteContrib;
	result.a = spriteContrib.a; // * ((result.x+result.y+result.z)/3.0); // defeats strong alpha on lesser colours
    return result;
}

technique All
{
    pass P0
    {
        VertexShader = compile vs_3_0 mainVS();
        PixelShader  = compile ps_3_0 mainPS();
        Lighting         = FALSE;
        FogEnable        = FALSE;
        AlphaBlendEnable = TRUE;
		ZWriteEnable     = FALSE;
    }
}
