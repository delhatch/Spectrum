#ifndef   __INC_VGA_H__
#define   __INC_VGA_H__



//  VGA Parameter
#define VGA_WIDTH     640
#define VGA_HEIGHT    480
#define OSD_MEM_ADDR  VGA_WIDTH*VGA_HEIGHT

//  VGA Set Function 
#define Vga_Write_Ctrl(base,value)          IOWR(base, OSD_MEM_ADDR   , value)
#define Vga_Cursor_X(base,value)            IOWR(base, OSD_MEM_ADDR+1 , value)        
#define Vga_Cursor_Y(base,value)            IOWR(base, OSD_MEM_ADDR+2 , value)        
#define Vga_Cursor_Color_R(base,value)      IOWR(base, OSD_MEM_ADDR+3 , value)        
#define Vga_Cursor_Color_G(base,value)      IOWR(base, OSD_MEM_ADDR+4 , value)        
#define Vga_Cursor_Color_B(base,value)      IOWR(base, OSD_MEM_ADDR+5 , value)        
#define Vga_Pixel_On_Color_R(base,value)    IOWR(base, OSD_MEM_ADDR+6 , value)        
#define Vga_Pixel_On_Color_G(base,value)    IOWR(base, OSD_MEM_ADDR+7 , value)        
#define Vga_Pixel_On_Color_B(base,value)    IOWR(base, OSD_MEM_ADDR+8 , value)        
#define Vga_Pixel_Off_Color_R(base,value)   IOWR(base, OSD_MEM_ADDR+9 , value)        
#define Vga_Pixel_Off_Color_G(base,value)   IOWR(base, OSD_MEM_ADDR+10 , value)        
#define Vga_Pixel_Off_Color_B(base,value)   IOWR(base, OSD_MEM_ADDR+11 , value)        
#define Vga_Set_Pixel(base,x,y)             IOWR(base, y*VGA_WIDTH+x, 1)        
#define Vga_Clr_Pixel(base,x,y)             IOWR(base, y*VGA_WIDTH+x, 0)   

//-------------------------------------------------------------------------
typedef union VGA_Ctrl_Reg
{
  struct _VGA_Ctrl_Flags
  {
    unsigned char RED_ON      : 1;
    unsigned char GREEN_ON    : 1;
    unsigned char BLUE_ON     : 1;
    unsigned char CURSOR_ON   : 1;
    unsigned char RESERVED    : 4;
  }VGA_Ctrl_Flags;
  unsigned char Value;
}VGA_Ctrl_Reg;
//-------------------------------------------------------------------------
void Set_Cursor_XY(unsigned int X,unsigned int Y);
void Set_Cursor_Color(unsigned int R,unsigned int G,unsigned int B);
void Set_Pixel_On_Color(unsigned int R,unsigned int G,unsigned int B);
void Set_Pixel_Off_Color(unsigned int R,unsigned int G,unsigned int B);
//-------------------------------------------------------------------------


#endif //

