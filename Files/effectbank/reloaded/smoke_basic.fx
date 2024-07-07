/*******************************************************************************************
Fireball explosion FLAK shader
by Mark Blosser  
email: mjblosser@gmail.com
website: www.mjblosser.com
-------------------------------------------------------------------
Description: 
Also performs screen-aligned billboarding, depth buffer disabled for alpha-blending
Optionally can do looping sprite animation (disabled since triggered in FPSC)
-Also can bend sprite left or right with SwayAmount variable
-ScaleOverride variable controls size of sprite
-AlphaOverride varibale controls opacity

********************************************************************************************/

/**************MATRICES & UNTWEAKABLES *****************************************************/

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

/**************VALUES PROVIDED FROM FPSC - NON TWEAKABLE**************************************/

float4 clipPlane : ClipPlane;  //cliplane for water plane

float alphaoverride  : alphaoverride;

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



/***************TEXTURES AND SAMPLERS***************************************************/
//For dynamic ojbects (D, I, N, S)


texture DiffuseMap : DiffuseMap
<
    string Name = "D.tga";
    string type = "2D";
>;


//Diffuse Texture _D
sampler2D DiffuseSampler = sampler_state
{
    Texture   = <DiffuseMap>;
    MipFilter = LINEAR;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    AddressU = wrap; AddressV = wrap;
};



/************* DATA STRUCTS **************/

struct appdata {
    float4 Position   : POSITION;
    float2 UV      : TEXCOORD0;    
};


/*data passed to pixel shader*/
struct vertexOutput
{
    float4 Position     : POSITION;
    float2 TexCoord     : TEXCOORD0;
    //float2 atlasUV      : TEXCOORD3; 
    float2 UV           : TEXCOORD3;    
    float  WaterFog     : TEXCOORD5; 
    float4 WPos         : TEXCOORD6;
    float clip          : TEXCOORD7;   
};


/*******Vertex Shader***************************/

vertexOutput mainVS(appdata IN)   
{
    
   vertexOutput OUT;
    
    //float4 tempPos = float4(IN.Position, 1);
    float4 worldSpacePos = mul(IN.Position, World);
    OUT.WPos =   worldSpacePos;   
    OUT.TexCoord  = IN.UV;   
    
    //==========screen aligned billboard================
    float4x4 worldViewMatrix = mul(World, View);
   
     
     float3 offsetW = worldSpacePos-IN.Position; 
     
     float amplitude = SwayAmount * pow(abs(IN.Position.y),1.0); //power function biases movement toward the top of the model   
     float4 vert = IN.Position + amplitude;
     float3 positionVS = (IN.Position* .25 *ScaleOverride) + float3(worldViewMatrix._41+vert.x, worldViewMatrix._42+IN.Position.y, worldViewMatrix._43);
     
     
     
     OUT.Position = mul(float4(positionVS , 1.0f), Projection);
     //===============================================
    
    //===Calculate a set of texture coordinates to perform atlas walking=======/
    //rem texture addressing must be set to "wrap"
   float2 DimensionsXY = float2(8,8); 
   
   float framespersec = 30;  //speed of animation in frames per second
   float looptime = 2.133; //looptime in seconds
         
   float loopcounter  = floor(time/looptime); //increments by one every 50 seconds (or whatever "looptime" is)
   float offset ;  //initialize offset value used below
   
   offset = looptime*loopcounter; //offset time value -increments every looptime   
       
   float speed =(time*framespersec) - (offset*framespersec) ;   
   
   float2 atlasUVtemp = IN.UV;   
   
   float index = floor( speed);      //floor of speed
   float rowCount = floor( (index / DimensionsXY.x) );      //floor of (speed / Ydimension.g)
   float2 offsetVector = float2(index, rowCount);
   float2 atlas = (1.0 / DimensionsXY) ;
   float2 move = (offsetVector + atlasUVtemp);
   
   //OUT.atlasUV = (atlas.xy *move);
   //OUT.atlasUV = (atlas.xy *move) +float2(-0.0,0.00125)*-speed;  //scroll texture
   //================================================================================/    
    OUT.UV = IN.UV;   
    // calculate Water FOG colour
    float4 cameraPos = mul( worldSpacePos, View );
    float fogstrength = cameraPos.z * FogColor.w;
    OUT.WaterFog = min(fogstrength,1.0);
        
    // all shaders should send the clip value to the pixel shader (for refr/refl)                                                                     
    OUT.clip = dot(worldSpacePos, clipPlane);                                                                      
  
    return OUT;
}


/****************Fragment Shader*****************/


float4 mainPS(vertexOutput IN) : COLOR
{
    
    float4 finalcolor;
    
    clip(IN.clip); // all shaders should receive the clip value  
    
    //float4 diffusemap = tex2D(DiffuseSampler,IN.atlasUV);    //sample diffuse texture
    float4 diffusemap = tex2D(DiffuseSampler,IN.UV);    //sample diffuse texture
    float alpha = diffusemap.a * alphaoverride;    

    float4 result =  diffusemap ;
    
    //calculate hud (scene) pixel-fog
    float4 cameraPos = mul(IN.WPos, View);
    float hudfogfactor = saturate((cameraPos.z- HudFogDist.x)/(HudFogDist.y - HudFogDist.x));
    
    //Mix in HUD (scene) Fog with final color;
    float4 hudfogresult = lerp(result,HudFogColor,hudfogfactor);
    
    //And Finally add in any Water Fog   
    float4 waterfogresult = lerp(hudfogresult,FogColor,IN.WaterFog);   
    
    finalcolor=float4(waterfogresult.xyz,alpha);      
          
    return finalcolor;
}


/****** technique *****************************************************************************/

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
      blendop=add;
      DestBlend = invsrcalpha;  
        Zenable=true;      
        ZWriteEnable = false;
        AlphaTestEnable = false;
        
    }
}
