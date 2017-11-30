#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <io.h>
#include <fcntl.h>

#include "system.h"
#include "alt_types.h"
#include <unistd.h>  // usleep 
#include "sys/alt_irq.h"
//#include "alt_irq.h"

#include "VGA.h"
#define half_fft_size 256
#define full_fft_size 512
// For 512 point fft, plot 19 bars. For 32 point fft, plot 8 bars.
#define number_of_bars 19

//--------------------------------------
//----------clear screen----------------
void Vga_clear_screen(unsigned int base)
{
    alt_u16 x_col,y_col;
    for(y_col=0;y_col<VGA_HEIGHT;y_col++)
      {
        for(x_col=0;x_col<VGA_WIDTH;x_col++)
        {
            Vga_Clr_Pixel(base,x_col,y_col);
        }
      }
}

//----------------------------------------------------------------------------------------//
//
//                                Main function
//
//----------------------------------------------------------------------------------------//
int main(void)
{
   int myint, xval, yval, myindex, width;
   int mydata[half_fft_size];   // holds fft data. Upper half = lower half, so only read half.
   int myfreq[20];

    //Initialize the VGA display
    
    VGA_Ctrl_Reg vga_ctrl_set;

    vga_ctrl_set.VGA_Ctrl_Flags.RED_ON    = 1;
    vga_ctrl_set.VGA_Ctrl_Flags.GREEN_ON  = 1;
    vga_ctrl_set.VGA_Ctrl_Flags.BLUE_ON   = 1;
    vga_ctrl_set.VGA_Ctrl_Flags.CURSOR_ON = 0;

    Vga_Write_Ctrl(VPG_BASE, vga_ctrl_set.Value);
    Vga_clear_screen(VPG_BASE); //clear the screen
    Set_Pixel_On_Color(512,512,512);
    Set_Pixel_Off_Color(0,0,0);
    Set_Cursor_Color(0,1023,0);

    while(1)
    {
    // Read the FFT values
    for( myint=0; myint < (half_fft_size-1); myint++)
    {
    	mydata[myint] = IORD(COPROC_TOP_0_BASE, myint);
    }
    //printf("mydata[0] = %x\n",mydata[2]);
    //printf("mydata[0] = %x\n",mydata[3]);
    //-----------------------------------------------------------------
    // Now do a fake log(freq) binning of the linear frequency values.
    // Looks similar to a log/log Real-time Analyzer (RTA) plot.
    //-----------------------------------------------------------------
    myfreq[0] = mydata[0] / 1.5;
    myfreq[1] = mydata[1];
    myfreq[2] = mydata[2];
    myfreq[3] = mydata[3];
    myfreq[4] = mydata[4];
    myfreq[5] = mydata[5];
    myfreq[6] = mydata[6] + mydata[7];
    myfreq[6] /= 1.25;
    myfreq[7] = mydata[8] + mydata[9];
    myfreq[7] /= 1.25;
    myfreq[8] = mydata[10] + mydata[11] + mydata[12];
    myfreq[8] /= 1.3;
    myfreq[9] = mydata[13] + mydata[14] + mydata[15];
    myfreq[9] /= 1.3;
    myfreq[10] = mydata[16] + mydata[17] + mydata[18] + mydata[19];
    myfreq[10] /= 1.4;
    myfreq[11] = mydata[20] + mydata[21] + mydata[22] + mydata[23] + mydata[24];
    myfreq[11] /= 1.6;
    myfreq[12] = 0;
    for( xval=25; xval<=29; xval++)
    {
    	myfreq[12] += mydata[xval];
    }
    myfreq[12] /= 1.7;
    myfreq[13] = 0;
    for( xval=30; xval<=38; xval++)
    {
       myfreq[13] += mydata[xval];
    }
    myfreq[13] /= 1.9;
    myfreq[14] = 0;
    for( xval=39; xval<=48; xval++)
    {
        myfreq[14] += mydata[xval];
    }
    myfreq[14] /= 2;
    myfreq[15] = 0;
    for( xval=49; xval<=61; xval++)
    {
         myfreq[15] += mydata[xval];
    }
    myfreq[15] /= 2.1;
    myfreq[16] = 0;
    for( xval=62; xval<=75; xval++)
    {
        myfreq[16] += mydata[xval];
    }
    myfreq[16] /= 2.1;
    myfreq[17] = 0;
    for( xval=76; xval<=96; xval++)
    {
        myfreq[17] += mydata[xval];
    }
    myfreq[17] /= 2.4;
    myfreq[18] = 0;
    for( xval=97; xval<=120; xval++)
    {
        myfreq[18] += mydata[xval];
    }
    myfreq[18] /= 2.6;
    myfreq[19] = 0;
    for( xval=121; xval<=151; xval++)
    {
        myfreq[19] += mydata[xval];
    }
    myfreq[19] /= 2.1;

    for( xval=0; xval<=19; xval++)
    {
       mydata[xval] = myfreq[xval];
    }

    myindex = 0;
    // Now plot the bars
    for( xval=10; xval<=(number_of_bars*10); xval=xval+10)
    {
    	//clear the bar
    	for( width=0; width <= 6; width++)
    	{
    	  for(yval=479; yval>=1; yval--)
    	  {
    		 Set_Pixel(VPG_BASE,xval+width,yval,0);
    	  }
    	//}
    	//draw the bar
    	//for( width=0; width <= 6; width++)
    	//{
    	  for(yval=479; yval>=(479-mydata[myindex]); yval--)
    	  {
    		 Set_Pixel(VPG_BASE,xval+width,yval,xval+4); //'4' is just an arbitrary offset into the color look-up table LUT.
    	  }
    	}
    	myindex++;
    }

    usleep(200);  // Can adjust this for faster action or slower bar movement.
    }

/*
    // Speed test for drawing rectangles.
    int iSecretx, iSecrety, iGuess;
    int wherex, wherey, odd;

    // initialize random seed:
    srand (time(NULL));
    odd = 1;

    for( iGuess=0; iGuess<1000; iGuess++)
    {
       // generate secret number between 1 and 10:
       iSecretx = rand() % 400 + 1;
       iSecrety = rand() % 200 + 1;
       //printf("Random number is %d and %d\n", iSecretx, iSecrety);

    // fill in a box 10 x 10. every other time erase a box.
    	for( wherex = iSecretx; wherex <= (iSecretx+10); wherex++)
    	{
    		for( wherey = iSecrety; wherey <= (iSecrety+100); wherey++)
    		{
    		    //Vga_Set_Pixel(VPG_BASE,wherex,wherey);
    		    Set_Pixel(VPG_BASE,wherex+iSecrety,wherey,wherex);
    		    //usleep(10);
    		}
    	}
    }
*/
    return 0;
}

