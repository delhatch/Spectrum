//	Copyright (C) 1988-2007 Altera Corporation
//	Any megafunction design, and related net list (encrypted or decrypted),
//	support information, device programming or simulation file, and any other
//	associated documentation or information provided by Altera or a partner
//	under Altera's Megafunction Partnership Program may be used only to
//	program PLD devices (but not masked PLD devices) from Altera.  Any other
//	use of such megafunction design, net list, support information, device
//	programming or simulation file, or any other related documentation or
//	information is prohibited for any other purpose, including, but not
//	limited to modification, reverse engineering, de-compiling, or use with
//	any other silicon devices, unless such use is explicitly licensed under
//	a separate agreement with Altera or a megafunction partner.  Title to
//	the intellectual property, including patents, copyrights, trademarks,
//	trade secrets, or maskworks, embodied in any such megafunction design,
//	net list, support information, device programming or simulation file, or
//	any other related documentation or information provided by Altera or a
//	megafunction partner, remains with Altera, the megafunction partner, or
//	their respective licensors.  No other licenses, including any licenses
//	needed under any third party's intellectual property, are provided herein.
//
//  Altera FFT MegaCore ver 7.1 
//
//  04/06/2007 model.c : Example FFT testbench for Hauwei
//

#include "stdio.h"
#include "fft.h"
#include "util.h"
#include "math.h"
#include "stdlib.h"
#define FFT_NAME fft
#define RND_CONV 1
#include <iostream>
#include <fstream>
using namespace std;

//--------------------ftp----------------

unsigned long int HexToInt (char hex_number[8]);
void my_Float2Bin(long int value); 
void seprate_sem(char bin_buff[32]);

static string t;
static char bin_value[32];
static char buff[32];

static signed int sign;
static int	exponent;
static long int mantisa;
//------------------------------------------
union u_intfloat_converter {
	long unsigned int as_uint;
	float as_float;
};

static void f_convert_double_to_binary (double f, int binary_width, char *buffer, int buff_size);

