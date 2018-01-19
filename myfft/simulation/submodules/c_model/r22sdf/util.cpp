// ================================================================================
// Legal Notice: Copyright (C) 1991-2007 Altera Corporation
// Any megafunction design, and related net list (encrypted or decrypted),
// support information, device programming or simulation file, and any other
// associated documentation or information provided by Altera or a partner
// under Altera's Megafunction Partnership Program may be used only to
// program PLD devices (but not masked PLD devices) from Altera.  Any other
// use of such megafunction design, net list, support information, device
// programming or simulation file, or any other related documentation or
// information is prohibited for any other purpose, including, but not
// limited to modification, reverse engineering, de-compiling, or use with
// any other silicon devices, unless such use is explicitly licensed under
// a separate agreement with Altera or a megafunction partner.  Title to
// the intellectual property, including patents, copyrights, trademarks,
// trade secrets, or maskworks, embodied in any such megafunction design,
// net list, support information, device programming or simulation file, or
// any other related documentation or information provided by Altera or a
// megafunction partner, remains with Altera, the megafunction partner, or
// their respective licensors.  No other licenses, including any licenses
// needed under any third party's intellectual property, are provided herein.
// ================================================================================
//
#include "util.h"
#include "math.h"
#include <iostream>
#include "systemc.h"
#define SC_INCLUDE_FX
using namespace std;

/*----------------------------------------------
 | log2_int 
 +----------------------------------------------*/
int log2_int(int arg) {
  int res = 0;
  for (int i = 0; i < 30 ; i++) {
    if (arg > (pow(2.0,i))) {
      res = i+1;
    }
  }
  return res;
  
}

/*----------------------------------------------
 | func_bit_reverse
 +----------------------------------------------*/
void func_bit_reverse(double* real, double* imag, int fftpts) {
  int this_fftpts_size=log2_int(fftpts);
  int this_shift = this_fftpts_size;
  
 for (int i =0; i < fftpts; i++) {
 
    int address=0;
   //swap bits in the address
    for (int j=0; j <= this_fftpts_size/2 ; j++) {
      int lower_bit = ((i>>j)&0x1);
      int higher_bit = (i>>(this_fftpts_size - 1 - j)&0x1);
      int higher_bit_tmp = lower_bit<<(this_fftpts_size -1 -j); //lower bit, shifted up
      lower_bit = higher_bit<<j; //higher bit, shifted down
      higher_bit = higher_bit_tmp;
      address |= lower_bit | higher_bit;
    }
#if DEBUG
    cout << "fft:func_bit_reverse: "<< i << " " << address << endl;
#endif
    //swap values at the addresses i & address
    if (address > i) {
      double real_tmp = real[i];
      double imag_tmp = imag[i];
      real[i] = real[address];
      imag[i] = imag[address];
      real[address] = real_tmp;
      imag[address] = imag_tmp;
    }
      this_shift--;
  }
}

/*----------------------------------------------
 | convertCharToHexNibble
 +----------------------------------------------*/
 char convertCharToHexNibble(const char c) {
  if (c >= '0' && c <= '9') {
    return c - '0';
  } else if (c>='A' && c <='Z') {
    return c - 'A' + 10;
  } else {
    return c - 'a' + 10;
  }
}

/*----------------------------------------------
 | convertHexStringToFloat
 +----------------------------------------------*/
float convertHexStringToFloat(char* hexString) {
  float f;
  char * floatAsChar = (char*)&f;

  int length = sizeof(f);

  int hexLength = strlen(hexString);

  int endian = checkEndian();
  int floatPos = (endian == LITTLEENDIAN) ? 0 :  length-1; // endian may be wrong...
  int floatPosInc = (endian == LITTLEENDIAN) ? 1 : -1;    // endian may be wrong...

  for (int i=0; i<length; ++i) {
    floatAsChar[i] = 0;
  }

  for (int i=0; i<length; ++i) {
    --hexLength;
    if (hexLength >= 0) {
      floatAsChar[floatPos] = convertCharToHexNibble(hexString[hexLength]);
      --hexLength;
      if (hexLength >= 0) {
	floatAsChar[floatPos] |= convertCharToHexNibble(hexString[hexLength]) << 4;
      } else {
	break;
      }
    } else {
      break;
    }
    floatPos += floatPosInc;
  }

  return f;

}
//#ifdef __CYGWIN__
char* itoa (int value, char * buffer, int radix) {
  if (sprintf(buffer, "%x", value)) return buffer;
  else return NULL;
}
//#endif

/*----------------------------------------------
 | checkEndian
 +----------------------------------------------*/
int checkEndian() {

    union
    {
	long l;
	char c[sizeof(long)];
    } u;
    u.l = 1;
    return (u.c[sizeof(long)-1] == 1);
    /* Return 0 (success) if we're little-endian, or 1 (fail) if big-endian */

}

/*----------------------------------------------
 | floatToBin
 +----------------------------------------------*/
sc_fixed<32,32> floatToBin(const void *obj, size_t size){

  const int max_size=3;
  int endian = checkEndian();
  sc_fixed<32,32> rep;
  unsigned char* byte = NULL;
  byte =  new unsigned char[max_size];
  byte = (unsigned char*)obj;
  if (endian == LITTLEENDIAN ){
    byte += size - 1;
  }
  //float is of max size 3 ie 24 bits
  int size_tmp = size;
  while ( size_tmp-- ){
	char tmp[4];
	sprintf(tmp,"%d", *byte);
    rep.range((size_tmp+1)*8-1,size_tmp*8) = atoi(tmp);
    byte += (endian == LITTLEENDIAN) ? -1 : 1;
  }
  return rep;
}

/*----------------------------------------------
 | BinToFloat
 +----------------------------------------------*/
float binToFloat(const sc_fixed<32,32> obj){

  int endian = checkEndian();
  sc_bit sign = (sc_bit)(obj[31]);
  sc_ufixed<8,8> exponent = 0;
  exponent.range(7,0) = obj.range(30, 23);
  float mantissa =0;
  //cout << "binToFloat(): obj is " << obj.to_string(SC_HEX) ;
  //convert mantissa to decimal
  for (int i=22; i >=0; i--) {
    if (obj[i] == 1) {
      mantissa+=pow((float)2.0,(float)-1.0*(23-i));
    }
  }
  //cout << " mantissa is " << mantissa << " exponent is " << exponent ; 
  float rep=0;
  //check for the special case of 0 - then set to 0
  if (mantissa == 0 && exponent == 0) {
    rep = 0;
  }else {
    rep = pow((float)2.0,(float)exponent-127);
  }
  if (sign == 1) {
    rep = -1*(1+mantissa)*rep;
  }else {
    rep = (1+mantissa)*rep;
  }
  // cout << " float is " << rep << endl;
  return rep;
}

