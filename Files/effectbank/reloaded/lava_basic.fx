string Description = "Lava Shader";                           
#include "settings.fx"                         

float freq1 = 3.0;                                        
float freq2 = 3.5;
float timeScale = 40.0;
float warpScale = 0.35;
                                                          
// For Poisson Disk PCF sampling
static const float2 PoissonSamples[64] =
{
    float2(-0.5119625f, -0.4827938f),
    float2(-0.2171264f, -0.4768726f),
    float2(-0.7552931f, -0.2426507f),
    float2(-0.7136765f, -0.4496614f),
    float2(-0.5938849f, -0.6895654f),
    float2(-0.3148003f, -0.7047654f),
    float2(-0.42215f, -0.2024607f),
    float2(-0.9466816f, -0.2014508f),
    float2(-0.8409063f, -0.03465778f),
    float2(-0.6517572f, -0.07476326f),
    float2(-0.1041822f, -0.02521214f),
    float2(-0.3042712f, -0.02195431f),
    float2(-0.5082307f, 0.1079806f),
    float2(-0.08429877f, -0.2316298f),
    float2(-0.9879128f, 0.1113683f),
    float2(-0.3859636f, 0.3363545f),
    float2(-0.1925334f, 0.1787288f),
    float2(0.003256182f, 0.138135f),
    float2(-0.8706837f, 0.3010679f),
    float2(-0.6982038f, 0.1904326f),
    float2(0.1975043f, 0.2221317f),
    float2(0.1507788f, 0.4204168f),
    float2(0.3514056f, 0.09865579f),
    float2(0.1558783f, -0.08460935f),
    float2(-0.0684978f, 0.4461993f),
    float2(0.3780522f, 0.3478679f),
    float2(0.3956799f, -0.1469177f),
    float2(0.5838975f, 0.1054943f),
    float2(0.6155105f, 0.3245716f),
    float2(0.3928624f, -0.4417621f),
    float2(0.1749884f, -0.4202175f),
    float2(0.6813727f, -0.2424808f),
    float2(-0.6707711f, 0.4912741f),
    float2(0.0005130528f, -0.8058334f),
    float2(0.02703013f, -0.6010728f),
    float2(-0.1658188f, -0.9695674f),
    float2(0.4060591f, -0.7100726f),
    float2(0.7713396f, -0.4713659f),
    float2(0.573212f, -0.51544f),
    float2(-0.3448896f, -0.9046497f),
    float2(0.1268544f, -0.9874692f),
    float2(0.7418533f, -0.6667366f),
    float2(0.3492522f, 0.5924662f),
    float2(0.5679897f, 0.5343465f),
    float2(0.5663417f, 0.7708698f),
    float2(0.7375497f, 0.6691415f),
    float2(0.2271994f, -0.6163502f),
    float2(0.2312844f, 0.8725659f),
    float2(0.4216993f, 0.9002838f),
    float2(0.4262091f, -0.9013284f),
    float2(0.2001408f, -0.808381f),
    float2(0.149394f, 0.6650763f),
    float2(-0.09640376f, 0.9843736f),
    float2(0.7682328f, -0.07273844f),
    float2(0.04146584f, 0.8313184f),
    float2(0.9705266f, -0.1143304f),
    float2(0.9670017f, 0.1293385f),
    float2(0.9015037f, -0.3306949f),
    float2(-0.5085648f, 0.7534177f),
    float2(0.9055501f, 0.3758393f),
    float2(0.7599946f, 0.1809109f),
    float2(-0.2483695f, 0.7942952f),
    float2(-0.4241052f, 0.5581087f),
    float2(-0.1020106f, 0.6724468f),
};

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

// useful to make entity glow (for IDE and also in-game)
float4          GlowIntensity;

float ShadowStrength
<    string UIName =  "ShadowStrength";    
> = {1.0f};

float SurfaceSunFactor
<    string UIName =  "SurfaceSunFactor";    
> = {1.0f};

float GlobalSpecular
<    string UIName =  "GlobalSpecular";    
> = {0.5f};

float GlobalSurfaceIntensity
<    string UIName =  "GlobalSurfaceIntensity";    
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
float timer : Time;

float4 eyePos : CameraPosition;
float m_fClippingOnState = 1;

// Character Creator
float amountfromMask[4];
float amountfromPixel[4];
                                          
// Depth Write Control (1=write real depth)
float DepthWriteMode
<    string UIName =  "DepthWriteMode";    
> = {1.0f};

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

float SpecularOverride = 1.0f;

float4 SkyColor : Diffuse
<    string UIName =  "SkyColor";    
> = {1.0, 1.0, 1.0, 1.0f};

float4 FloorColor : Diffuse
<    string UIName =  "FloorColor";    
> = {1.0, 1.0, 1.00, 1.0f};

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


// RENDERCOLORTARGET simply indicates that we are using an RT (depth texture at bottom)
texture DiffuseMap : RENDERCOLORTARGET
<
    string Name = "D.tga";
    string type = "2D";
