//Fireball explosion FLAK shader by Mark Blosser  
//email: mjblosser@gmail.com website: www.mjblosser.com
//Description: 
//Also performs screen-aligned billboarding, depth buffer disabled for alpha-blending
//-Also can bend sprite left or right with SwayAmount variable
//-ScaleOverride variable controls size of sprite
//-AlphaOverride varibale controls opacity

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
float alphaoverride  : alphaoverride;

float4 clipPlane : ClipPlane;  //cliplane for water plane

float ScaleOverride 
<
   string SasUIControl = "slider";
   float SasUIMax = 3.0;
   float SasUIMin = 0.0;
   float SasUIStep = 0.1;
> = 1.0;

float SwayAmount
<
   string UIWidget = "slider";
   float UIMax = 0.5;
   float UIMin = -0.5;
   float UIStep = 0.01;
> = 0.00f;

float4 FogColor : Diffuse
<   string UIName =  "Fog Color";    
> = {0.0f, 0.0f, 0.0f, 0.0000001f};

float4 HudFogColor : Diffuse
<   string UIName =  "Hud Fog Color";    
> = {0.0f, 0.0f, 0.0f, 0.0000001f};

float4 HudFogDist : Diffuse
<   string UIName =  "Hud Fog Dist";    
> = {1.0f, 0.0f, 0.0f, 0.0000001f};

float4 UVScaling : uvscaling
<   string UIName =  "UV Scaling";    
> = {0, 0, 0, 0};

texture DiffuseMap : DiffuseMap
<
    string Name = "D.tga";
    string type = "2D";
>;

sampler2D DiffuseSampler = sampler_state
{
    Texture   = <DiffuseMap>;
    MipFilter = LINEAR;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    AddressU = wrap; AddressV = wrap;
};

struct appdata 
{
    float4 Position   : POSITION;
    float2 UV      : TEXCOORD0;    
};

struct vertexOutput
{
    float4 Position     : POSITION;
    float2 TexCoord     : TEXCOORD0;
    float2 atlasUV      : TEXCOORD1; 
    float2 UV           : TEXCOORD2;    
    float  WaterFog     : TEXCOORD3; 
    float4 WPos         : TEXCOORD4;
    float clip          : TEXCOORD5;   
};

vertexOutput mainVS(appdata IN)   
{
    vertexOutput OUT;
    
    float4 worldSpacePos = mul(IN.Position, World);
    OUT.WPos =   worldSpacePos;   
    OUT.TexCoord  = IN.UV;   
    
    // screen aligned billboard
   float4x4 worldViewMatrix = mul(World, View);
    float3 offsetW = worldSpacePos-IN.Position; 
    float amplitude = SwayAmount * pow(abs(IN.Position.y),1.0); //power function biases movement toward the top of the model   
    float4 vert = IN.Position + amplitude;
    float3 positionVS = (IN.Position* .25 *ScaleOverride) + float3(worldViewMatrix._41+vert.x, worldViewMatrix._42+IN.Position.y, worldViewMatrix._43);
    OUT.Position = mul(float4(positionVS , 1.0f), Projection);
    
    OUT.UV = IN.UV;   
    OUT.atlasUV = IN.UV + UVScaling.xy;
   
    // calculate Water FOG colour
    float4 cameraPos = mul( worldSpacePos, View );
    float fogstrength = cameraPos.z * FogColor.w;
    OUT.WaterFog = min(fogstrength,1.0);
        
    // all shaders should send the clip value to the pixel shader (for refr/refl)                                                                     
    OUT.clip = dot(worldSpacePos, clipPlane);                                                                      
  
    return OUT;
}

float4 mainPS(vertexOutput IN) : COLOR
{
    float4 finalcolor;
    clip(IN.clip);
    
    float4 diffusemap = tex2D(DiffuseSampler,IN.atlasUV);
    float alpha = diffusemap.a * alphaoverride;    
    float4 result =  diffusemap;
    
    // calculate hud (scene) pixel-fog
    float4 cameraPos = mul(IN.WPos, View);
    float hudfogfactor = saturate((cameraPos.z- HudFogDist.x)/(HudFogDist.y - HudFogDist.x));
    
    // mix in HUD (scene) Fog with final color;
    float4 hudfogresult = lerp(result,HudFogColor,hudfogfactor);
    
    // and Finally add in any Water Fog   
    float4 waterfogresult = lerp(hudfogresult,FogColor,IN.WaterFog);   
    finalcolor=float4(waterfogresult.xyz,alpha);    
        
    return finalcolor;
}

technique dx9textured
{
    pass P0
    {
        // shaders
        VertexShader = compile vs_3_0 mainVS();
        PixelShader  = compile ps_3_0 mainPS();
        CullMode = none;
        AlphaBlendEnable = true; 
        SrcBlend = srcalpha; 
      BlendOp = add;
      DestBlend = invsrcalpha;  
        Zenable=true;      
        ZWriteEnable = false;
        AlphaTestEnable = false;
    }
}
