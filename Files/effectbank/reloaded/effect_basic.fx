string Description = "Effect Shader";
#include "settings.fx"
// shadow mapping
matrix          m_mShadow;
float4          m_vCascadeOffset[8];
float4          m_vCascadeScale[8];
int             m_nCascadeLevels;
float           m_fMinBorderPadding;     
float           m_fMaxBorderPadding;
float           m_fShadowBiasFromGUI;  // A shadow map offset to deal with self shadow artifacts.  
float           m_fCascadeBlendArea; // Amount to overlap when blending between cascades.
float           m_fTexelSize; 
float           m_fCascadeFrustumsEyeSpaceDepths[8];
float3          m_vLightDir;

float ShadowStrength
<    string UIName =  "ShadowStrength";    
> = {1.0f};

// standard constants
float4x4 World : World;
float4x4 WorldInverse : WorldInverse;
float4x4 WorldIT : WorldInverseTranspose;
float4x4 WorldView : WorldView;
float4x4 WorldViewProjection : WorldViewProjection;
float4x4 View : View;
float4x4 ViewInverse : ViewInverse;
float4x4 ViewIT : ViewInverseTranspose;
float4x4 ViewProjection : ViewProjection;
float4x4 Projection : Projection;

float4 eyePos : CameraPosition;
float time : Time;
float sintime : SinTime;
float m_fClippingOnState = 1;

/**************VALUES PROVIDED FROM FPSC - NON TWEAKABLE**************************************/

float4 clipPlane : ClipPlane;  //cliplane for water plane

float4 LightSource
<   string UIType = "Fixed Light Direction";
> = {-1.0f, -1.0f, -1.0f, 1.0f};

//SpotFlash Values from FPSC (SpotFlashPos.w is carrying the spotflash fadeout value + SpotFlashColor.w carries FlashLightStrength)
float4 SpotFlashPos;
float4 SpotFlashColor;

float4 FogColor : Diffuse
<   string UIName =  "Fog Color";    
> = {0.0f, 0.0f, 0.0f, 0.0000001f};

float4 HudFogColor : Diffuse
<   string UIName =  "Hud Fog Color";    
> = {0.0f, 0.0f, 0.0f, 0.0000001f};

float4 HudFogDist : Diffuse
<   string UIName =  "Hud Fog Dist";    
> = {1.0f, 0.0f, 0.0f, 0.0000001f};

float4 AmbiColorOverride
<    string UIName =  "AmbiColorOverride";    
> = {1.0f, 1.0f, 1.0f, 1.0f};

float4 AmbiColor : Ambient
<    string UIName =  "AmbiColor";    
> = {0.1f, 0.1f, 0.1f, 1.0f};

float4 SurfColor : Diffuse
<    string UIName =  "SurfColor";    
> = {1.0f, 1.0f, 1.0f, 1.0f};

float alphaoverride  : alphaoverride;

float4 EntityEffectControl
<    string UIName =  "EntityEffectControl";    
> = {0.0f, 0.0f, 0.0f, 0.0f};

//Shader Variables pulled from FPI scripting 
float4 ShaderVariables : ShaderVariables
<    string UIName =  "Shader Variables";    
> = {1.0f, 1.0f, 1.0f, 1.0f};

//Supports dynamic lights (using CalcLighting function)
float4 g_lights_data;
float4 g_lights_pos0;
float4 g_lights_pos1;
float4 g_lights_pos2;
float4 g_lights_atten0;
float4 g_lights_atten1;
float4 g_lights_atten2;
float4 g_lights_diffuse0;
float4 g_lights_diffuse1;
float4 g_lights_diffuse2;


texture DiffuseMap : DiffuseMap
<
    string Name = "D.tga";
    string type = "2D";
>;

texture NormalMap : DiffuseMap
<
    string Name = "N.tga";
    string type = "2D";
>;

texture SpecularMap : DiffuseMap
<
    string Name = "S.tga";
    string type = "2D";
>;
texture VegShadowTex : DiffuseMap
<
    string Name = "D.tga";
    string type = "2D";
>;
texture DynTerShaMap : DiffuseMap
<
    string Name = "D.tga";
    string type = "2D";
>;
texture DepthMapTX1 : DiffuseMap
<
    string Name = "DEPTH1.tga";
    string type = "2D";