>;
texture OcclusionMap : DiffuseMap
<
    string Name = "O.tga";
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

texture IlluminationMap : DiffuseMap
<
    string Name = "I.tga";
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
//Character Creator
texture MaskMap : DiffuseMap
<
    string Name = "d.tga";
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

//Lightmap in static entities, occlusion map in dynamic entities _O
sampler2D OccSampler = sampler_state
{
    Texture   = <OcclusionMap>;
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

sampler2D IllumSampler = sampler_state
{
    Texture   = <IlluminationMap>;
    MipFilter = LINEAR;
    MinFilter = ANISOTROPIC;
    MagFilter = LINEAR;
};

sampler2D DepthMap1 = sampler_state
{
   Texture = <DepthMapTX1>;   
    MinFilter = POINT;//LINEAR;
    MagFilter = POINT;//LINEAR;
    AddressU = Clamp;
    AddressV = Clamp;
};
sampler2D DepthMap2 = sampler_state
{
   Texture = <DepthMapTX2>;   
    MinFilter = POINT;//LINEAR;
    MagFilter = POINT;//LINEAR;
    AddressU = Clamp;
    AddressV = Clamp;
};
sampler2D DepthMap3 = sampler_state
{
   Texture = <DepthMapTX3>;   
    MinFilter = POINT;//LINEAR;
    MagFilter = POINT;//LINEAR;
    AddressU = Clamp;
    AddressV = Clamp;
};
sampler2D DepthMap4 = sampler_state
{
   Texture = <DepthMapTX4>;   
    MinFilter = POINT;//LINEAR;
    MagFilter = POINT;//LINEAR;
    AddressU = Wrap;
    AddressV = Wrap;
    AddressU = Border;
    AddressV = Border;
   BorderColor = 0xFFFFFFFF;
};
//Character Creator
sampler2D MaskSampler = sampler_state
{
    Texture   = <MaskMap>;
    MipFilter = LINEAR;
    MinFilter = ANISOTROPIC;
    MagFilter = LINEAR;
};


struct appdata 
{
    float4 Position   : POSITION;
    float2 UV      : TEXCOORD0;
    float4 Normal   : NORMAL;
    float4 Tangent   : TANGENT0;
    float4 Binormal   : BINORMAL0;
};

/*data passed to pixel shader*/
struct vertexOutput
{
    float4 Position     : POSITION;
    float2 TexCoord     : TEXCOORD0;
    float3 LightVec       : TEXCOORD1;
    float3 WorldNormal   : TEXCOORD2;
    float3 WorldTangent   : TEXCOORD3;
    float3 WorldBinorm   : TEXCOORD4;
    float4 WPos         : TEXCOORD5;
    float  clip         : TEXCOORD6;
    float2 vDepth       : TEXCOORD7;
    float3 WorldEyeVec  : TEXCOORD8;
    float2 warp         : TEXCOORD9;      
};

struct vertexOutput_low
{
    float4 Position     : POSITION;
    float2 TexCoord     : TEXCOORD0;
    float3 LightVec       : TEXCOORD1;
    float3 WorldNormal   : TEXCOORD2;
    float4 WPos         : TEXCOORD3;
    float2 vegshadowuv  : TEXCOORD4;
    float  clip         : TEXCOORD5;
    float  vDepth       : TEXCOORD6;
    float2 warp         : TEXCOORD7;
};   

/****** helper functions for shadow mapping*****/

void ComputeCoordinatesTransform( in int iCascadeIndex,
                                  in float4 InterpolatedPosition,
                                  in out float4 vShadowTexCoord ) 
{
   float4 vLightDot = mul ( InterpolatedPosition, m_mShadow );
    vLightDot *= m_vCascadeScale[iCascadeIndex];
    vLightDot += m_vCascadeOffset[iCascadeIndex];
   vShadowTexCoord.xyz = vLightDot.xyz;
} 

void CalculatePCFPercentLit ( in int iCurrentCascadeIndex,
                       in float4 vShadowTexCoord, 
                       in float fCurrentDepth,
                       in float2 mwpos,                       
                              out float fPercentLit ) 
{
    fPercentLit = 0.0f;

   float2 fTS = (1.0f/SHADOWTEXELX,1.0f/SHADOWTEXELY);
   if ( iCurrentCascadeIndex==0 )
   {
        // test dither with random offsets.
        float2 o = fmod(floor(mwpos), 1.50) * 0.25;
        fPercentLit += vShadowTexCoord.z > tex2D(DepthMap1,float2(vShadowTexCoord.x,vShadowTexCoord.y)+(  (float2(-0.75, 0.75) + o) *fTS)  ).x ? 1.0f : 0.0f;
        fPercentLit += vShadowTexCoord.z > tex2D(DepthMap1,float2(vShadowTexCoord.x,vShadowTexCoord.y)+(  (float2( 0.25, 0.75) + o) *fTS)  ).x ? 1.0f : 0.0f;
        fPercentLit += vShadowTexCoord.z > tex2D(DepthMap1,float2(vShadowTexCoord.x,vShadowTexCoord.y)+(  (float2(-0.75,-0.25) + o) *fTS)  ).x ? 1.0f : 0.0f;
        //fPercentLit += vShadowTexCoord.z > tex2D(DepthMap1,float2(vShadowTexCoord.x,vShadowTexCoord.y)+(  (float2( 0.25,-0.25) + o) *fTS)  ).x ? 1.0f : 0.0f;
        fPercentLit += vShadowTexCoord.z > tex2D(DepthMap1,float2(vShadowTexCoord.x,vShadowTexCoord.y)+(  (float2( 0.75,-0.75) + o) *fTS)  ).x ? 1.0f : 0.0f;
        fPercentLit *= 0.25;
   }
   else
   {
      if ( iCurrentCascadeIndex==1 )
      {
         // test dither with random offsets.
         // cords on different shadow maps dont match 100% so adjust ( -0.00003f )
         //float2 o = fmod(floor(mwpos), 1.50) * 0.25;
         //fPercentLit += vShadowTexCoord.z-0.00003f > tex2D(DepthMap2,float2(vShadowTexCoord.x,vShadowTexCoord.y)+( (float2( 0.25, 0.75) + o) *fTS)).x ? 1.0f : 0.0f;
         //fPercentLit += vShadowTexCoord.z-0.00003f > tex2D(DepthMap2,float2(vShadowTexCoord.x,vShadowTexCoord.y)+( (float2(-0.75,-0.25) + o) *fTS)).x ? 1.0f : 0.0f;
         //fPercentLit *= 0.5;
         fPercentLit += vShadowTexCoord.z-0.00003f > tex2D(DepthMap2,float2(vShadowTexCoord.x,vShadowTexCoord.y)).x ? 1.0f : 0.0f;

      }
      else
      {
         if ( iCurrentCascadeIndex==2 )
         {
            fPercentLit += vShadowTexCoord.z-0.00009f > tex2D(DepthMap3,float2(vShadowTexCoord.x,vShadowTexCoord.y)).x ? 0.5f : 0.0f;
            //fPercentLit *= 0.5f;
            //fPercentLit = 0.0;

         }
         else
         {
            if ( iCurrentCascadeIndex==3 && vShadowTexCoord.z<1.0 )
            {
               fPercentLit += vShadowTexCoord.z-0.00012f > tex2D(DepthMap4,float2(vShadowTexCoord.x,vShadowTexCoord.y)).x ? 0.10f : 0.0f;
               //fPercentLit *= 0.25f;
               //fPercentLit = 0.0;
            }
         }
      }
   }
}

void CalculateBlendAmountForInterval ( in int iCurrentCascadeIndex, 
                                       in out float fPixelDepth, 
                                       in out float fCurrentPixelsBlendBandLocation,
                                       out float fBlendBetweenCascadesAmount ) 
{
   // Calculate amount to blend between two cascades and the band where blending will occure.
    // We need to calculate the band of the current shadow map where it will fade into the next cascade.
    // We can then early out of the expensive PCF for loop. 
    float fBlendInterval = m_fCascadeFrustumsEyeSpaceDepths[ iCurrentCascadeIndex ];
   
    int fBlendIntervalbelowIndex = min(0, iCurrentCascadeIndex-1);
   if ( fBlendIntervalbelowIndex>1 )
   {
      fPixelDepth -= m_fCascadeFrustumsEyeSpaceDepths[ fBlendIntervalbelowIndex ];
      fBlendInterval -= m_fCascadeFrustumsEyeSpaceDepths[ fBlendIntervalbelowIndex ];
    }
   
    // The current pixel's blend band location will be used to determine when we need to blend and by how much.
    fCurrentPixelsBlendBandLocation = 1.0f - (fPixelDepth / fBlendInterval);
   
    // The fBlendBetweenCascadesAmount is our location in the blend band.
    fBlendBetweenCascadesAmount = fCurrentPixelsBlendBandLocation / m_fCascadeBlendArea;
}

/*******Main Vertex Shader***************************/

vertexOutput mainVS_highest(appdata IN)   
{
   vertexOutput OUT;
   
   float4 worldSpacePos = mul(IN.Position, World);
   OUT.WPos =   worldSpacePos; 
      
   OUT.WorldNormal = normalize(mul(IN.Normal, WorldIT).xyz);
   // PE: something is wrong with tangent. lee: try to display it directly in fragment,
   // on some angles it gives different result on a flat surface ?
   //OUT.WorldTangent = normalize(mul(IN.Tangent, WorldIT).xyz);
   float3 c1 = cross(OUT.WorldNormal, float3(0.0, 0.0, 1.0)); 
   float3 c2 = cross(OUT.WorldNormal, float3(0.0, 1.0, 0.0)); 
   if (length(c1) > length(c2)) {
     OUT.WorldTangent = c1;   
   } else {
     OUT.WorldTangent = c2;   
   }
   OUT.WorldTangent = normalize(OUT.WorldTangent); 
   OUT.WorldBinorm = normalize(mul(IN.Binormal, WorldIT).xyz);
      
   OUT.LightVec = normalize(LightSource);
   OUT.Position = mul(IN.Position, WorldViewProjection);
   OUT.TexCoord  = IN.UV; 
   OUT.WorldEyeVec = (ViewInverse[3].xyz - worldSpacePos.xyz);   
                 
   // all shaders should send the clip value to the pixel shader (for refr/refl)                                                                     
   OUT.clip = dot(worldSpacePos, clipPlane);                                                                      
     
   // SHADOW MAPPING - world position and projected depth (for cascade distance calc)
   OUT.vDepth.x = mul( IN.Position, WorldViewProjection ).z; 

   // defeat projective aliasing by detecting when parallel to light direction
   OUT.vDepth.y = max(0,abs(dot(OUT.LightVec, OUT.WorldNormal))-0.25f)*1.333f;
   float timeNow = (timer/timeScale);
   OUT.TexCoord = IN.UV+float2 (timeNow,0.0);
   OUT.warp = float2 (sin(freq1*timeNow),cos(freq2*timeNow));
       
    return OUT;
}

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
   float timeNow = (timer/timeScale);
   OUT.TexCoord = IN.UV+float2 (timeNow,0.0);
   OUT.warp = float2 (sin(freq1*timeNow),cos(freq2*timeNow));

    return OUT;
}

