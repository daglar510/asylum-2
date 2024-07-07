#include "settings.fx"
/*******************************************************************************************
Shader Model 3 Rendering System for FPS Creator
by Mark Blosser  
email: mjblosser@gmail.com
website: www.mjblosser.com
-------------------------------------------------------------------
Description: 
Shader for dynamic entities. Uses diffuse, illumination, normal, and specular mapping.
Requires  D2,I,N,S textures.  

/**************MATRICES & UNTWEAKABLES *****************************************************/

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

/**************VALUES PROVIDED FROM FPSC - NON TWEAKABLE**************************************/

float4 clipPlane : ClipPlane;  //cliplane for water plane

float4 LightSource
<   string UIType = "Fixed Light Direction";
> = {0.0f, -1.0f, 0.0f, 1.0f};

//SpotFlash Values from FPSC
float4 SpotFlashPos;  //SpotFlashPos.w is carrying the spotflash fadeout value
float4 SpotFlashColor; //remember this has not been divided by 255 before being sent from FPSC (I should fix this)

//WATER Fog Color
float4 FogColor : Diffuse
<   string UIName =  "Fog Color";    
> = {0.0f, 0.0f, 0.0f, 0.0000001f};

//HUD Fog Color
float4 HudFogColor : Diffuse
<   string UIName =  "Hud Fog Color";    
> = {0.0f, 0.0f, 0.0f, 0.0000001f};

//HUD Fog Distances (near,far,0,0)
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


/***************TEXTURES AND SAMPLERS***************************************************/
//For dynamic ojbects (D, I, N, S)

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


/************* DATA STRUCTS **************/

struct appdata 
{
    float4 Position   : POSITION;
    float4 Normal   : NORMAL;
    float2 UV      : TEXCOORD0;
};

/*data passed to pixel shader*/
struct vertexOutput
{
    float4 Position     : POSITION;
    float2 TexCoord     : TEXCOORD0;
    float  WaterFog     : TEXCOORD1; 
    float4 WPos         : TEXCOORD2;
    float  clip         : TEXCOORD3;
    float  vDepth       : TEXCOORD4;
   float3 WorldEyeVec  : TEXCOORD5;
};

/****** helper functions for shadow mapping*****/

void ComputeCoordinatesTransform( in int iCascadeIndex,
                                      in float4 InterpolatedPosition ,
                                      in out float4 vShadowTexCoord ) 
{
   float4 vLightDot = mul ( InterpolatedPosition, m_mShadow );
    vLightDot *= m_vCascadeScale[iCascadeIndex];
    vLightDot += m_vCascadeOffset[iCascadeIndex];
   vShadowTexCoord.xyz = vLightDot.xyz;
} 