int main(int argc, char** argv){


  /***************************************************************************
   * Set FFT Core Parameters 
   **************************************************************************/
  int maxN=256;   // maxN :Largest Transform Length
  int N=0;            // N : Block Transform Length
  int dw =0;          // Input Data Precision
  int twidw=0;         // Twiddle Factor Precision
  int direction=0;      // FFT Transform direction 0 : FFT, 1 : Inverse FFT
  int input_order=0;    // FFT input order 0 : Bit Reversed, 1 : Natural Order
  int output_order=0;   // FFT output order 0 : Bit Reversed, 1 : Natural Order
  int rep=0; // FFT data representation : 0 for fixed point, 1 for floating pt
  int arch=0;
  double num_stages=0;
  int out_dw=0;
  int fftpts_size=0;
  int rounding_type=0;
    
  
	int i;
  // These variables store the directory and filenames of the i/o

	char* directory;
	char* real_input_file;
	char* imag_input_file;
	char* blksize_input_file;
	char* inverse_input_file;
	char* real_output_file;
	char* imag_output_file;
	
 maxN = atoi((char*)argv[1]);		//read from the 	fff_test_suite xml = $per->{nps}
	
  /***************************************************************************
   * Create input data arrays to model
   **************************************************************************/
  double* real_in = new double[maxN];
  double* imag_in = new double[maxN];
  double* real_out = new double[maxN];
  double* imag_out = new double[maxN];
  int* dr_in = new int[maxN];
  int* di_in = new int[maxN];
  
  
  
  FILE *fidro;	// File handle for 	Real Output
	FILE *fidio;	//					Imag Output
	FILE *fidr;		//					Real Input
	FILE *fidi;		//					Imag Input
	FILE *fidblk;
	FILE *fidinv;
	
  //----------------ftp---------------------------
  
  double floatpt_in_dec=0;
  

  char reali_hex[10];	//to store the input value in hex
  char imagi_hex[10];
  long int bin_value=0x00000000;
  //--------------------------------------------------
  
  //*****************************
  //parse the variable from input argv
  //***************************** 
  output_order = atoi((char*)argv[2]);//			$O_O
  dw = atoi((char*)argv[3]);		//take from	$mpr
  twidw = atoi((char*)argv[4]);		//			$twr
  rep = atoi((char*)argv[5]);		//			$rep
  input_order = atoi((char*)argv[6]);//			$I_O	 
	//N = atoi((char*)argv[7]);			//read from 	blocksize.txt
	//direction = atoi((char*)argv[8]);//read from the	inverse.txt  
	// the input directory
	
	arch = atoi((char*)argv[7]);
	
	directory = (char*)malloc(sizeof(char)*strlen(argv[8]));
	directory = argv[8];
	//*********************************
	
	//Create strings (char arrays) with exactly the right number of elements
	//Number of elements = length of file name + length of directory + Forward slash (1)
	real_input_file = (char*)malloc(sizeof(char)*(strlen("real_input.txt")+strlen(directory)+2));
	imag_input_file = (char*)malloc(sizeof(char)*(strlen("imag_input.txt")+strlen(directory)+2));
	blksize_input_file = (char*)malloc(sizeof(char)*(strlen("blksize_report.txt")+strlen(directory)+2));
	inverse_input_file = (char*)malloc(sizeof(char)*(strlen("inverse_report.txt")+strlen(directory)+2));
	
	real_output_file = (char*)malloc(sizeof(char)*(strlen("real_output_c_model.txt")+strlen(directory)+2));
	imag_output_file = (char*)malloc(sizeof(char)*(strlen("imag_output_c_model.txt")+strlen(directory)+2));

	strcpy(real_input_file,directory);
	strcat(real_input_file,"/real_input.txt");
	strcpy(imag_input_file,directory);
	strcat(imag_input_file,"/imag_input.txt");
	
	strcpy(real_output_file,directory);
	strcat(real_output_file,"/real_output_c_model.txt");
	strcpy(imag_output_file,directory);
	strcat(imag_output_file,"/imag_output_c_model.txt");
	
	strcpy(blksize_input_file,directory);
	strcat(blksize_input_file,"/blksize_report.txt");
	
	strcpy(inverse_input_file,directory);
	strcat(inverse_input_file,"/inverse_report.txt");
	//debug 
	printf ("\n directory = %s", directory);
	printf ("\n real_input_file = %s", real_input_file);
	printf ("\n imag_input_file = %s", imag_input_file);
	printf ("\n real_output_file = %s", real_output_file);
	printf ("\n imag_output_file = %s", imag_output_file);	
	printf ("\n blksize_input_file = %s", blksize_input_file);	
	printf ("\n inverse_input_file= %s", inverse_input_file);	
  
    
 int size_of_file =0;
 
 int ch1,j;
    fidblk = fopen(blksize_input_file,"r");
    if(fidblk==NULL)
            printf("\n error when open file");
        else
        {
            size_of_file=0;
            do {
				if (fscanf(fidblk,"%d",&ch1) == 1) {
					size_of_file++;
				}
            }
            while(!feof(fidblk));
        }
  fclose(fidblk); 
  
	
  fidr = fopen(real_input_file,"r");
  fidi = fopen(imag_input_file,"r");
  fidblk = fopen(blksize_input_file,"r");
  fidinv = fopen(inverse_input_file,"r");
  
  fidro = fopen(real_output_file,"wt");
  fidio = fopen(imag_output_file,"wt");
  
  if(fidr==NULL || fidi==NULL || fidblk==NULL || fidinv==NULL)
  {
	printf("\n ERROR OPEN FILE INPUT");
	exit (1);
  }
  else 
  {
	printf("\n OPEN FILE SUCESSFULLY");
  }
  
  //START for whole data
  
  num_stages=(double)(double(log2_int(maxN))/double(log2_int(4)));
	out_dw = dw + (int)ceil(2.5*num_stages);
	fftpts_size=(int)ceil(double(log2_int(maxN)))+1;  
	rounding_type = RND_CONV;
  
	//-----------------------------------------------------
	//debug the input before parse to model.exe
	//-----------------------------------------------------
	
	printf("\n maxN = %d",maxN);
	printf("\n output_order = %d",output_order);
	printf("\n dw = %d",dw);
	printf("\n twidw = %d",twidw);
	printf("\n rep = %d",rep);
	printf("\n input_order = %d",input_order);
	printf("\n num_stages = %d",num_stages);
	printf("\n out_dw = %d",out_dw);
	printf("\n fftpts_size = %d",fftpts_size);
	printf("\n rounding_type = %d",rounding_type);
	
	int block_size=0;
    int inverse=0;	
	//-----------------------------------------------------
		for (j=0;j<size_of_file;j++)
		{
			//printf("\n Read the blocksize and inverse file for each block");
			fscanf(fidblk,"%d",&block_size);
			fscanf(fidinv,"%d",&inverse);
			//printf("\n block_size = %d , inverse %d",block_size,inverse);

			
			N = block_size;
			direction = inverse;
				
			
			//printf("\n stage = %d, round = %d,out_dw=%d,fftpts_size=%d",num_stages,rounding_type,out_dw,fftpts_size);
			for(i=0;i<N;i++){
			  //for floating point	
			  if(rep==1)
			  {
				  //*************************
				  //real iput processing
				  //*************************

				  u_intfloat_converter real_number;
				 
				  //1. read data from input file in hex format
					fscanf(fidr,"%s",&reali_hex);
					
				  //2. convert from hex to dec
					real_number.as_uint = HexToInt(reali_hex);

				  	real_in[i]=(double)real_number.as_float;
					

				
				  
				  //*************************
				  // imag input processing
				  //************************
				  
				  
				  //1. read data from input file in hex format
					u_intfloat_converter imag_number;
					fscanf(fidi,"%s",&imagi_hex);
					
				  //2. convert from hex to dec
					imag_number.as_uint = HexToInt(imagi_hex);
			        
				  //	imag_in[i] = floatpt_in_dec;
					imag_in[i]=(double)imag_number.as_float;
					
					
						  
			    }
			  else //for fixed point
			  {	
			      fscanf(fidr,"%d",&dr_in[i]);
			      real_in[i] = (double)dr_in[i];
			      fscanf(fidi,"%d",&di_in[i]);
			      imag_in[i] = (double)di_in[i];
			  }
			  
		    }
			
		  
		 
		 
		  /****************************************************************************
		   * declare an instance of the fft
		   ***************************************************************************/

		 FFT_NAME this_fft("fft",dw, out_dw, fftpts_size, twidw,rounding_type,output_order, input_order,rep);
		  
		  this_fft.setThisFftpts(N);
		  this_fft.setThisInverse(direction);

		  /****************************************************************************
		   * Call to FFT
		   * Input : real_data : Real Component Input : Double Array of Length N
		   *         imag_data : Imaginary Component Input : Double Array of Length N 
		   * Outputs are stored in real_data, imag_data.
		   ***************************************************************************/

		 double* real_tmp = new double[maxN];
		  double* imag_tmp = new double[maxN];
		  memcpy( real_tmp, real_in, N*sizeof(double) );
		  memcpy( imag_tmp, imag_in, N*sizeof(double) );
		  
		  this_fft.SVSfftmodel(real_tmp, imag_tmp);
		 
		  memcpy( real_out, real_tmp, N*sizeof(double) );
		  memcpy( imag_out, imag_tmp, N*sizeof(double) );

		 
		  /*******************************************************************************
		   * Write Results to Disk
		   *******************************************************************************/
		
		float float_real;
		float float_imag;
			 for(i=0;i<N;i++){
							if(rep==1)
							{ 	//write to file in hex format for floating point
								float_real=(float)real_out[i];
								fprintf(fidro,"%X\n",*(int *)&float_real);

								//imag outut
								float_imag=(float)imag_out[i];
								fprintf(fidio,"%X\n",*(int *)&float_imag);
							}
							else
							{	//write to file in dec for fixed point
								if (out_dw >= 32){
									char buffer[128];
									f_convert_double_to_binary(real_out[i], out_dw, buffer, 128);
									fprintf (fidro, "%s\n", buffer);
									f_convert_double_to_binary(imag_out[i], out_dw, buffer, 128);
									fprintf (fidio, "%s\n", buffer);
								}
								else
								{	//write to file in dec for fixed point
									fprintf(fidro,"%d\n",(int)real_out[i]);
									fprintf(fidio,"%d\n",(int)imag_out[i]);
								}
							}
						}
		//$$$ END processing 1 block	
			
		} //END of while
	
  fclose(fidr);
  fclose(fidi);
  fclose(fidro);
  fclose(fidio);
  fclose(fidblk);
  fclose(fidinv);
  
  
  return 0;

}