float4 CalcSpotFlash( float3 worldNormal, float3 worldPos )
{
    float4 output = (float4)0.0;
    float3 toLight = (SpotFlashPos.xyz - worldPos.xyz);
    float3 lightDir = normalize( toLight );
    float lightDist = length( toLight );
    
    float MinFalloff = 100;  //falloff start distance
    float LinearFalloff = 1;
    float ExpFalloff = .005;  // 1/200
    SpotFlashPos.w = clamp(0,1,SpotFlashPos.w);
    
    //classic attenuation - but never actually reaches zero
    float fAtten = 1.0/(MinFalloff + (LinearFalloff*lightDist)+(ExpFalloff*lightDist*lightDist));
    output += (float4(SpotFlashColor.xyz,1)) *fAtten * (SpotFlashPos.w) * max(0,dot(worldNormal,lightDir));
        
    return output;
}

float4 CalcLighting(float3 Nb, float3 worldPos, float3 Vn, float4 diffusemap, float4 specmap)
{                              
   float4 output = GlowIntensity;
#ifdef VERSION114
   if ( g_lights_data.x == 0 ) return output;
#endif    
    // light 0
    float3 toLight = g_lights_pos0.xyz - worldPos;
    float lightDist = length( toLight );
    float fAtten;
    float3 lightDir;
    float3 halfvec;
    float4 lit0;
//    if( lightDist < g_lights_pos0.w*4.0 ) {  
       //float fAtten = 1.0/dot( g_lights_atten0, float4(1,lightDist,lightDist*lightDist,0) ); // NVIDIA 361 bug
       float4 local_lights_atten0 = float4(1.0, 1.0/g_lights_pos0.w, 1.0/(g_lights_pos0.w*g_lights_pos0.w), 0.0);
       fAtten = 1.0/dot( local_lights_atten0, float4(1,lightDist,lightDist*lightDist,0) );
       lightDir = normalize( toLight );
       halfvec = normalize(Vn + lightDir);
       lit0 = lit(dot(lightDir,Nb),dot(halfvec,Nb),24); 
       output+= (lit0.y *g_lights_diffuse0 * fAtten * 1.7*diffusemap) + (lit0.z * g_lights_diffuse0 * fAtten *specmap );   
//    }   
    // light 1
    toLight = g_lights_pos1.xyz - worldPos;
    lightDist = length( toLight );
//    if( lightDist < g_lights_pos1.w*4.0 ) {  
       //fAtten = 1.0/dot( g_lights_atten1, float4(1,lightDist,lightDist*lightDist,0) ); // NVIDIA 361 bug
       float4 local_lights_atten1 = float4(1.0, 1.0/g_lights_pos1.w, 1.0/(g_lights_pos1.w*g_lights_pos1.w), 0.0);
       fAtten = 1.0/dot( local_lights_atten1, float4(1,lightDist,lightDist*lightDist,0) );
       lightDir = normalize( toLight );
       halfvec = normalize(Vn + lightDir);
       lit0 = lit(dot(lightDir,Nb),dot(halfvec,Nb),24); 
       output+= (lit0.y *g_lights_diffuse1 * fAtten * 1.7*diffusemap) + (lit0.z * g_lights_diffuse1 * fAtten *specmap );   
//    }   
    // light 2
    toLight = g_lights_pos2.xyz - worldPos;
    lightDist = length( toLight );
//    if( lightDist < g_lights_pos2.w*4.0 ) {  
       //fAtten = 1.0/dot( g_lights_atten2, float4(1,lightDist,lightDist*lightDist,0) ); // NVIDIA 361 bug
       float4 local_lights_atten2 = float4(1.0, 1.0/g_lights_pos2.w, 1.0/(g_lights_pos2.w*g_lights_pos2.w), 0.0);
       fAtten = 1.0/dot( local_lights_atten2, float4(1,lightDist,lightDist*lightDist,0) );
       lightDir = normalize( toLight );
       halfvec = normalize(Vn + lightDir);
       lit0 = lit(dot(lightDir,Nb),dot(halfvec,Nb),24); 
       output+= (lit0.y *g_lights_diffuse2 * fAtten * 1.7*diffusemap) + (lit0.z * g_lights_diffuse2 * fAtten *specmap );   
//    }   
    return output;
}

