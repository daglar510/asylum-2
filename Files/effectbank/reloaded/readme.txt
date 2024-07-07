//#######################################################################################
//#### These shaders , has been greatly impoved and many new features added.         ####
//#### This has now been made available for free to ALL GameGuru users.              ####
//#### If you like to support the work involved in these shader updates ( a lot ),   ####
//#### You can order a copy of GG Loader from daily3d.com , but its not needed.      ####
//#### http://www.daily3d.com , or give me a e-mail plemsoft@plemsoft.com            ####
//#### This is mainly made to make GG look like GG Loader. But is part of a larger   ####
//#### 3D developer kit for AGK called "GG Loader". Best Regards: Preben Eriksen.    ####
//#######################################################################################

New shader pack for GameGuru 1.141 beta 2

Remember to make a backup of the original shaders before you copy the new files.

Copy all files from the zip folder "reloaded - ggloader" to your Game Guru: /effectbank/reloaded/ folder.
Overwrite all files when you copy.

You can enable/disable functins by editing "settings.fx".

#define FASTROCKTEXTURE // PE: disable tri-planar rock for faster terrain. 
#define IMPROVEDISTANCE // PE: Imrpove distance terrain.
#define LENSFLARE // PE: enable / disable lens flare.
#define DISABLELENSFLAREHALO // PE: diable the lens flare halo.
#define FXAA // PE: enable / disable FXAA
//#define CARTOON // PE: enable / disable cartoon (cel) shader.
#define DOF // PE: enable / disable depth of field.
#define MOTIONBLUR // PE: enable / disable motion blur.

If you use lens flare you should adjust BLOOM so everything dont give a flare.
If you use CARTOON you should play around with  "Surface level", "Brightness" , "Contrast".