>;
texture DepthMapTX2 : DiffuseMap
<
    string Name = "DEPTH1.tga";
    string type = "2D";
>;
texture DepthMapTX3 : DiffuseMap
<
    string Name = "DEPTH1.tga";
    string type = "2D";
>;
texture DepthMapTX4 : DiffuseMap
<
    string Name = "D.tga";
    string type = "2D";
>;

//Diffuse Texture _D
sampler2D DiffuseSampler = sampler_state
{
    Texture   = <DiffuseMap>;
    MipFilter = LINEAR;
    MinFilter = ANISOTROPIC;
    MagFilter = LINEAR;
};

//Effect Texture _N 
sampler2D NormalSampler = sampler_state
{
    Texture   = <NormalMap>;
    MipFilter = LINEAR;
    MinFilter = ANISOTROPIC;
    MagFilter = LINEAR;
};

//Effect Texture _S 
sampler2D SpecSampler = sampler_state
{
    Texture   = <SpecularMap>;
    MipFilter = LINEAR;
    MinFilter = ANISOTROPIC;
    MagFilter = LINEAR;
};

sampler VegShadowSamp = sampler_state
{
   Texture = <VegShadowTex>;
   MinFilter = Linear; 
   MagFilter = Linear; 
   MipFilter = Linear;
   AddressU = clamp; 
   AddressV = clamp;
};

sampler2D DynTerShaSampler = sampler_state
{
    Texture   = <DynTerShaMap>;
    MipFilter = LINEAR;
    MinFilter = ANISOTROPIC;
    MagFilter = LINEAR;
    AddressU = Clamp;
    AddressV = Clamp;
};

sampler2D DepthMap1 = sampler_state
{
   Texture = <DepthMapTX1>;   
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    AddressU = Clamp;
    AddressV = Clamp;
};
sampler2D DepthMap2 = sampler_state
{
   Texture = <DepthMapTX2>;   
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    AddressU = Clamp;
    AddressV = Clamp;
};
sampler2D DepthMap3 = sampler_state
{
   Texture = <DepthMapTX3>;   
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    AddressU = Clamp;
    AddressV = Clamp;
};
sampler2D DepthMap4 = sampler_state
{
   Texture = <DepthMapTX4>;   
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    AddressU = Wrap;
    AddressV = Wrap;
    //AddressU = Border;
    //AddressV = Border;
   //BorderColor = 0xFFFFFFFF;
};

struct appdata {
    float4 Position   : POSITION;
    float2 UV      : TEXCOORD0;
    float4 Normal   : NORMAL;
    float4 Tangent   : TANGENT0;
    float4 Binormal   : BINORMAL0;
};

/*data passed to pixel shader*/

struct vertexOutput_low
{
    float4 Position     : POSITION;
    float2 TexCoord     : TEXCOORD0;
    float3 LightVec       : TEXCOORD1;
    float3 WorldNormal   : TEXCOORD2;
    float4 WPos         : TEXCOORD3;
   float2 vegshadowuv  : TEXCOORD4;
    float  clip         : TEXCOORD6;
    float  vDepth       : TEXCOORD7;
};

/*******Main Vertex Shader***************************/

vertexOutput_low mainVS_lowest(appdata IN)   
{
   vertexOutput_low OUT;

   float4 worldSpacePos = mul(IN.Position, World);
   OUT.WPos =   worldSpacePos; 
   OUT.WorldNormal = normalize(mul(IN.Normal, WorldIT).xyz);
   OUT.LightVec = normalize(LightSource);
   OUT.Position = mul(IN.Position, WorldViewProjection);
   OUT.TexCoord  = IN.UV; 
   OUT.vegshadowuv = float2(worldSpacePos.x/51200.0f,worldSpacePos.z/51200.0f);
   OUT.clip = dot(worldSpacePos, clipPlane);                                                                      
   OUT.vDepth = mul( IN.Position, WorldViewProjection ).z; 

    return OUT;
}