float4 mainPS_highest(vertexOutput IN) : COLOR
{
   // clip
    clip(IN.clip);
   
   // source textures
    float4 diffusemap = tex2D(DiffuseSampler,IN.TexCoord.xy);

   float2 temp = IN.TexCoord.xy;
   float4 baseColour = diffusemap;
   temp = temp + IN.warp*baseColour.xy*warpScale;
   diffusemap = tex2D(DiffuseSampler,temp);

    //PE: not used en entity only static
    //float4 occmap = tex2D(OccSampler,IN.TexCoord.xy) * GlobalSurfaceIntensity;
    float3 normalmap = tex2D(NormalSampler,IN.TexCoord.xy) * 2 - 1;
    float4 specmap = tex2D(SpecSampler,IN.TexCoord.xy);
    // lava looks wierd with illum.
    //float4 illummap = tex2D(IllumSampler,IN.TexCoord.xy);
   
   // work out normal from normmap/tangent/binormal
    float3 Ln = (IN.LightVec);
    float3 Nn = (IN.WorldNormal);
    float3 Tn = (IN.WorldTangent);  
    float3 Bn = (IN.WorldBinorm);

    float3 Nb = (normalmap.z * Nn) + ((normalmap.x * Tn + normalmap.y * Bn));
    Nb = normalize(Nb);
         
   // lighting
    float3 V  = (eyePos - IN.WPos);  
    float3 Vn  = normalize(V); 
    float3 Hn = normalize(Vn+Ln);
    float4 lighting = lit(dot(Ln,Nb),dot(Hn,Nb),24);
   lighting.y = lerp(0.65,lighting.y,SurfaceSunFactor);
    // dynamic lighting
   float4 spotflashlighting = CalcSpotFlash (Nb,IN.WPos.xyz);   
   float4 dynamicContrib = CalcLighting (Nb,IN.WPos.xyz,Vn,diffusemap,float4(0,0,0,0)) + spotflashlighting;  
   
   // flash light system (flash light control carried in SpotFlashColor.w )
   float conewidth = 24;
    float4 viewspacePos = mul(IN.WPos, View);
    float intensity = max(0, 1.5f - (viewspacePos.z/500.0f));
   float3 lightvector = Vn;
    float3 lightdir = float3(View._m02,View._m12,View._m22);
    float flashlight = pow(max(dot(-lightvector, lightdir),0),conewidth) * intensity * SpotFlashColor.w;   
   dynamicContrib.xyz = dynamicContrib.xyz + (diffusemap.xyz*float3(flashlight,flashlight,flashlight));

   // paint
   float4 diffuseContrib = SurfColor * diffusemap * (lighting.y*0.9f) * GlobalSurfaceIntensity;
   float4 specContrib = lighting.z * specmap * SurfColor * SpecularOverride * GlobalSpecular;
//   float4 specContrib = lighting.z * specmap * SurfColor * GlobalSpecular;

   // spherical ambience
   float fSkyFloorRatio = (1+dot(IN.WorldNormal.xyz,float3(0,1,0)))/2;
   float3 bouncelightcolor = lerp(FloorColor,SkyColor,fSkyFloorRatio) * diffusemap.xyz * 0.8;
   bouncelightcolor = bouncelightcolor + (diffusemap.xyz * 0.2);
//   float4 ambContrib = (float4(bouncelightcolor,1) * ((AmbiColor * AmbiColorOverride)+float4(illummap.xxx,1))) * 2;
   float4 ambContrib = (float4(bouncelightcolor,1) * ((AmbiColor * AmbiColorOverride) )) * 2;
   // shadow mapping code
   float fShadow = 0.0f;
   float4 vShadowMapTextureCoord = 0.0f;
   if ( ShadowStrength > 0.0f )
   {
      // reset shadow vars
      float fPercentLit = 0.0f;

      // the interval based selection technique compares the pixel's depth against the frustum's cascade divisions.
      float fCurrentPixelDepth;
      fCurrentPixelDepth = IN.vDepth.x;
      int iCurrentCascadeIndex;
      iCurrentCascadeIndex = 3;
      if ( fCurrentPixelDepth < m_fCascadeFrustumsEyeSpaceDepths[2] ) iCurrentCascadeIndex = 2;
      if ( fCurrentPixelDepth < m_fCascadeFrustumsEyeSpaceDepths[1] ) iCurrentCascadeIndex = 1;
      if ( fCurrentPixelDepth < m_fCascadeFrustumsEyeSpaceDepths[0] ) iCurrentCascadeIndex = 0;

      // repeat text coord calculations for the next cascade - the next cascade index is used for blurring between maps.
      int iNextCascadeIndex = 1;
      iNextCascadeIndex = min ( 4 - 1, iCurrentCascadeIndex + 1 ); 
      float fBlendBetweenCascadesAmount = 1.0f;
      float fCurrentPixelsBlendBandLocation = 1.0f;
      CalculateBlendAmountForInterval ( iCurrentCascadeIndex, fCurrentPixelDepth, 
         fCurrentPixelsBlendBandLocation, fBlendBetweenCascadesAmount );

      // calculate shadowmaptexture view space
      float4 finalwpos = IN.WPos;

      // work out texture coordinate into specified shadow map
      ComputeCoordinatesTransform( iCurrentCascadeIndex, finalwpos, vShadowMapTextureCoord );    

      // offset shadow pixel depth textcord based on light direction. 
      float sbias = lerp(ADJUSTSHADOW,0.000115f,clamp( dot(IN.WorldNormal,Ln) ,0.0,1.0));
      vShadowMapTextureCoord.z -= sbias + (fCurrentPixelDepth/20000000.0f);

      // work out how much shadow
      CalculatePCFPercentLit ( iCurrentCascadeIndex, vShadowMapTextureCoord, fCurrentPixelDepth, finalwpos.xz, fShadow );
                         
      if( fCurrentPixelsBlendBandLocation < (m_fCascadeBlendArea*0.75) ) // PE: lower a bit.
      {  
         // the current pixel is within the blend band.
         // Repeat text coord calculations for the next cascade. 
         // The next cascade index is used for blurring between maps.
         float4 vShadowMapTextureCoord_blend = 0.0f;

         ComputeCoordinatesTransform( iNextCascadeIndex, finalwpos, vShadowMapTextureCoord_blend );  
      
         // the current pixel is within the blend band.
         float fPercentLit_blend = 0.0f;
         
         vShadowMapTextureCoord_blend.z -= sbias + (fCurrentPixelDepth/20000000.0f);
         
         CalculatePCFPercentLit ( iNextCascadeIndex, vShadowMapTextureCoord_blend, fCurrentPixelDepth, finalwpos.xz, fPercentLit_blend );
                           
         // Blend the two calculated shadows by the blend amount.
         fShadow = lerp( fPercentLit_blend, fShadow, fBlendBetweenCascadesAmount ); 
      }
      
      // finally modulate shadow with strength (IN.vDepth.y ensures no projective aliasing!)
      // 291115 - projectile aliasing solved - can just cap shadow max to match terrain shadow technique
      fShadow = min ( fShadow * ShadowStrength, 0.7f );
   }

   // inverse to modulate surface lighting (and only shadow surfaces facing sunlight)
   float ShadowSunFactor = lerp(1.0,dot(Ln,IN.WorldNormal),SurfaceSunFactor);
   fShadow = clamp( fShadow * ShadowSunFactor * 2.5f, 0.0 , 0.7 ); // PE: Let it look like baked shadows.
   float fInvShadow = 1.0-fShadow;

   // apply shadow mapping to final render
   //ambContrib.xyz = ambContrib.xyz * fInvShadow; // 291115 - ambient is NOT affected by shadow!
   diffuseContrib.xyz = diffuseContrib.xyz * fInvShadow;
   specContrib.xyz = specContrib.xyz * fInvShadow;
    float4 result = diffuseContrib + ambContrib + specContrib + dynamicContrib;   
   
   //calculate hud pixel-fog
    float4 cameraPos = mul(IN.WPos, View);
    float hudfogfactor = saturate((cameraPos.z- HudFogDist.x)/(HudFogDist.y - HudFogDist.x));
    float4 hudfogresult = lerp(result,float4(HudFogColor.xyz,0),hudfogfactor*HudFogColor.w);
   
   // original entity diffuse alpha with override
   // hudfogresult.a = diffusemap.a * alphaoverride;    
   
   // entity effect control can slice alpha based on a world Y position
   //float alphaslice = 1.0f - min(1,max(0,IN.WPos.y - EntityEffectControl.x)/50.0f);
   //hudfogresult.a = hudfogresult.a * alphaslice;
   
   // final pixel color
   return float4(hudfogresult.rgb,1.0);

//    return hudfogresult;
//    return float4( hudfogresult.r,0.0,0.0,1.0);
    //return float4(clamp( dot(IN.WorldNormal,Ln) ,0.0,1.0),0.0,0.0,1.0);   
    //return float4(Tn,1.0);   
    //return float4(Tn,1.0);   

}

