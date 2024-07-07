string Description = "Static Character Shader (copied from character_basic)";
#include "settings.fx"
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

float GlobalSpecular
<    string UIName =  "GlobalSpecular";    
> = {0.5f};

float GlobalSurfaceIntensity
<    string UIName =  "GlobalSurfaceIntensity";    
> = {1.0f};

// general
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

float4x4 boneMatrix[60] : BoneMatrixPalette;
float4 eyePos : CameraPosition;
float time : Time;
float sintime : SinTime;

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

float4 AmbiColor : Ambient
<    string UIName =  "AmbiColor";    
> = {0.5f, 0.5f, 0.5f, 1.0f};

float4 AmbiColorOverride
<    string UIName =  "AmbiColorOverride";    
> = {1.0f, 1.0f, 1.0f, 1.0f};

float alphaoverride  : alphaoverride;

float4 SurfColor : Diffuse
<    string UIName =  "SurfColor";    
> = {1.0f, 1.0f, 1.0f, 1.0f};

float4 SkyColor : Diffuse
<    string UIName =  "SkyColor";    
> = {1.0, 1.0, 1.0, 1.0f};

float4 FloorColor : Diffuse
<    string UIName =  "FloorColor";    
> = {1.0, 1.0, 1.00, 1.0f};

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


//Shader Variables pulled from FPI scripting 
float4 ShaderVariables : ShaderVariables
<    string UIName =  "Shader Variables";    
> = {1.0f, 1.0f, 1.0f, 1.0f};

//Character Creator Skin Tone
float4 ColorTone[4] : Diffuse
<   string UIName =  "Color Tone";    
> = {
   float4(-1.0f, 1.0f, 1.0f, 1.0f),
   float4(-1.0f, 1.0f, 1.0f, 1.0f),
   float4(-1.0f, 1.0f, 1.0f, 1.0f),
   float4(-1.0f, 1.0f, 1.0f, 1.0f)
};

//Character Creator Tone Mix
float ToneMix[4] : Diffuse
<   string UIName =  "Color Tone";    
> = {
   float(0.5f),
   float(0.5f),
   float(0.5f),
   float(0.5f)
};

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
float  g_lights_num;

//FloorPositionY.x holds the shadow offset value which places the shadow at character's feet
float4 FloorPositionY : Diffuse
<
> = { 0.000000, 0.000000, 0.000000, 0.000000 };


/************* TEXTURES AND SAMPLERS **************/

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
texture SpecularMap : SpecularMap
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


sampler2D DiffuseMapSampler = sampler_state
{
   Texture = <DiffuseMap>;
   MinFilter = LINEAR;
   MagFilter = LINEAR;
   MipFilter = LINEAR;
};

sampler2D OccSampler = sampler_state
{
    Texture   = <OcclusionMap>;
    MipFilter = LINEAR;
    MinFilter = ANISOTROPIC;
    MagFilter = LINEAR;
};

sampler2D NormalMapSampler = sampler_state
{
   Texture = <NormalMap>;
   MinFilter = LINEAR;
   MagFilter = LINEAR;
   MipFilter = LINEAR;
};

