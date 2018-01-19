#include "stdio.h"
#include "math.h"
#include "stdlib.h"

//  Altera FFT MegaCore ver 6.1
//  12/10/04 model.c : Example FFT testbench
void main(int argc, int argv[])
{
    FILE* fid;
    FILE* fidr;
    FILE* fidi;
    const double pi = 3.14159265358979;
    double* real_data_in = {'\0'};
    double* imag_data_in = {'\0'};
    double* fft_real_out = {'\0'};
    double* fft_imag_out = {'\0'};
    double* exponent_out = {'\0'};
    int* dr_in = {'\0'};
    int* di_in = {'\0'};

    double data_prec = 16.0;
    double twiddle_prec = 16.0;
    double N = 2048.0;
    double arch = 0.0;
    double throughput = 4.0;
    double direction = 0.0;
    int i;

    void Sfftmodel(double * fft_real_out,
                   double * fft_imag_out,
                   double * exponent_out,
                   double * real_data_in,
                   double * imag_data_in,
                   double points,
                   double throughput,
                   double arch,
                   double mpr,
                   double twr,
                   double direction
                  );
    real_data_in = malloc(sizeof(double) * (int)N);
    imag_data_in = malloc(sizeof(double) * (int)N);
    fft_real_out = malloc(sizeof(double) * (int)N);
    fft_imag_out = malloc(sizeof(double) * (int)N);
    exponent_out = malloc(sizeof(double) * (int)N);
    dr_in = malloc(sizeof(int) * (int)N);
    di_in = malloc(sizeof(int) * (int)N);


    /***************************************************************************
     * Create input arrays to model
     **************************************************************************/
    fidr = fopen("real_input.txt", "rt");
    fidi = fopen("imag_input.txt", "rt");
    if (fidr < 0 || fidi < 0) {
        printf("can't open input files\n");
    }
    for (i = 0; i < N; i++) {
        fscanf(fidr, "%d", &dr_in[i]);
        //real_data_in[i] = (double)dr_in[i];
        real_data_in[i] = 0;
        fscanf(fidi, "%d", &di_in[i]);
        imag_data_in[i] = 0;
        //imag_data_in[i] = (double)di_in[i];
    }
    fclose(fidr);
    fclose(fidi);
    /***************************************************************************
     * Set FFT Core Parameters
     **************************************************************************/
    // N : FFT Transform Length
    N = 128.0;
    // data_prec : Input Data Precision
    data_prec = 16.0;
    // twiddle_prec : Twiddle Factor Precision
    twiddle_prec = 16.0;
    // direction : FFT Transform direction
    // 0.0 : FFT
    // 1.0 : Inverse FFT
    direction = 0.0;
    // arch : FFT Architecture
    // 0.0 : Streaming Architecture
    // 1.0 : Buffered Burst Architecture
    // 2.0 : Burst Architecture
    arch = 2.0;
    // throughput : FFT Engine Throughput
    // 1.0 Single Output
    // 4.0 Quad Output
    throughput = 4.0;
    /****************************************************************************
     * Call to External FFT
     * Output: fft_real_out : Real Component Output : Double Array of Length N
     *         fft_imag_out : Imaginary Component Output : Double Array of Length N
     *         exponent_out : Block Floating Point Exponent : Double Array of Length N
     * Input : real_data_in : Real Component Input : Double Array of Length N
     *         imag_data_in : Imaginary Component Input : Double Array of Length N
     ***************************************************************************/
    Sfftmodel(     fft_real_out,
                   fft_imag_out,
                   exponent_out,
                   real_data_in,
                   imag_data_in,
                   N,
                   throughput,
                   arch,
                   data_prec,
                   twiddle_prec,
                   direction
             );

    /*******************************************************************************
     * Write Results to Disk
     *******************************************************************************/
    // Output Data Dump File
    fid = fopen("fft_test.txt", "wt");

    for (i = 0; i < (int)N; i++) {
        fprintf(fid, "\t%lf\t%lf\t%lf\n", fft_real_out[i], fft_imag_out[i], exponent_out[i]);
    }
    fclose(fid);
}