float4 mainPS_medium(vertexOutput_low IN) : COLOR
{
   // clip
    clip(IN.clip);
   
   // texture ref
    float4 diffusemap = tex2D(DiffuseSampler,IN.TexCoord.xy);

   float2 temp = IN.TexCoord.xy;
   float4 baseColour = diffusemap;
   temp = temp + IN.warp*baseColour.xy*warpScale;
   diffusemap = tex2D(DiffuseSampler,temp);
  
   // lighting
    float3 Ln = normalize(IN.LightVec);
    float3 V  = (eyePos - IN.WPos);  
    float3 Vn  = normalize(V); 
    float3 Hn = normalize(Vn+Ln);
    float4 lighting = lit(dot(Ln,IN.WorldNormal),dot(Hn,IN.WorldNormal),24);
   lighting.y = lerp(0.65,lighting.y,SurfaceSunFactor);

    // dynamic lighting
   float4 spotflashlighting = CalcSpotFlash (IN.WorldNormal,IN.WPos.xyz);   
   float4 dynamicContrib = CalcLighting (IN.WorldNormal,IN.WPos.xyz,Vn,diffusemap,float4(0,0,0,0)) + spotflashlighting;  
   
   // flash light system (flash light control carried in SpotFlashColor.w )
    float4 viewspacePos = mul(IN.WPos, View);
   float conewidth = 24;
    float intensity = max(0, 1.5f - (viewspacePos.z/500.0f));
    float3 lightvector = Vn;
    float3 lightdir = float3(View._m02,View._m12,View._m22);
    float flashlight = pow(max(dot(-lightvector, lightdir),0),conewidth) * intensity * SpotFlashColor.w;   
   dynamicContrib.xyz = dynamicContrib.xyz + (diffusemap.xyz*float3(flashlight,flashlight,flashlight));
   
   // paint
   float4 diffuseContrib = SurfColor * diffusemap * lighting.y * GlobalSurfaceIntensity;

   // spherical ambience
   float fSkyFloorRatio = (1+dot(IN.WorldNormal.xyz,float3(0,1,0)))/2;
   float3 bouncelightcolor = lerp(FloorColor,SkyColor,fSkyFloorRatio) * diffusemap.xyz * 0.8;
   bouncelightcolor = bouncelightcolor + (diffusemap.xyz * 0.2);
    float4 ambContrib = float4(bouncelightcolor,1) * AmbiColor * AmbiColorOverride * 2;
    float4 result = diffuseContrib + ambContrib + dynamicContrib;
   
   //calculate hud pixel-fog
    float4 cameraPos = mul(IN.WPos, View);
    float hudfogfactor = saturate((cameraPos.z- HudFogDist.x)/(HudFogDist.y - HudFogDist.x));
    float4 hudfogresult = lerp(result,float4(HudFogColor.xyz,0),hudfogfactor*HudFogColor.w);
   
   // original entity diffuse alpha with override
   // hudfogresult.a = diffusemap.a * alphaoverride;    
   
   // entity effect control can slice alpha based on a world Y position
   //float alphaslice = 1.0f - min(1,max(0,IN.WPos.y - EntityEffectControl.x)/50.0f);
   //hudfogresult.a = hudfogresult.a * alphaslice;
   
   // final pixel color
    return float4(hudfogresult.rgb,1.0);
//    return hudfogresult;   
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
    float4 lighting = lit(dot(Ln,IN.WorldNormal),dot(Hn,IN.WorldNormal),24);
   lighting.y = lerp(0.65,lighting.y,SurfaceSunFactor);

   // CHEAPEST flash light system (flash light control carried in SpotFlashColor.w )
    float4 viewspacePos = mul(IN.WPos, View);
    float flashlight = (1.0f-min(1,viewspacePos.z/300.0f)) * SpotFlashColor.w;   
   
   // paint
    float4 diffusemap = tex2D(DiffuseSampler,IN.TexCoord.xy);

   float2 temp = IN.TexCoord.xy;
   float4 baseColour = diffusemap;
   temp = temp + IN.warp*baseColour.xy*warpScale;
   diffusemap = tex2D(DiffuseSampler,temp);


   float4 diffuseContrib = SurfColor * diffusemap * lighting.y * GlobalSurfaceIntensity;
   diffuseContrib.xyz = diffuseContrib.xyz + (diffusemap.xyz*float3(flashlight,flashlight,flashlight));

   // spherical ambience
   float fSkyFloorRatio = (1+dot(IN.WorldNormal.xyz,float3(0,1,0)))/2;
   float3 bouncelightcolor = lerp(FloorColor,SkyColor,fSkyFloorRatio) * diffusemap.xyz * 0.8;
   bouncelightcolor = bouncelightcolor + (diffusemap.xyz * 0.2);
    float4 ambContrib = float4(bouncelightcolor,1) * AmbiColor * AmbiColorOverride * 2;
    float4 result = diffuseContrib + ambContrib;

   //calculate hud pixel-fog
    float4 cameraPos = mul(IN.WPos, View);
    float hudfogfactor = saturate((cameraPos.z- HudFogDist.x)/(HudFogDist.y - HudFogDist.x));
    float4 hudfogresult = lerp(result,float4(HudFogColor.xyz,0),hudfogfactor*HudFogColor.w);
   
   // original entity diffuse alpha with override
   // hudfogresult.a = diffusemap.a * alphaoverride;    
   
   // entity effect control can slice alpha based on a world Y position
   //float alphaslice = 1.0f - min(1,max(0,IN.WPos.y - EntityEffectControl.x)/50.0f);
   //hudfogresult.a = hudfogresult.a * alphaslice;
   
   // final pixel color
   return float4(hudfogresult.rgb,1.0);
//    return hudfogresult;   
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
   if( tex2D(DiffuseSampler,IN.TexCoord.xy).a < TREEALPHACLIP ) 
   {
       clip(-1);
      return IN.vDepth;
   }
   return IN.vDepth;
}

