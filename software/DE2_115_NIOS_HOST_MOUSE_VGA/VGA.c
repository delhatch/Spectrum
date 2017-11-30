#include <io.h>
#include "system.h"
#include "VGA.h"



//-------------------------------------------------------------------------
void Set_Cursor_XY(unsigned int X,unsigned int Y)
{
  Vga_Cursor_X(VPG_BASE,X);
  Vga_Cursor_Y(VPG_BASE,Y);

}
//-------------------------------------------------------------------------
void Set_Cursor_Color(unsigned int R,unsigned int G,unsigned int B)
{
  Vga_Cursor_Color_R(VPG_BASE,R);
  Vga_Cursor_Color_G(VPG_BASE,G);
  Vga_Cursor_Color_B(VPG_BASE,B);

}
//-------------------------------------------------------------------------
void Set_Pixel_On_Color(unsigned int R,unsigned int G,unsigned int B)
{
  Vga_Pixel_On_Color_R(VPG_BASE,R);
  Vga_Pixel_On_Color_G(VPG_BASE,G);
  Vga_Pixel_On_Color_B(VPG_BASE,B);

}
//-------------------------------------------------------------------------
void Set_Pixel_Off_Color(unsigned int R,unsigned int G,unsigned int B)
{
  Vga_Pixel_Off_Color_R(VPG_BASE,R);
  Vga_Pixel_Off_Color_G(VPG_BASE,G);
  Vga_Pixel_Off_Color_B(VPG_BASE,B);

}
//-------------------------------------------------------------------------

