#ifndef FFT_H
#define FFT_H

#include <string>

#ifndef FFT_NAME
#define FFT_NAME fft
#endif
#ifndef MEX_COMPILE
#define SC_INCLUDE_FX
#endif

class FFT_NAME
{
public:
    FFT_NAME(int in_dw_, int out_dw_, int fftpts_size_, int twidw_,
             int rounding_type_, int output_order_, int input_order_, int rep_, int svopt);
    FFT_NAME(int in_dw_, int out_dw_, int fftpts_size_, int twidw_,
             int rounding_type_, int output_order_, int input_order_, int rep_, int svopt,
             double* prune_);
    ~FFT_NAME();
    
    void SVSfftmodel(double*, double*);
    void setThisFftpts(int);
    void setThisInverse(int);
    int getThisFftpts();
    int getThisInverse();
    void func_compute_fft(double*, double*);

private:
    void fft_fixedpt_kernel(double*, double*, double*, double*, int, int, int);
    void fft_floatpt_kernel(double*, double*, double*, double*, int, int, int);
    void fft_floatpt_mr42_kernel(double*, double*, double*, double*, int, int, int);
    void func_radix_2_fixedpt_bfI (double*, double*, int, int );
    void func_radix_2_fixedpt_bfII (double*, double*, int, int );
    void func_radix_2_floatpt_bfI (double*, double*, int, int );
    void func_radix_2_floatpt_bfII (double*, double*, int, int );
    int func_gen_fixedpt_twids_r22(double*, double*, int);
    int func_gen_floatpt_twids_r22(double*, double*, int);
    int func_gen_floatpt_twids(double*, double*, int);
    void print_fixedpt_values(double*, double*, int, const std::string&, int, int);
    void print_floatpt_values(double*, double*, const std::string&, int, int);
    void calc_all_cma_datawidths(double*);
    bool perform_mult(int, int);
    bool perform_bfii(int, int);
    void inverse_data(double*& real, double*& imag);
    int calc_delay(int);
    int calc_delay(int, int);
    bool is_first_stage(int, int);
    void calc_stage(double*, double*, int&, int, int&, int, int);
    const bool is_reverse_float_fft();

    //  void func_bit_reverse(double*,double*);
    int in_dw;
    int out_dw;
    int twidw;
    int fftpts_size;
    int max_fftpts;
    int rounding_type;
    int output_order;
    int input_order;
    int representation;
    int svopt;
    bool bit_reverse_core;
    bool max_pwr_2;
    // settings for the current block
    int this_fftpts;
    int this_inverse;
    bool radix_2_lp;
    int effective_fftpts;
    int* cma_datawidths;
    int max_num_stages;
};

#endif