/****** render depth information ***************/

vertexOutput_low mainVS_renderdepth(appdata IN)   
{
    vertexOutput_low OUT;
   float4 tempPos = mul(IN.Position, WorldViewProjection);
    OUT.Position = tempPos;
    OUT.LightVec = float3(0,0,0);
    float4 worldSpacePos = mul(IN.Position, World);
   OUT.vegshadowuv = float2(0,0);
    OUT.WorldNormal = float3(0,0,0);
   OUT.vDepth = float2(0,0);
    OUT.clip = dot(worldSpacePos, clipPlane);
    OUT.TexCoord = IN.UV;
   worldSpacePos.w = (7000-mul( IN.Position, WorldView ).z) * DepthWriteMode;
    OUT.WPos = worldSpacePos;  
    OUT.vDepth = tempPos.z;
    OUT.warp = float2(0,0);    
    return OUT;
}
float4 mainPS_renderdepth(vertexOutput_low IN) : COLOR
{
    clip(IN.clip);
   clip(tex2D(DiffuseSampler,IN.TexCoord.xy).a - TREEALPHACLIP );
   return IN.WPos.wxyz;
}

technique Highest
{
    pass RenderDepthPixelsPass
   <
      string RenderColorTarget = "[depthtexture]";
   >
    {
        // shaders
        VertexShader = compile vs_3_0 mainVS_renderdepth();
        PixelShader  = compile ps_3_0 mainPS_renderdepth();
        AlphaBlendEnable = false;
        AlphaTestEnable = false;
    }
    pass MainPass
   <
      string RenderColorTarget = "";
   >
    {
        // shaders
        VertexShader = compile vs_3_0 mainVS_highest();
        PixelShader  = compile ps_3_0 mainPS_highest();
//        alphafunc=greater;
//        alpharef=128;
#ifdef DEBUGLEVEL
        FillMode = WIREFRAME;
#endif

        AlphaBlendEnable = false;
        AlphaTestEnable = false;
    }
}