void CalculatePCFPercentLit ( in int iCurrentCascadeIndex,
                       in float4 vShadowTexCoord, 
                              in float fRightTexelDepthDelta, 
                              in float fUpTexelDepthDelta,
                              in float2 mwpos,
                              out float fPercentLit ) 
{
   // Use PCF to sample the depth map and return a percent lit value.
    fPercentLit = 0.0f;
   
   // this threshold ensures light-facing surfaces are largely lit without casting the
   // shadow too far in the other direction making shadow joins look bad
   
   float fTS = m_fTexelSize * 2.0f;
   if ( iCurrentCascadeIndex==0 )
   {
        // test dither with random offsets.
        float2 o = fmod(floor(mwpos), 1.50) * 0.25;
        fPercentLit += vShadowTexCoord.z > tex2D(DepthMap1,float2(vShadowTexCoord.x,vShadowTexCoord.y)+(  (float2(-0.75, 0.75) + o) *fTS)  ).x ? 1.0f : 0.0f;
        fPercentLit += vShadowTexCoord.z > tex2D(DepthMap1,float2(vShadowTexCoord.x,vShadowTexCoord.y)+(  (float2( 0.25, 0.75) + o) *fTS)  ).x ? 1.0f : 0.0f;
        fPercentLit += vShadowTexCoord.z > tex2D(DepthMap1,float2(vShadowTexCoord.x,vShadowTexCoord.y)+(  (float2(-0.75,-0.25) + o) *fTS)  ).x ? 1.0f : 0.0f;
        fPercentLit += vShadowTexCoord.z > tex2D(DepthMap1,float2(vShadowTexCoord.x,vShadowTexCoord.y)+(  (float2( 0.25,-0.25) + o) *fTS)  ).x ? 1.0f : 0.0f;
        fPercentLit += vShadowTexCoord.z > tex2D(DepthMap1,float2(vShadowTexCoord.x,vShadowTexCoord.y)+(  (float2( 0.75,-0.75) + o) *fTS)  ).x ? 1.0f : 0.0f;
        fPercentLit *= 0.20;

      //fPercentLit += vShadowTexCoord.z > tex2D(DepthMap1,float2(vShadowTexCoord.x,vShadowTexCoord.y)).x ? 1.0f : 0.0f;
      //fPercentLit += vShadowTexCoord.z > tex2D(DepthMap1,float2(vShadowTexCoord.x,vShadowTexCoord.y-fTS)).x ? 1.0f : 0.0f;
      //fPercentLit += vShadowTexCoord.z > tex2D(DepthMap1,float2(vShadowTexCoord.x+fTS,vShadowTexCoord.y-fTS)).x ? 1.0f : 0.0f;
      //fPercentLit += vShadowTexCoord.z > tex2D(DepthMap1,float2(vShadowTexCoord.x+fTS+fTS,vShadowTexCoord.y-fTS)).x ? 1.0f : 0.0f;
      //fPercentLit += vShadowTexCoord.z > tex2D(DepthMap1,float2(vShadowTexCoord.x+fTS,vShadowTexCoord.y)).x ? 1.0f : 0.0f;
      //fPercentLit += vShadowTexCoord.z > tex2D(DepthMap1,float2(vShadowTexCoord.x+fTS+fTS,vShadowTexCoord.y)).x ? 1.0f : 0.0f;
      //fPercentLit += vShadowTexCoord.z > tex2D(DepthMap1,float2(vShadowTexCoord.x,vShadowTexCoord.y+fTS)).x ? 1.0f : 0.0f;
      //fPercentLit += vShadowTexCoord.z > tex2D(DepthMap1,float2(vShadowTexCoord.x+fTS,vShadowTexCoord.y+fTS)).x ? 1.0f : 0.0f;
      //fPercentLit += vShadowTexCoord.z > tex2D(DepthMap1,float2(vShadowTexCoord.x+fTS+fTS,vShadowTexCoord.y+fTS)).x ? 1.0f : 0.0f;
   }
   else
   {
      if ( iCurrentCascadeIndex==1 )
      {
        // test dither with random offsets.
        float2 o = fmod(floor(mwpos), 1.50) * 0.25;
        fPercentLit += vShadowTexCoord.z > tex2D(DepthMap2,float2(vShadowTexCoord.x,vShadowTexCoord.y)+(  (float2(-0.75, 0.75) + o) *fTS)  ).x ? 1.0f : 0.0f;
        fPercentLit += vShadowTexCoord.z > tex2D(DepthMap2,float2(vShadowTexCoord.x,vShadowTexCoord.y)+(  (float2( 0.25, 0.75) + o) *fTS)  ).x ? 1.0f : 0.0f;
        fPercentLit += vShadowTexCoord.z > tex2D(DepthMap2,float2(vShadowTexCoord.x,vShadowTexCoord.y)+(  (float2(-0.75,-0.25) + o) *fTS)  ).x ? 1.0f : 0.0f;
        fPercentLit += vShadowTexCoord.z > tex2D(DepthMap2,float2(vShadowTexCoord.x,vShadowTexCoord.y)+(  (float2( 0.25,-0.25) + o) *fTS)  ).x ? 1.0f : 0.0f;
        fPercentLit += vShadowTexCoord.z > tex2D(DepthMap2,float2(vShadowTexCoord.x,vShadowTexCoord.y)+(  (float2( 0.75,-0.75) + o) *fTS)  ).x ? 1.0f : 0.0f;
        fPercentLit *= 0.20;

        // fPercentLit += vShadowTexCoord.z > tex2D(DepthMap2,float2(vShadowTexCoord.x,vShadowTexCoord.y)).x ? 1.0f : 0.0f;
        // fPercentLit += vShadowTexCoord.z > tex2D(DepthMap2,float2(vShadowTexCoord.x,vShadowTexCoord.y-fTS)).x ? 1.0f : 0.0f;
        // fPercentLit += vShadowTexCoord.z > tex2D(DepthMap2,float2(vShadowTexCoord.x+fTS,vShadowTexCoord.y-fTS)).x ? 1.0f : 0.0f;
        // fPercentLit += vShadowTexCoord.z > tex2D(DepthMap2,float2(vShadowTexCoord.x+fTS+fTS,vShadowTexCoord.y-fTS)).x ? 1.0f : 0.0f;
        // fPercentLit += vShadowTexCoord.z > tex2D(DepthMap2,float2(vShadowTexCoord.x+fTS,vShadowTexCoord.y)).x ? 1.0f : 0.0f;
        // fPercentLit += vShadowTexCoord.z > tex2D(DepthMap2,float2(vShadowTexCoord.x+fTS+fTS,vShadowTexCoord.y)).x ? 1.0f : 0.0f;
        // fPercentLit += vShadowTexCoord.z > tex2D(DepthMap2,float2(vShadowTexCoord.x,vShadowTexCoord.y+fTS)).x ? 1.0f : 0.0f;
        // fPercentLit += vShadowTexCoord.z > tex2D(DepthMap2,float2(vShadowTexCoord.x+fTS,vShadowTexCoord.y+fTS)).x ? 1.0f : 0.0f;
        // fPercentLit += vShadowTexCoord.z > tex2D(DepthMap2,float2(vShadowTexCoord.x+fTS+fTS,vShadowTexCoord.y+fTS)).x ? 1.0f : 0.0f;
      }
      else
      {
         if ( iCurrentCascadeIndex==2 )
         {
           // test dither with random offsets.
           float2 o = fmod(floor(mwpos), 1.50) * 0.25;
           fPercentLit += vShadowTexCoord.z > tex2D(DepthMap3,float2(vShadowTexCoord.x,vShadowTexCoord.y)+(  (float2(-0.75, 0.75) + o) *fTS)  ).x ? 1.0f : 0.0f;
           fPercentLit += vShadowTexCoord.z > tex2D(DepthMap3,float2(vShadowTexCoord.x,vShadowTexCoord.y)+(  (float2( 0.25, 0.75) + o) *fTS)  ).x ? 1.0f : 0.0f;
           fPercentLit += vShadowTexCoord.z > tex2D(DepthMap3,float2(vShadowTexCoord.x,vShadowTexCoord.y)+(  (float2(-0.75,-0.25) + o) *fTS)  ).x ? 1.0f : 0.0f;
           fPercentLit += vShadowTexCoord.z > tex2D(DepthMap3,float2(vShadowTexCoord.x,vShadowTexCoord.y)+(  (float2( 0.25,-0.25) + o) *fTS)  ).x ? 1.0f : 0.0f;
           fPercentLit += vShadowTexCoord.z > tex2D(DepthMap3,float2(vShadowTexCoord.x,vShadowTexCoord.y)+(  (float2( 0.75,-0.75) + o) *fTS)  ).x ? 1.0f : 0.0f;
           fPercentLit *= 0.20;

           // fPercentLit += vShadowTexCoord.z > tex2D(DepthMap3,float2(vShadowTexCoord.x,vShadowTexCoord.y)).x ? 1.0f : 0.0f;
           // fPercentLit += vShadowTexCoord.z > tex2D(DepthMap3,float2(vShadowTexCoord.x,vShadowTexCoord.y-fTS)).x ? 1.0f : 0.0f;
           // fPercentLit += vShadowTexCoord.z > tex2D(DepthMap3,float2(vShadowTexCoord.x+fTS,vShadowTexCoord.y-fTS)).x ? 1.0f : 0.0f;
           // fPercentLit += vShadowTexCoord.z > tex2D(DepthMap3,float2(vShadowTexCoord.x+fTS+fTS,vShadowTexCoord.y-fTS)).x ? 1.0f : 0.0f;
           // fPercentLit += vShadowTexCoord.z > tex2D(DepthMap3,float2(vShadowTexCoord.x+fTS,vShadowTexCoord.y)).x ? 1.0f : 0.0f;
           // fPercentLit += vShadowTexCoord.z > tex2D(DepthMap3,float2(vShadowTexCoord.x+fTS+fTS,vShadowTexCoord.y)).x ? 1.0f : 0.0f;
           // fPercentLit += vShadowTexCoord.z > tex2D(DepthMap3,float2(vShadowTexCoord.x,vShadowTexCoord.y+fTS)).x ? 1.0f : 0.0f;
           // fPercentLit += vShadowTexCoord.z > tex2D(DepthMap3,float2(vShadowTexCoord.x+fTS,vShadowTexCoord.y+fTS)).x ? 1.0f : 0.0f;
           // fPercentLit += vShadowTexCoord.z > tex2D(DepthMap3,float2(vShadowTexCoord.x+fTS+fTS,vShadowTexCoord.y+fTS)).x ? 1.0f : 0.0f;
         }
         else
         {
            if ( iCurrentCascadeIndex==3 )
            {
              // test dither with random offsets.
              float2 o = fmod(floor(mwpos), 1.50) * 0.25;
              fPercentLit += vShadowTexCoord.z > tex2D(DepthMap4,float2(vShadowTexCoord.x,vShadowTexCoord.y)+(  (float2(-0.75, 0.75) + o) *fTS)  ).x ? 1.0f : 0.0f;
              fPercentLit += vShadowTexCoord.z > tex2D(DepthMap4,float2(vShadowTexCoord.x,vShadowTexCoord.y)+(  (float2( 0.25, 0.75) + o) *fTS)  ).x ? 1.0f : 0.0f;
              fPercentLit += vShadowTexCoord.z > tex2D(DepthMap4,float2(vShadowTexCoord.x,vShadowTexCoord.y)+(  (float2(-0.75,-0.25) + o) *fTS)  ).x ? 1.0f : 0.0f;
              fPercentLit += vShadowTexCoord.z > tex2D(DepthMap4,float2(vShadowTexCoord.x,vShadowTexCoord.y)+(  (float2( 0.25,-0.25) + o) *fTS)  ).x ? 1.0f : 0.0f;
              fPercentLit += vShadowTexCoord.z > tex2D(DepthMap4,float2(vShadowTexCoord.x,vShadowTexCoord.y)+(  (float2( 0.75,-0.75) + o) *fTS)  ).x ? 1.0f : 0.0f;
              fPercentLit *= 0.20;


              // fPercentLit += vShadowTexCoord.z > tex2D(DepthMap4,float2(vShadowTexCoord.x,vShadowTexCoord.y)).x ? 1.0f : 0.0f;
              // fPercentLit += vShadowTexCoord.z > tex2D(DepthMap4,float2(vShadowTexCoord.x,vShadowTexCoord.y-fTS)).x ? 1.0f : 0.0f;
              // fPercentLit += vShadowTexCoord.z > tex2D(DepthMap4,float2(vShadowTexCoord.x+fTS,vShadowTexCoord.y-fTS)).x ? 1.0f : 0.0f;
              // fPercentLit += vShadowTexCoord.z > tex2D(DepthMap4,float2(vShadowTexCoord.x+fTS+fTS,vShadowTexCoord.y-fTS)).x ? 1.0f : 0.0f;
              // fPercentLit += vShadowTexCoord.z > tex2D(DepthMap4,float2(vShadowTexCoord.x+fTS,vShadowTexCoord.y)).x ? 1.0f : 0.0f;
              // fPercentLit += vShadowTexCoord.z > tex2D(DepthMap4,float2(vShadowTexCoord.x+fTS+fTS,vShadowTexCoord.y)).x ? 1.0f : 0.0f;
              // fPercentLit += vShadowTexCoord.z > tex2D(DepthMap4,float2(vShadowTexCoord.x,vShadowTexCoord.y+fTS)).x ? 1.0f : 0.0f;
              // fPercentLit += vShadowTexCoord.z > tex2D(DepthMap4,float2(vShadowTexCoord.x+fTS,vShadowTexCoord.y+fTS)).x ? 1.0f : 0.0f;
              // fPercentLit += vShadowTexCoord.z > tex2D(DepthMap4,float2(vShadowTexCoord.x+fTS+fTS,vShadowTexCoord.y+fTS)).x ? 1.0f : 0.0f;
            }
         }
      }
   }
   //fPercentLit /= 9.0f;
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
    fCurrentPixelsBlendBandLocation = fPixelDepth / fBlendInterval;
    fCurrentPixelsBlendBandLocation = 1.0f - fCurrentPixelsBlendBandLocation;
   
    // The fBlendBetweenCascadesAmount is our location in the blend band.
    fBlendBetweenCascadesAmount = fCurrentPixelsBlendBandLocation / m_fCascadeBlendArea;
}

