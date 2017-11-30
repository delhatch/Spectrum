#include <stdio.h>
#include <stdlib.h> // malloc, free
#include <string.h>
#include <stddef.h>
#include <unistd.h>  // usleep (unix standard?)
#include "sys/alt_flash.h"
#include "sys/alt_flash_types.h"
#include "io.h"
#include "alt_types.h"  // alt_u32
#include "altera_avalon_pio_regs.h" //IOWR_ALTERA_AVALON_PIO_DATA
#include "sys/alt_irq.h"  // interrupt
#include "sys/alt_alarm.h" // time tick function (alt_nticks(), alt_ticks_per_second())
#include "sys/alt_timestamp.h" 
#include "sys/alt_stdio.h"
#include "system.h"
#include <fcntl.h>
#include "SEG7.h"

#define SEG7_SET(index, seg_mask)   IOWR(SEG7_BASE,index,seg_mask)
#define SEG7_NUM    8

static    unsigned char szMap[] = {
        63, 6, 91, 79, 102, 109, 125, 7, 
        127, 111, 119, 124, 57, 94, 121, 113
    };  // 0,1,2,....9, a, b, c, d, e, f
    
void SEG7_Clear(void){
    int i;
    for(i=0;i<SEG7_NUM;i++){
        SEG7_SET(i, 0x00);
    }        
}
void SEG7_Full(void){
    int i;
    for(i=0;i<SEG7_NUM;i++){
        SEG7_SET(i, 0xFF);
    }        
}

void SEG7_Number(void){
    int i;
    for(i=0;i<SEG7_NUM;i++){
        SEG7_SET(i, szMap[i]);
    }        
}

void SEG7_Hex(alt_u32 Data, alt_u8 point_mask){
    alt_u8 mask = 0x01;
    alt_u8 seg_mask;
    int i;
    
    //
    seg_mask = 0;
    for(i=0;i<SEG7_NUM;i++){
        seg_mask = szMap[Data & 0x0F];
        Data >>= 4;
        if (point_mask & mask)
            seg_mask |= 0x80;
        mask <<= 1;     
        SEG7_SET(i, seg_mask);
    }        
}

void SEG7_Decimal(alt_u32 Data, alt_u8 point_mask){
    alt_u8 mask = 0x01;
    alt_u8 seg_mask;
    int i;
    
    //
    seg_mask = 0;
    for(i=0;i<SEG7_NUM;i++){
        seg_mask = szMap[Data%10];
        Data /= 10;
        if (point_mask & mask)
            seg_mask |= 0x80;
        mask <<= 1;   
        SEG7_SET(i, seg_mask);
    }        
  
} 