technique Medium
{
    pass RenderDepthPixelsPass
   <
      string RenderColorTarget = "[depthtexture]";
   >
    {
        // shaders
        VertexShader = compile vs_3_0 mainVS_renderdepth();
        PixelShader  = compile ps_3_0 mainPS_renderdepth();
        AlphaBlendEnable = false;
        AlphaTestEnable = false;
    }
    pass MainPass
   <
      string RenderColorTarget = "";
   >
    {
        // shaders
        VertexShader = compile vs_3_0 mainVS_lowest();
        PixelShader  = compile ps_3_0 mainPS_medium();
//        alphafunc=greater;
//        alpharef=128;
        AlphaBlendEnable = false;
        AlphaTestEnable = false;
    }
}

technique Lowest
{
    pass RenderDepthPixelsPass
   <
      string RenderColorTarget = "[depthtexture]";
   >
    {
        // shaders
        VertexShader = compile vs_3_0 mainVS_renderdepth();
        PixelShader  = compile ps_3_0 mainPS_renderdepth();
        AlphaBlendEnable = false;
        AlphaTestEnable = false;
    }
    pass MainPass
   <
      string RenderColorTarget = "";
   >
    {
        // shaders
        VertexShader = compile vs_3_0 mainVS_lowest();
        PixelShader  = compile ps_3_0 mainPS_lowest();
//        alphafunc = greater;
//        alpharef = 128;
        AlphaBlendEnable = false;
        AlphaTestEnable = false;
    }
}

technique DepthMap
{
    pass p0
    {      
        VertexShader = compile vs_3_0 mainVS_lowest();
        PixelShader  = compile ps_3_0 blackPS();
        CullMode = CCW;
//        alphafunc = greater;
//        alpharef = 128;
        AlphaBlendEnable = FALSE;
        AlphaTestEnable = false;
   }
}

technique blacktextured
{
    pass P0
    {
        // shaders
        VertexShader = compile vs_3_0 mainVS_lowest();
        PixelShader  = compile ps_3_0 blackPS();
        CullMode = ccw;
//        alphafunc=greater;
//        alpharef=128 ;
        AlphaBlendEnable = FALSE;
        AlphaTestEnable = false;
    }
}