/*******Main Vertex Shader***************************/

vertexOutput mainVS(appdata IN)   
{
    vertexOutput OUT;
    float4 worldSpacePos = mul(float4(IN.Position.xyz + IN.Normal.xyz,1), World);   
    float4 cameraPos = mul( worldSpacePos, View );
    OUT.Position = mul(cameraPos, Projection);
    OUT.WPos =   worldSpacePos;
    OUT.TexCoord  = IN.UV; 
    OUT.WorldEyeVec = (ViewInverse[3].xyz - worldSpacePos.xyz);   
       
    // calculate Water FOG colour
    float fogstrength = cameraPos.z * FogColor.w;
    OUT.WaterFog = min(fogstrength,1.0);
        
    // all shaders should send the clip value to the pixel shader (for refr/refl)                                                                     
    OUT.clip = dot(worldSpacePos, clipPlane);                                                                      
  
    // SHADOW MAPPING - world position and projected depth (for cascade distance calc)
    OUT.vDepth = mul( cameraPos, Projection ).z; 
  
    return OUT;
}

float4 mainPS(vertexOutput IN) : COLOR
{
    float4 finalcolor;
    //clip(IN.clip); // all shaders should receive the clip value  
    //clip( IN.vDepth < 2750.0f ? -1:1 ); // do not render within certain range
    
    float4 diffusemap = tex2D(DiffuseSampler,IN.TexCoord.xy);    //sample diffuse texture  
    
    //contributions
    float4 diffuseContrib = diffusemap;

   // shadow mapping code
   float fShadow = 0.0f;
    float4 vShadowMapTextureCoord = 0.0f;
    float4 vShadowMapTextureCoord_blend = 0.0f;
    float fPercentLit = 0.0f;
    float fPercentLit_blend = 0.0f;
    float fUpTextDepthWeight=0;
    float fRightTextDepthWeight=0;
    float fUpTextDepthWeight_blend=0;
    float fRightTextDepthWeight_blend=0;

    // The interval based selection technique compares the pixel's depth against the frustum's cascade divisions.
    float fCurrentPixelDepth;
    fCurrentPixelDepth = IN.vDepth;
    int iCurrentCascadeIndex;
   iCurrentCascadeIndex = 3;
   if ( fCurrentPixelDepth < m_fCascadeFrustumsEyeSpaceDepths[2] ) iCurrentCascadeIndex = 2;
   if ( fCurrentPixelDepth < m_fCascadeFrustumsEyeSpaceDepths[1] ) iCurrentCascadeIndex = 1;
   if ( fCurrentPixelDepth < m_fCascadeFrustumsEyeSpaceDepths[0] ) iCurrentCascadeIndex = 0;

   // Repeat text coord calculations for the next cascade - the next cascade index is used for blurring between maps.
    int iNextCascadeIndex = 1;
   iNextCascadeIndex = min ( 4 - 1, iCurrentCascadeIndex + 1 ); 
    float fBlendBetweenCascadesAmount = 1.0f;
    float fCurrentPixelsBlendBandLocation = 1.0f;
    CalculateBlendAmountForInterval ( iCurrentCascadeIndex, fCurrentPixelDepth, 
      fCurrentPixelsBlendBandLocation, fBlendBetweenCascadesAmount );
       
   // World out texture coordinate into specified shadow map
   float4 finalwpos = IN.WPos;
    ComputeCoordinatesTransform( iCurrentCascadeIndex, 
                                 finalwpos, 
                                 vShadowMapTextureCoord );    

   // work out how much shadow
    CalculatePCFPercentLit ( iCurrentCascadeIndex, vShadowMapTextureCoord, fRightTextDepthWeight, 
                             fUpTextDepthWeight, finalwpos.xz, fShadow );
                      
   if( fCurrentPixelsBlendBandLocation < m_fCascadeBlendArea ) 
   {  
      // the current pixel is within the blend band.
      // Repeat text coord calculations for the next cascade. 
      // The next cascade index is used for blurring between maps.
      ComputeCoordinatesTransform( iNextCascadeIndex, finalwpos, 
                            vShadowMapTextureCoord_blend );  
   
      // the current pixel is within the blend band.
      CalculatePCFPercentLit ( iNextCascadeIndex, vShadowMapTextureCoord_blend, fRightTextDepthWeight_blend, 
                        fUpTextDepthWeight_blend, finalwpos.xz, fPercentLit_blend );
                        
      // Blend the two calculated shadows by the blend amount.
      fShadow = lerp( fPercentLit_blend, fShadow, fBlendBetweenCascadesAmount ); 
   }
      
   // finally modulate shadow with strength
   fShadow = fShadow * ShadowStrength;  
   
   diffuseContrib.xyz = diffuseContrib.xyz * (1.0-(fShadow*0.65f));
   
    float3 Vn = normalize(IN.WorldEyeVec);
    AmbiColor*=AmbiColorOverride;
    
    float4 result = diffuseContrib + (diffusemap * AmbiColor );
    
    //calculate hud pixel-fog
    float4 cameraPos = mul(IN.WPos, View);
    float hudfogfactor = saturate((cameraPos.z- HudFogDist.x)/(HudFogDist.y - HudFogDist.x));
    
    //Mix in HUD Fog with final color;
    float4 hudfogresult = lerp(result,HudFogColor,hudfogfactor);
    
    //And Finally add in any Water Fog   
    float4 waterfogresult = lerp(hudfogresult,FogColor,IN.WaterFog);   
    
    finalcolor = float4(waterfogresult); 
   finalcolor.xyz = diffusemap.xyz;
    finalcolor.a = diffusemap.a; 
          
    return finalcolor;
}

