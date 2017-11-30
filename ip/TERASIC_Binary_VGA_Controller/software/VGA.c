#include <io.h>
#include "system.h"
#include "VGA.h"



//-------------------------------------------------------------------------
void Set_Cursor_XY(unsigned int X,unsigned int Y)
{
  Vga_Cursor_X(VGA_BASE,X);
  Vga_Cursor_Y(VGA_BASE,Y);
}
//-------------------------------------------------------------------------
void Set_Cursor_Color(unsigned int R,unsigned int G,unsigned int B)
{
  Vga_Cursor_Color_R(VGA_BASE,R);
  Vga_Cursor_Color_G(VGA_BASE,G);
  Vga_Cursor_Color_B(VGA_BASE,B);
}
//-------------------------------------------------------------------------
void Set_Pixel_On_Color(unsigned int R,unsigned int G,unsigned int B)
{
  Vga_Pixel_On_Color_R(VGA_BASE,R);
  Vga_Pixel_On_Color_G(VGA_BASE,G);
  Vga_Pixel_On_Color_B(VGA_BASE,B);
}
//-------------------------------------------------------------------------
void Set_Pixel_Off_Color(unsigned int R,unsigned int G,unsigned int B)
{
  Vga_Pixel_Off_Color_R(VGA_BASE,R);
  Vga_Pixel_Off_Color_G(VGA_BASE,G);
  Vga_Pixel_Off_Color_B(VGA_BASE,B);
}
//-------------------------------------------------------------------------