//***********************************************
//subpro
//***********************************************

unsigned long int HexToInt (char hex_number[10])
{
	char buffer[10];
	//long float value;	//64B
	double value;


	char *pointer;
    
	//buffer[0]=hex_number[0];
	strcpy(buffer,hex_number);
	value = 0;
	for (pointer = buffer; *pointer; ++pointer) {
	value *= 16;
		switch (*pointer) {
		case 'a':
		case 'A':
		value += 0xa;
		break;
		case 'b':
		case 'B':
		value += 0xb;
		break;
		case 'c':
		case 'C':
		value += 0xc;
		break;
		case 'd':
		case 'D':
		value += 0xd;
		break;
		case 'e':
		case 'E':
		value += 0xe;
		break;
		case 'f':
		case 'F':
		value += 0xf;
		break;
		default:
		
		value += *pointer - '0';
		break;
		}
	}

	return (unsigned long int) value;
}


void my_Float2Bin(long int value)
{
	
	long int mask2=1;
    string t ="";
	long int remain,decimal,bin_value=0;
	int i=0;

	decimal = value;
	for (i=0;i<32;i++)
	{
		remain=decimal%2;	//so du
		decimal=decimal/2;	//so nguyen
		if(remain==1)
		{
		//mask with at that position
		//bin_value=bin_value | (mask2<<i);
		t = t + '1';
		//	t='1' + t;
		
		}
		else if (remain==0)
		{
		t = t + '0'  ;
		//	t='0' + t;
		}
	}

  
   t.copy(buff,32); 
	//return bin_value;
   char tam ;
   tam = buff[32];
    buff[32] = NULL;
}