float4 blackPS(vertexOutput IN) : COLOR
{
    //clip(IN.clip); // all shaders should receive the clip value  
   return float4(0,0,0,tex2D(DiffuseSampler,IN.TexCoord.xy).a);
}

/****** technique *****************************************************************************/

technique dx9textured
{
    pass P0
    {
        // shaders
        VertexShader = compile vs_3_0 mainVS();
        PixelShader  = compile ps_3_0 mainPS();
        CullMode = ccw;
        alphafunc=greater;
      alpharef=128 ;
        AlphaBlendEnable = FALSE;
        AlphaTestEnable = true;
    }
}

technique DepthMap
{
    pass p0
    {      
        VertexShader = compile vs_3_0 mainVS();
        PixelShader  = compile ps_3_0 blackPS();
        CullMode = None;
        alphafunc=greater;
      alpharef=128 ;
        AlphaBlendEnable = FALSE;
        AlphaTestEnable = true;
   }
}

technique blacktextured
{
    pass P0
    {
        // shaders
        VertexShader = compile vs_3_0 mainVS();
        PixelShader  = compile ps_3_0 blackPS();
        CullMode = ccw;
        alphafunc=greater;
      alpharef=128 ;
        AlphaBlendEnable = FALSE;
        AlphaTestEnable = true;
    }
}
