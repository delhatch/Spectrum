#ifndef UTIL_H
#define UTIL_H
#define SC_INCLUDE_FX
#include "systemc.h"
#include "math.h"

#define BIT_REVERSE 0
#define NATURAL_ORDER 1
#define DC_CENTER_ORDER 2
#define MAX_FFTPTS 262144
#define BIGENDIAN 1
#define LITTLEENDIAN 0

#ifndef MEX_COMPILE
enum {
    AV_IN_FFTPTS,
    AV_IN_INVERSE,
    AV_IN_EOP,
    AV_IN_ERROR,
    AV_IN_IMAG,
    AV_IN_REAL,
    AV_IN_SOP,
    AV_IN_SIZE
};

enum {
    AV_OUT_FFTPTS,
    AV_OUT_EOP,
    AV_OUT_ERROR,
    AV_OUT_IMAG,
    AV_OUT_REAL,
    AV_OUT_SOP,
    AV_OUT_SIZE
};
#endif

int log2_int(int arg);
void func_bit_reverse(double* real, double* imag, int fftpts);
void func_index_reverse(double* real, double* imag, int fftpts);
char convertCharToHexNibble(const char c);
float convertHexStringToFloat(char* hexString);

#ifdef __CYGWIN__
char* itoa (int value, char* buffer, int radix);
#endif

int checkEndian();
sc_fixed<32, 32> floatToBin(const void* obj, size_t size);
float binToFloat(const sc_fixed<32, 32> obj);

#endif