float4 mainPS_lowest(vertexOutput_low IN) : COLOR
{
   // clip
    clip(IN.clip);
   
   // lighting
    float3 Ln = normalize(IN.LightVec);
    float3 V  = (eyePos - IN.WPos);  
    float3 Vn  = normalize(V); 
    float3 Hn = normalize(Vn+Ln);
    float4 lighting = lit(pow( abs(0.5*(dot(Ln,IN.WorldNormal))+0.5),2),dot(Hn,IN.WorldNormal),24);  //Valve's lighting model

   // CHEAPEST flash light system (flash light control carried in SpotFlashColor.w )
    float4 viewspacePos = mul(IN.WPos, View);
    float flashlight = (1.0f-min(1,viewspacePos.z/300.0f)) * SpotFlashColor.w;   
   
   // paint
    float4 diffusemap = tex2D(DiffuseSampler,IN.TexCoord.xy);
    float4 ambContrib = (((AmbiColor*AmbiColorOverride)) * diffusemap);
    float4 diffuseContrib = diffusemap * (0.8*lighting.y*SurfColor + 0.2*SurfColor);
   float4 dynamicContrib = (diffusemap*flashlight);
    float4 result = diffuseContrib + ambContrib + dynamicContrib;

   // cheap dynamic terrain floor shadow texture read (tried to work out height based from light slope and local-y but no joy)
   float fShadow = (1.0-(0.5*(dot(Ln,IN.WorldNormal))+0.5)) * ShadowStrength * 0.2;
   
   // apply shadow mapping to final render
   result.xyz = result.xyz * (1.0f-(fShadow*0.65f));   
   
   //calculate hud pixel-fog
    float4 cameraPos = mul(IN.WPos, View);
    float hudfogfactor = saturate((cameraPos.z- HudFogDist.x)/(HudFogDist.y - HudFogDist.x));
    float4 hudfogresult = lerp(result,HudFogColor,hudfogfactor);
   
   // original entity diffuse alpha with override
    hudfogresult.a = diffusemap.a * alphaoverride;    
   
   // entity effect control can slice alpha based on a world Y position
   float alphaslice = 1.0f - min(1,max(0,IN.WPos.y - EntityEffectControl.x)/50.0f);
   hudfogresult.a = hudfogresult.a * alphaslice;
   
   // final pixel color
    
    // hack
    //return hudfogresult;   
    return float4(1,hudfogresult.y,hudfogresult.z,1);   
}

float4 mainPS_distant(vertexOutput_low IN) : COLOR
{
    // clip
    clip(IN.clip);
   
    // final pixel color
    return float4(1,1,1,1);   
}

float4 blackPS(vertexOutput_low IN) : COLOR
{
    clip(IN.clip); // all shaders should receive the clip value  
//    return float4(0,0,0,tex2D(DiffuseSampler,IN.TexCoord.xy).a);
   if( tex2D(DiffuseSampler,IN.TexCoord.xy).a < TREEALPHACLIP )
   {
       clip(-1);
      return IN.vDepth;
   }
   return IN.vDepth;
}

technique Highest
{
    pass P0
    {
        // shaders
        VertexShader = compile vs_2_0 mainVS_lowest();
        PixelShader  = compile ps_2_0 mainPS_lowest();
        alphafunc=greater;
        alpharef=128;
        AlphaBlendEnable = TRUE;
        AlphaTestEnable = true;
    }
}

technique Medium
{
    pass P0
    {
        // shaders
        VertexShader = compile vs_2_0 mainVS_lowest();
        PixelShader  = compile ps_2_0 mainPS_lowest();
        alphafunc=greater;
        alpharef=128;
        AlphaBlendEnable = TRUE;
        AlphaTestEnable = true;
    }
}

technique Lowest
{
    pass P0
    {
        // shaders
        VertexShader = compile vs_2_0 mainVS_lowest();
        PixelShader  = compile ps_2_0 mainPS_lowest();
        alphafunc=greater;
        alpharef=128;
        AlphaBlendEnable = TRUE;
        AlphaTestEnable = true;
    }
}

technique DepthMap
{
    pass p0
    {      
        VertexShader = compile vs_2_0 mainVS_lowest();
        PixelShader  = compile ps_2_0 blackPS();
        CullMode = None;
        alphafunc = greater;
      alpharef = 128;
        AlphaBlendEnable = FALSE;
        AlphaTestEnable = true;
   }
}

technique blacktextured
{
    pass P0
    {
        // shaders
        VertexShader = compile vs_2_0 mainVS_lowest();
        PixelShader  = compile ps_2_0 blackPS();
        CullMode = ccw;
        alphafunc=greater;
      alpharef=128 ;
        AlphaBlendEnable = FALSE;
        AlphaTestEnable = true;
    }
}
