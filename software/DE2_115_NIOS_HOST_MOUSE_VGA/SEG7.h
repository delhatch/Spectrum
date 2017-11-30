#ifndef SEG7_H_
#define SEG7_H_

#define SEG_DISPLAY_R(mask)  IOWR_ALTERA_AVALON_PIO_DATA(PIO_SEG_RIGHT_BASE, ~mask) 
#define SEG_DISPLAY_L(mask)  IOWR_ALTERA_AVALON_PIO_DATA(PIO_SEG_LEFT_BASE, ~mask) 

void SEG7_Clear(void);
void SEG7_Full(void);
void SEG7_Hex(alt_u32 Data, alt_u8 point_mask);
void SEG7_Decimal(alt_u32 Data, alt_u8 point_mask); 

#endif /*SEG7_H_*/