sampler2D SpecularMapSampler = sampler_state
{
   Texture = <SpecularMap>;
   MinFilter = LINEAR;
   MagFilter = LINEAR;
   MipFilter = LINEAR;
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


/************* DATA STRUCTS **************/

struct appdata
{
    float3 Position    : POSITION;
    float2 UV          : TEXCOORD0;
    float4 Normal      : NORMAL;
    float4 Tangent     : TANGENT0;
    float4 Binormal    : BINORMAL0;
    float4 Blendweight   : TEXCOORD1;
    float4 Blendindices   : TEXCOORD2;
};


/* data passed from vertex shader to pixel shader */
struct vertexOutput
{
    float4 HPosition   : POSITION;
    float2 TexCoord       : TEXCOORD0;
    float3 LightVec       : TEXCOORD1;
    float3 WorldNormal   : TEXCOORD2;    
    float3 WorldTangent   : TEXCOORD3;
    float3 WorldBinormal: TEXCOORD4;
    float4 WPos         : TEXCOORD5;
    float  clip         : TEXCOORD6;    
    float2 vDepth       : TEXCOORD7;
};
struct vertexOutput_low
{
    float4 HPosition   : POSITION;
    float2 TexCoord       : TEXCOORD0;
    float3 LightVec       : TEXCOORD1;
    float3 WorldNormal   : TEXCOORD2;    
    float4 WPos         : TEXCOORD3;
    float clip          : TEXCOORD4;    
};

struct shadow_vs_out
{
   float4 pos  : POSITION;
   float3 WPos : TEXCOORD6;   
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

void CalculateRightAndUpTexelDepthDeltas ( in float3 vShadowTexDDX,
                                           in float3 vShadowTexDDY,
                                           out float fUpTextDepthWeight,
                                           out float fRightTextDepthWeight )
{
   // This function calculates the screen space depth for shadow space texels    
    // We use the derivatives in X and Y to create a transformation matrix.  Because these derivives give us the 
    // transformation from screen space to shadow space, we need the inverse matrix to take us from shadow space 
    // to screen space.  This new matrix will allow us to map shadow map texels to screen space.  This will allow 
    // us to find the screen space depth of a corresponding depth pixel.
    // This is not a perfect solution as it assumes the underlying geometry of the scene is a plane.  A more 
    // accureate way of finding the actual depth would be to do a deferred rendering approach and actually 
    // sample the depth (ca-ching dudes!)
    // Using an offset, or using variance shadow maps is a better approach to reducing these artifacts in most cases.
    
    float2x2 matScreentoShadow = float2x2( vShadowTexDDX.xy, vShadowTexDDY.xy );
    float fDeterminant = determinant ( matScreentoShadow );
    
    float fInvDeterminant = 1.0f / fDeterminant;
    
    float2x2 matShadowToScreen = float2x2 (
        matScreentoShadow._22 * fInvDeterminant, matScreentoShadow._12 * -fInvDeterminant, 
        matScreentoShadow._21 * -fInvDeterminant, matScreentoShadow._11 * fInvDeterminant );

    float2 vRightShadowTexelLocation = float2( m_fTexelSize, 0.0f );
    float2 vUpShadowTexelLocation = float2( 0.0f, m_fTexelSize );  
    
    // Transform the right pixel by the shadow space to screen space matrix.
    float2 vRightTexelDepthRatio = mul( vRightShadowTexelLocation,  matShadowToScreen );
    float2 vUpTexelDepthRatio = mul( vUpShadowTexelLocation,  matShadowToScreen );

    // We can now caculate how much depth changes when you move up or right in the shadow map.
    // We use the ratio of change in x and y times the dervivite in X and Y of the screen space 
    // depth to calculate this change.
    fUpTextDepthWeight = 
        vUpTexelDepthRatio.x * vShadowTexDDX.z 
        + vUpTexelDepthRatio.y * vShadowTexDDY.z;
    fRightTextDepthWeight = 
        vRightTexelDepthRatio.x * vShadowTexDDX.z 
        + vRightTexelDepthRatio.y * vShadowTexDDY.z;  
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
   // and avoid shadow swim when animating by using no filter
   vShadowTexCoord.z -= 0.0003f;
         
   float fTS = (1.0f/1024.0f);//m_fTexelSize;
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
      //for ( int p=0; p<64; p+=4 )
      //{
      //   fPercentLit += vShadowTexCoord.z > tex2D(DepthMap1,float2(vShadowTexCoord.x,vShadowTexCoord.y)+(PoissonSamples[p]*fTS)).x ? 1.0f : 0.0f;
      //}
      //fPercentLit /= 16.0f;
   }
   else
   {
      if ( iCurrentCascadeIndex==1 )
      {
         fPercentLit += vShadowTexCoord.z > tex2D(DepthMap2,float2(vShadowTexCoord.x,vShadowTexCoord.y)).x ? 1.0f : 0.0f;
      }
      else
      {
         if ( iCurrentCascadeIndex==2 )
         {
            fPercentLit += vShadowTexCoord.z > tex2D(DepthMap3,float2(vShadowTexCoord.x,vShadowTexCoord.y)).x ? 1.0f : 0.0f;
         }
         else
         {
            if ( iCurrentCascadeIndex==3 && vShadowTexCoord.z<1.0 )
            {
               fPercentLit += vShadowTexCoord.z > tex2D(DepthMap4,float2(vShadowTexCoord.x,vShadowTexCoord.y)).x ? 1.0f : 0.0f;
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

/******************MAIN CHARACTER VERTEX SHADER****************************************/

vertexOutput mainVS_highest(appdata IN)
{
    vertexOutput OUT;
   
    float3 netPosition = 0, netNormal = 0;
    for (int i = 0; i < 4; i++)
    {
     float index = IN.Blendindices[i];
     float3x4 model = float3x4(boneMatrix[index][0], boneMatrix[index][1], boneMatrix[index][2]);     
     float3 vec3 = mul(model, float4(IN.Position, 1));
     vec3 = vec3 + boneMatrix[index][3].xyz;
     float3x3 rotate = float3x3(model[0].xyz, model[1].xyz, model[2].xyz); 
     float3 norm3 = mul(rotate, IN.Normal);
     netPosition += vec3.xyz * IN.Blendweight[i];
     netNormal += norm3.xyz * IN.Blendweight[i];
    }

    float4 tempPos = float4(netPosition,1.0);
    netNormal = normalize(netNormal);
    
    OUT.WorldNormal = mul(netNormal, WorldIT).xyz;
    OUT.WorldTangent = mul(IN.Tangent, WorldIT).xyz;
    OUT.WorldBinormal = mul(IN.Binormal, WorldIT).xyz;
    
    float3 worldSpacePos = mul(tempPos, World).xyz;
    OUT.WPos = float4(worldSpacePos.xyz,1);
    
    OUT.LightVec = normalize(LightSource);
       
    OUT.TexCoord = IN.UV;
    OUT.HPosition = mul(tempPos, WorldViewProjection);
        
    // all shaders should send the clip value to the pixel shader (for refr/refl)
    OUT.clip = (worldSpacePos.y * clipPlane.y) + clipPlane.a; // good for water plane
    
    // SHADOW MAPPING - world position and projected depth (for cascade distance calc)
    OUT.vDepth.x = mul( tempPos, WorldViewProjection ).z; 

   // defeat projective aliasing by detecting when parallel to light direction
   OUT.vDepth.y = max(0,abs(dot(OUT.LightVec, OUT.WorldNormal))-0.25f)*1.333f;
   
    return OUT;
}

vertexOutput_low mainVS_lowest(appdata IN)
{
    vertexOutput_low OUT;
    float3 netPosition = 0, netNormal = 0;
    for (int i = 0; i < 4; i++)
    {
     float index = IN.Blendindices[i];
     float3x4 model = float3x4(boneMatrix[index][0], boneMatrix[index][1], boneMatrix[index][2]);     
     float3 vec3 = mul(model, float4(IN.Position, 1));
     vec3 = vec3 + boneMatrix[index][3].xyz;
     float3x3 rotate = float3x3(model[0].xyz, model[1].xyz, model[2].xyz); 
     float3 norm3 = mul(rotate, IN.Normal);
     netPosition += vec3.xyz * IN.Blendweight[i];
     netNormal += norm3.xyz * IN.Blendweight[i];
    }
    float4 tempPos = float4(netPosition,1.0);
   OUT.WorldNormal = normalize(mul(IN.Normal, WorldIT).xyz);
   OUT.LightVec = normalize(LightSource);
    OUT.TexCoord = IN.UV;
    OUT.HPosition = mul(tempPos, WorldViewProjection);
    float4 worldSpacePos = mul(tempPos, World);
   OUT.WPos = float4(worldSpacePos.xyz,1);
    OUT.clip = (worldSpacePos.y * clipPlane.y) + clipPlane.a; // good for water plane
    return OUT;
}

vertexOutput_low mainVS_lowest_noanim(appdata IN)
{
    vertexOutput_low OUT;
   float3 tempXYZ = IN.Position.xyz;
    float4 tempPos = float4(tempXYZ,1.0);
   OUT.WorldNormal = float3(0,0,0);
   OUT.LightVec = float3(0,0,0);
    OUT.TexCoord = IN.UV;
    OUT.HPosition = mul(tempPos, WorldViewProjection);
    float4 worldSpacePos = mul(tempPos, World);
   OUT.WPos = worldSpacePos;
    OUT.clip = (worldSpacePos.y * clipPlane.y) + clipPlane.a; // good for water plane
    return OUT;
}

/*************SPOTFLASH FUNCTION**************************************************/

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
    output += (SpotFlashColor) *fAtten * (SpotFlashPos.w) * max(0,dot(worldNormal,lightDir));
        
    return output;
}

/*************DYNAMIC LIGHTING FUNCTION**************************************************/

float4 CalcLighting(float3 Nb, float3 worldPos, float3 Vn, float4 diffusemap,float4 specmap)
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
       float4 local_lights_atten0 = float4(1.0, 1.0/g_lights_pos0.w, 1.0/(g_lights_pos0.w*g_lights_pos0.w), 0.0);
       //float fAtten = 1.0/dot( g_lights_atten0, float4(1,lightDist,lightDist*lightDist,0) ); // NVIDIA 361 bug
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
       float4 local_lights_atten1 = float4(1.0, 1.0/g_lights_pos1.w, 1.0/(g_lights_pos1.w*g_lights_pos1.w), 0.0);
       //fAtten = 1.0/dot( g_lights_atten1, float4(1,lightDist,lightDist*lightDist,0) ); // NVIDIA 361 bug
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
       float4 local_lights_atten2 = float4(1.0, 1.0/g_lights_pos2.w, 1.0/(g_lights_pos2.w*g_lights_pos2.w), 0.0);
       //fAtten = 1.0/dot( g_lights_atten2, float4(1,lightDist,lightDist*lightDist,0) ); // NVIDIA 361 bug
       fAtten = 1.0/dot( local_lights_atten2, float4(1,lightDist,lightDist*lightDist,0) );
       lightDir = normalize( toLight );
       halfvec = normalize(Vn + lightDir);
       lit0 = lit(dot(lightDir,Nb),dot(halfvec,Nb),24); 
       output+= (lit0.y *g_lights_diffuse2 * fAtten * 1.7*diffusemap) + (lit0.z * g_lights_diffuse2 * fAtten *specmap );   
//    }   
    return output;
}

/*******************MAIN CHARACTER PIXEL SHADER*******************************************/

float4 mainPS_highest(vertexOutput IN) : COLOR
{
   // clip
    clip(IN.clip);
   
   // get texture reference
    float4 diffusemap = tex2D(DiffuseMapSampler,IN.TexCoord.xy);
    float4 normalmap = tex2D(NormalMapSampler,IN.TexCoord.xy) * 2 - 1;
    float4 specmap = tex2D(SpecularMapSampler,IN.TexCoord.xy);
    float4 illummap = tex2D(IllumSampler,IN.TexCoord.xy);

   // Character Creator Stuff
    float4 maskmap = tex2D(MaskSampler,IN.TexCoord.xy);
   amountfromMask[0] = maskmap.r * ToneMix[0];
   amountfromMask[1] = maskmap.g * ToneMix[1];
   amountfromMask[2] = maskmap.b * ToneMix[2];
   amountfromMask[3] = maskmap.a * ToneMix[3];
   for ( int c = 0 ; c < 4 ; c++ )
   {
      if ( amountfromMask[c] > 0.0 && ColorTone[c].r >= 0.0f )
      {
         amountfromPixel[c] = 1.0f - amountfromMask[c];
         diffusemap = (diffusemap * amountfromPixel[c]) + (ColorTone[c] * amountfromMask[c]);
      }
   }   
   // End of Character Creator Stuff
   
   // normal from normpp/tanegtn
    float3 Nn = (IN.WorldNormal);
    float3 Tn = (IN.WorldTangent);
    float3 Bn = (IN.WorldBinormal);
    float3 Nb = (normalmap.z * Nn) + ((normalmap.x * Tn + normalmap.y * Bn));
    Nb = normalize(Nb);
   
   // lighting
    float3 Ln = normalize(IN.LightVec);
    float3 V  = (eyePos - IN.WPos.xyz);  
    float3 Vn  = normalize(V); 
    float3 Hn = normalize(Vn+Ln);
    float4 lighting = lit(dot(Ln,Nb),dot(Hn,Nb),24);
   
   // dynamic lighting
    float4 spotflashlighting = CalcSpotFlash (Nb,IN.WPos.xyz);   
    float4 dynamicContrib = CalcLighting (Nb,IN.WPos.xyz,Vn,diffusemap,specmap) + spotflashlighting;  

   // flash light system (flash light control carried in SpotFlashColor.w )
   float conewidth = 24;
    float4 viewspacePos = mul(IN.WPos, View);
    float intensity = max(0, 1.5f - (viewspacePos.z/500.0f));
   float3 lightvector = Vn;
    float3 lightdir = float3(View._m02,View._m12,View._m22);
    float flashlight = pow(max(dot(-lightvector, lightdir),0),conewidth) * intensity * SpotFlashColor.w;   
   dynamicContrib.xyz = dynamicContrib.xyz + (diffusemap.xyz*float3(flashlight,flashlight,flashlight));

   // paint
   float4 diffuseContrib = SurfColor * diffusemap * lighting.y * 0.61 * GlobalSurfaceIntensity; // 0.61 match static lightmap direct lighting effect
    float4 specContrib = lighting.z * specmap * SurfColor * GlobalSpecular;

   // spherical ambience
   float fSkyFloorRatio = (1+dot(IN.WorldNormal.xyz,float3(0,1,0)))/2;
   float3 bouncelightcolor = lerp(FloorColor,SkyColor,fSkyFloorRatio) * diffusemap.xyz * 0.8;
   bouncelightcolor = bouncelightcolor + (diffusemap.xyz * 0.2);
    float4 ambContrib = (float4(bouncelightcolor,1) * (AmbiColor+illummap.x) * AmbiColorOverride) * 2;
   
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
    fCurrentPixelDepth = IN.vDepth.x;
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
   float4 finalwpos = float4(IN.WPos.xyz,1);
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
   
   // finally modulate shadow with strength (IN.vDepth.y ensures no projective aliasing!) (cap at 0.6 to mimic PREBAKE blend)
   fShadow = min(fShadow * ShadowStrength * IN.vDepth.y, 0.6f);
   
   // inverse to modulate surface lighting (and only shadow surfaces facing sunlight)
   fShadow = fShadow * dot(Ln,Nb);
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
    hudfogresult.a = diffusemap.a * alphaoverride;    
   
   // result
   return hudfogresult;
}

float4 mainPS_medium(vertexOutput_low IN) : COLOR
{
   // clip
    clip(IN.clip);
   
   // lighting
    float3 Ln = normalize(IN.LightVec);
    float3 V  = (eyePos - IN.WPos);  
    float3 Vn  = normalize(V); 
    float3 Hn = normalize(Vn+Ln);
    float4 lighting = lit(dot(Ln,IN.WorldNormal),dot(Hn,IN.WorldNormal),24);
   
   // CHEAPEST flash light system (flash light control carried in SpotFlashColor.w )
    float4 viewspacePos = mul(IN.WPos, View);
    float flashlight = (1.0f-min(1,viewspacePos.z/300.0f)) * SpotFlashColor.w;   
   
   // paint
    float4 diffusemap = tex2D(DiffuseMapSampler,IN.TexCoord.xy);

   // Character Creator Stuff

    float4 maskmap = tex2D(MaskSampler,IN.TexCoord.xy);

   amountfromMask[0] = maskmap.r * ToneMix[0];
   amountfromMask[1] = maskmap.g * ToneMix[1];
   amountfromMask[2] = maskmap.b * ToneMix[2];
   amountfromMask[3] = maskmap.a * ToneMix[3];

   for ( int c = 0 ; c < 4 ; c++ )
   {
      if ( amountfromMask[c] > 0.0 && ColorTone[c].r >= 0.0f )
      {
         amountfromPixel[c] = 1.0f - amountfromMask[c];
         diffusemap = (diffusemap * amountfromPixel[c]) + (ColorTone[c] * amountfromMask[c]);
      }
   }

   // End of Character Creator Stuff

   float4 diffuseContrib = SurfColor * (diffusemap * (lighting.y+flashlight) * 0.61 * GlobalSurfaceIntensity); // 0.61 match static lightmap direct lighting effect
    float4 dynamicContrib = CalcSpotFlash(IN.WorldNormal.xyz,IN.WPos.xyz) + GlowIntensity;   

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
    hudfogresult.a = diffusemap.a * alphaoverride;    
   
   // result
    return hudfogresult;
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
   
   // CHEAPEST flash light system (flash light control carried in SpotFlashColor.w )
    float4 viewspacePos = mul(IN.WPos, View);
    float flashlight = (1.0f-min(1,viewspacePos.z/300.0f)) * SpotFlashColor.w;   
   
   // paint
    float4 diffusemap = tex2D(DiffuseMapSampler,IN.TexCoord.xy);

   // Character Creator Stuff

    float4 maskmap = tex2D(MaskSampler,IN.TexCoord.xy);

   amountfromMask[0] = maskmap.r * ToneMix[0];
   amountfromMask[1] = maskmap.g * ToneMix[1];
   amountfromMask[2] = maskmap.b * ToneMix[2];
   amountfromMask[3] = maskmap.a * ToneMix[3];

   for ( int c = 0 ; c < 4 ; c++ )
   {
      if ( amountfromMask[c] > 0.0 && ColorTone[c].r >= 0.0f )
      {
         amountfromPixel[c] = 1.0f - amountfromMask[c];
         diffusemap = (diffusemap * amountfromPixel[c]) + (ColorTone[c] * amountfromMask[c]);
      }
   }   

   // End of Character Creator Stuff

   float4 diffuseContrib = SurfColor * (diffusemap * (lighting.y+flashlight) * 0.61 * GlobalSurfaceIntensity); // 0.61 match static lightmap direct lighting effect

   // spherical ambience
   float fSkyFloorRatio = (1+dot(IN.WorldNormal.xyz,float3(0,1,0)))/2;
   float3 bouncelightcolor = lerp(FloorColor,SkyColor,fSkyFloorRatio) * diffusemap.xyz * 0.8;
   bouncelightcolor = bouncelightcolor + (diffusemap.xyz * 0.2);
    float4 ambContrib = float4(bouncelightcolor,1) * AmbiColor * AmbiColorOverride * 2;
    float4 result = diffuseContrib + ambContrib + GlowIntensity;
   
   //calculate hud pixel-fog
    float4 cameraPos = mul(IN.WPos, View);
    float hudfogfactor = saturate((cameraPos.z- HudFogDist.x)/(HudFogDist.y - HudFogDist.x));
    float4 hudfogresult = lerp(result,float4(HudFogColor.xyz,0),hudfogfactor*HudFogColor.w);
   
   // original entity diffuse alpha with override
    hudfogresult.a = diffusemap.a * alphaoverride;    
   
   // result
    return hudfogresult;
}

float4 mainPS_distant(vertexOutput_low IN) : COLOR
{
   // clip
    clip(IN.clip);
   
   // result
    return float4(1,1,1,1);
}

float4 blackPS(vertexOutput_low IN) : COLOR
{
    clip(IN.clip); // all shaders should receive the clip value  
    return float4(0,0,0,tex2D(DiffuseMapSampler,IN.TexCoord.xy).a);
}

/****** render depth information ***************/

vertexOutput_low mainVS_renderdepth(appdata IN)   
{
    vertexOutput_low OUT;
   
    float3 netPosition = 0;
    for (int i = 0; i < 4; i++)
    {
     float index = IN.Blendindices[i];
     float3x4 model = float3x4(boneMatrix[index][0], boneMatrix[index][1], boneMatrix[index][2]);     
     float3 vec3 = mul(model, float4(IN.Position, 1));
     vec3 = vec3 + boneMatrix[index][3].xyz;
     netPosition += vec3.xyz * IN.Blendweight[i];
    }
    float4 tempPos = float4(netPosition,1.0);
    OUT.HPosition = mul(tempPos, WorldViewProjection);
    OUT.LightVec = float3(0,0,0);
    OUT.WorldNormal = float3(0,0,0);
    OUT.TexCoord = IN.UV;
    float4 worldSpacePos = mul(tempPos, World);
    OUT.clip = dot(worldSpacePos, clipPlane);
   worldSpacePos.xyz *= DepthWriteMode;
   worldSpacePos.w = 7000-mul( tempPos, WorldView ).z;
    OUT.WPos = worldSpacePos;  
    return OUT;
}   
float4 mainPS_renderdepth(vertexOutput_low IN) : COLOR
{
    clip(IN.clip);
   clip(tex2D(DiffuseMapSampler,IN.TexCoord.xy).a-0.5);
   return IN.WPos.wxyz;
}

technique Static
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
        VertexShader = compile vs_3_0 mainVS_lowest_noanim();
        PixelShader  = compile ps_3_0 mainPS_lowest();
        alphafunc = greater; 
      alpharef = 128;
        AlphaTestEnable = false;
        AlphaBlendEnable = false;
#ifdef DEBUGLEVEL
        FillMode = WIREFRAME;
#endif

    }
}