void seprate_sem(char bin_buff[32])
{
	//char buffer[64];
	char ptr;
	
	//signed int sign;
	//int	exponent;
	int mask_exp=0x80;
	
	//long int mantisa;
	long int mask_man=0x00400000;
	
	exponent=0;
	mantisa=0;
	for(ptr=31;ptr>=0;ptr--)
	{
		//take bit[0] for sign
		if(ptr==31) 
		{
			//0:positive.
			//1:negative
			sign=0;
			if(bin_buff[ptr]=='1')
			{
				sign=1;
			}
		}
		//take from bit 1-8 for exponent
		if((ptr<31)&&(ptr>22))
		{
			if(bin_buff[ptr]=='1')
			{
				exponent=exponent | (mask_exp>>(30-ptr));
			}
			//mantisa=mantisa;
		}
		
		//take from 9 - 31 for mantisa
		if(ptr<23)
		{
			if(bin_buff[ptr]=='1')	
			{
				mantisa=mantisa | (mask_man>>(22-ptr));
			}
		}
	}



}
// Binary 5 -->  0101
// Binary -5 --> 1011

static void f_convert_double_to_binary (double f, int binary_width, char *buffer, int buff_size)
{
	char *p = buffer;
	int remainder;
	int i;
	int len;
	char c;
	int is_negative;

	/* Ensure that the expected output size is within range of a precise double. */
	if (binary_width > 53) {
		printf ("Error: Cannot represent binary data > 53 bits in a double.\n");
		exit (1);
	}
	if (f < 0.0) {
		is_negative = 1;
		f *= -1.0;
	} else {
		is_negative = 0;
	}

	/* Convert the double to a string (backwards) by successive division. */
	while (f != 0.0) {
		remainder = (int)fmod (f, 2);
		*p = (remainder + '0');
		p++;
		f = (f - remainder) / 2.0;
		if (p - buffer >= buff_size - 1) {
			printf ("Error: Buffer not large enough to convert floating point number.\n");
			exit (1);
		}
	}

	/* Make sure the number was within the range expected by the user. */
	if (p - buffer > binary_width) {
		printf ("Error: Double conversion yields binary number larger than binary_width.\n");
		exit (1);
	} else if (p - buffer == binary_width) {
		printf ("Error: Double conversion equals binary width -- no room for the sign bit.\n");
		exit (1);
	}
	
	/* Pad the binary representation with zeros */
	while (p - buffer < binary_width) {
		*p = '0';
		p++;
	}
	*p = 0;

	/* Reverse the string so it is in correct order */
	len = strlen (buffer);
	for (i = 0; i < len/2; i++) {
		c = buffer[i];
		buffer[i] = buffer[len - i - 1];
		buffer[len - i - 1] = c;
	}

	/* If number was negative, convert to two's compliment form */
	if (is_negative) {
		for (i = 0; i < len; i++) {
			if (buffer[i] == '0') 
				buffer[i] = '1';
			else
				buffer[i] = '0';
		}
		for (i = len - 1; i >= 0; i--) {
			if (buffer[i] == '1') {
				buffer[i] = '0';
			} else {
				buffer[i] = '1';
				break;
			}
		}
	}
}

