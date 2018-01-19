#define SC_INCLUDE_FX

/* This is the implementation file for the synchronous process "fft" */
#include <iostream>
#include "util.h"
#include "fpCompiler.h"
#include "systemc.h"
#include "fft.h"
#include <cmath>
#include <stdio.h>
#include <stdlib.h>
#ifdef MEX_COMPILE
#include "mex.h"
#endif

#define PI 3.14159265358979323846
#define TWO_PI 6.283185307179586476925286766559
#define RND_CONV 1
#define TRN_0 0
#define COUT_FMT SC_DEC
#define FIXEDPT 0
#define FLOATPT 1


using namespace std;
extern void _main();

//Function for butterfly computation
FFT_NAME::FFT_NAME(int in_dw_, int out_dw_, int fftpts_size_, int twidw_,
                   int rounding_type_, int output_order_, int input_order_, int rep_, int svopt_, double* prune_)
{
    in_dw = in_dw_;
    out_dw = out_dw_;
    fftpts_size = fftpts_size_;
    twidw = twidw_;
    rounding_type = rounding_type_;
    output_order = output_order_;
    input_order = input_order_;
    representation = rep_;
    svopt = (svopt_);

    //derived parameters
    max_fftpts = 1 << (fftpts_size_ - 1);
    max_pwr_2 = log2_int(max_fftpts) % 2;//(bool)((int)ceil(log2(max_fftpts)) % 2);
    max_num_stages = (int)ceil(double((log((double)max_fftpts) / log(2.0)) / log2_int(4)));
    cma_datawidths = new int[max_num_stages];
    calc_all_cma_datawidths(prune_);

    if (input_order == NATURAL_ORDER || input_order == DC_CENTER_ORDER) {
#ifdef DEBUG_FFT
        cout << "fft: SVSfftmodel: Transform size: " << this_fftpts << " using natural-order inputs.\n";
#endif
        bit_reverse_core = false;
    } else {
#ifdef DEBUG_FFT
        cout << "fft: SVSfftmodel: Transform size: " << this_fftpts << " using bit-reversed inputs.\n";
#endif
        bit_reverse_core = true;
    }
}


//Function for butterfly computation
FFT_NAME::FFT_NAME(int in_dw_, int out_dw_, int fftpts_size_, int twidw_,
                   int rounding_type_, int output_order_, int input_order_, int rep_, int svopt_)
{
    in_dw = in_dw_;
    out_dw = out_dw_;
    fftpts_size = fftpts_size_;
    twidw = twidw_;
    rounding_type = rounding_type_;
    output_order = output_order_;
    input_order = input_order_;
    representation = rep_;
    svopt = svopt_;

    //derived parameters
    max_fftpts = 1 << (fftpts_size_ - 1);
    max_pwr_2 = log2_int(max_fftpts) % 2;//(bool)((int)ceil(log2(max_fftpts)) % 2);
    max_num_stages = (int)ceil(double((log((double)max_fftpts) / log(2.0)) / log2_int(4)));
    cma_datawidths = new int[max_num_stages];
    double* prune = new double[max_num_stages];
    for (int i = 0; i < max_num_stages; i++) {
        prune[i] = 0.0;
    }
    calc_all_cma_datawidths(prune);
    delete [] prune;

    if (representation == FLOATPT && svopt != 3) {
#ifdef DEBUG_FFT
        cout << "fft: SVSfftmodel: Transform size: " << this_fftpts << " using natural-order inputs.\n";
#endif
        bit_reverse_core = input_order == BIT_REVERSE ? true : false;
    } else {
        if (input_order == NATURAL_ORDER || input_order == DC_CENTER_ORDER) {
#ifdef DEBUG_FFT
            cout << "fft: SVSfftmodel: Transform size: " << this_fftpts << " using natural-order inputs.\n";
#endif
            bit_reverse_core = false;
        } else {
#ifdef DEBUG_FFT
            cout << "fft: SVSfftmodel: Transform size: " << this_fftpts << " using bit-reversed inputs.\n";
#endif
            bit_reverse_core = true;
        }
    }
}

FFT_NAME::~FFT_NAME()
{
    delete [] cma_datawidths;
}

void FFT_NAME::setThisFftpts(int fftpts_)
{
    this_fftpts = fftpts_;
    // set effective fftpts, and radix_2_lp
    if (((log2_int(this_fftpts)) % 2 ) == 1 ) {
        //effectively the same hardware as the transform of 2x size
        effective_fftpts = 2 * this_fftpts;
        radix_2_lp = true;
    } else {
        radix_2_lp = false;
        effective_fftpts = this_fftpts;
    }

}

void FFT_NAME::setThisInverse(int inverse_)
{
    this_inverse = inverse_;
}

int FFT_NAME::getThisFftpts()
{
    return this_fftpts;
}

int FFT_NAME::getThisInverse()
{
    return this_inverse;
}

void FFT_NAME::func_radix_2_fixedpt_bfI (double* real, double* imag, int delay, int dw)
{
    for (int i = 0; i <= ((this_fftpts / (delay * 2)) - 1); i++) {
        for (int k = 0; k <= (delay - 1); k++) {
            int j = (delay * 2 * i) + k;
            double real_tmp_l = real[j] + real[j + delay];
            double imag_tmp_1 = imag[j] + imag[j + delay];
            double real_tmp_h = real[j] - real[j + delay];
            double imag_tmp_h = imag[j] - imag[j + delay];
            real[j] = real_tmp_l;
            imag[j] = imag_tmp_1;
            real[j + delay] = real_tmp_h;
            imag[j + delay] =  imag_tmp_h;
        }
    }

    print_fixedpt_values(real, imag, dw, "func_compute_fft: in bfi", 0, 32);
}

void FFT_NAME::func_radix_2_floatpt_bfI (double* real, double* imag, int delay, int dw)
{
    for (int i = 0; i <= ((this_fftpts / (delay * 2)) - 1); i++) {
        for (int k = 0; k <= (delay - 1); k++) {
            int j = (delay * 2 * i) + k;
            double real_tmp_l = (double)((float)real[j] + (float)real[j + delay]);
            double imag_tmp_1 = (double)((float)imag[j] + (float)imag[j + delay]);
            double real_tmp_h = (double)((float)real[j] - (float)real[j + delay]);
            double imag_tmp_h = (double)((float)imag[j] - (float)imag[j + delay]);
            real[j] = real_tmp_l;
            imag[j] = imag_tmp_1;
            real[j + delay] = real_tmp_h;
            imag[j + delay] = imag_tmp_h;
        }
    }
}

void FFT_NAME::func_radix_2_fixedpt_bfII (double* real, double* imag, int delay, int dw)
{
    //perform the trivial multiplication
    int ctr = 0;
    int triv = 0;
    int triv_delay = 0;
    if (input_order == BIT_REVERSE) {
        triv_delay = delay / 2;
    } else {
        triv_delay = delay;
    }
    triv = 3 * triv_delay;
    if (delay == 0 ) {
        return;
    }
    for (int k = 0; k < this_fftpts; k++) {
        ctr = ctr % (triv_delay * 4);
        if (ctr >= triv) {
            double real_tmp = imag[k];
            imag[k] = -real[k];
            real[k] = real_tmp;
        }
        ctr = ctr + 1;
    }
    for (int m = 0; m <= (this_fftpts / (delay * 2) - 1); m++) {
        for (int k = 0; k <= delay - 1; k++) {
            int j = (delay * 2 * m) + k ;
            double real_tmp_l = real[j] + real[j + delay];
            double imag_tmp_1 = imag[j] + imag[j + delay];
            double real_tmp_h = real[j] - real[j + delay];
            double imag_tmp_h = imag[j] - imag[j + delay];
            real[j] = real_tmp_l;
            imag[j] = imag_tmp_1;
            real[j + delay] = real_tmp_h;
            imag[j + delay] =  imag_tmp_h;
        }
    }
}

void FFT_NAME::func_radix_2_floatpt_bfII (double* real, double* imag, int delay, int dw)
{
    //perform the trivial multiplication
    int ctr = 0;
    int triv = 0;
    int triv_delay = 0;
    if (input_order == BIT_REVERSE) {
        triv_delay = delay / 2;
    } else {
        triv_delay = delay;
    }
    triv = 3 * triv_delay;
    if (delay == 0 ) {
        return;
    }
    for (int k = 0; k < this_fftpts; k++) {
        ctr = ctr % (triv_delay * 4);
        if (ctr >= triv) {
            double real_tmp = imag[k];
            imag[k] = -real[k];
            real[k] = real_tmp;
        }
        ctr = ctr + 1;
    }
    for (int m = 0; m <= (this_fftpts / (delay * 2) - 1); m++) {
        for (int k = 0; k <= delay - 1; k++) {
            int j = (delay * 2 * m) + k ;
            double real_tmp_l = (double)((float)real[j] + (float)real[j + delay]);
            double imag_tmp_1 = (double)((float)imag[j] + (float)imag[j + delay]);
            double real_tmp_h = (double)((float)real[j] - (float)real[j + delay]);
            double imag_tmp_h = (double)((float)imag[j] - (float)imag[j + delay]);
            real[j] = real_tmp_l;
            imag[j] = imag_tmp_1;
            real[j + delay] = real_tmp_h;
            imag[j + delay] =  imag_tmp_h;
        }
    }
}

int FFT_NAME::func_gen_fixedpt_twids_r22(double* twid_real, double* twid_imag, int stage)
{
    //determine how many rom points in this stage

    int rom_pts = (int)(effective_fftpts / (pow(4.0, stage)));
    int ma[3] = {effective_fftpts / rom_pts * 2,
                 effective_fftpts / rom_pts * 1,
                 effective_fftpts / rom_pts * 3
                };
    int addr = 0;
    int mag_twid = (int)pow(2.0, (twidw - 1)) - 1;
    //first n/4 points are 1
    for (int n = 0; n < rom_pts / 4; n++) {
        //double one_scaled=round(1*mag_twid);
        double one_scaled = floor(1 * mag_twid + 0.5);
        twid_real[addr] = one_scaled;
        twid_imag[addr] = 0.0;
        addr++;
    }
    for (int m = 0; m <= 2; m++) {
        for (int n = 0; n <= (rom_pts / 4 - 1); n++) {
            double exp_real = cos(-1 * TWO_PI * n * ma[m] / ((double)effective_fftpts));
            double exp_imag = sin(-1 * TWO_PI * n * ma[m] / ((double)effective_fftpts));
            twid_real[addr] = floor(exp_real * mag_twid + 0.5);
            twid_imag[addr] = floor(exp_imag * mag_twid + 0.5);
            addr++;
        }
    }
#ifdef DEBUG_FFT
    print_fixedpt_values(twid_real, twid_imag, twidw, "func_gen_fixedpt_twids_r22", stage, addr) ;
#endif
    return rom_pts;
}

int FFT_NAME::func_gen_floatpt_twids_r22(double* twid_real, double* twid_imag, int stage)
{
    //determine how many rom points in this stage

    int rom_pts = (int)(effective_fftpts / (pow(4.0, stage)));
    int ma[3] = {effective_fftpts / rom_pts * 2,
                 effective_fftpts / rom_pts * 1,
                 effective_fftpts / rom_pts * 3
                };
    int addr = 0;
    //first n/4 points are 1
    for (int n = 0; n < rom_pts / 4; n++) {
        twid_real[addr] = 1.0;
        twid_imag[addr] = 0.0;
        addr++;
    }
    for (int m = 0; m <= 2; m++) {
        for (int n = 0; n <= (rom_pts / 4 - 1); n++) {
            double exp_real = cos(-1 * TWO_PI * n * ma[m] / ((double)effective_fftpts));
            double exp_imag = sin(-1 * TWO_PI * n * ma[m] / ((double)effective_fftpts));
            twid_real[addr] = exp_real;
            twid_imag[addr] = exp_imag;
            addr++;
        }
    }

    return rom_pts;
}

static bool or_reduce ( int num, int num_lsbs )
{
    if ( num_lsbs < 1 ) {
        return false;
    }
    int mask = 2 ^ num_lsbs - 1;
    num &= mask;
    return num > 0 ? true : false;
}

int FFT_NAME::func_gen_floatpt_twids(double* twid_real, double* twid_imag, int stage)
{
    const double TWO_PI_F = PI * 2;
    int rom_pts;
    int addr = 0;
    if ( is_reverse_float_fft() ) {
        //This is a slightly modified version of the RTL twiddle address calculation logic.
        //The modification was to increment "count" by "stride" rather than 1. This removes repetition
        //of twiddle factors by a factor of "stride" for pure radix 4 and "stride/2" for mixed radix.
        //In software we can simply access the same twiddle factors "stride" or "stride/2" times.
        //Also note that in hardware the twiddle rom stores the value of a certain twiddle factor just once.
        //In software we may store the value of a certain twiddle factor multiple times to simplyfy the
        //access patter later.
        //Also note for informatin that in hardware, if the delay is more than 1, the first
        //outputs of "delay" number of butterflies are calculated before the second outputs are
        //calculated and so on. In sotware, we calculated all four/two outputs of a butterfly together.
        int log2nps = log2_int(effective_fftpts);
        int addwidth = 2 * (stage + 1);
        int twidwidth = log2nps - stage * 2;
        int twaddind = 0;
        int rvsadd_mask = (1 << twidwidth) - 1;
        int stride = radix_2_lp && stage == 0 ? 2 : pow( 4.0, stage );
        rom_pts = effective_fftpts / pow( 4.0, stage );

        for (int count = 0; count < effective_fftpts; count += stride ) {
            int bf_num = count >> (2 * (stage + 1));
            int fwdadd = bf_num * std::pow( 4.0, stage + 1);
            int rvsadd = 0;
            for ( int j = 0; j < log2nps / 2; ++j ) {
                rvsadd |= ((fwdadd >> (2 * j + 1)) & 1)   << (log2nps - 1 - 2 * j);
                rvsadd |= ((fwdadd >> (2 * j)    ) & 1)   << (log2nps - 2 - 2 * j);
            }

            bool count_addwidth_minus_one = (count >> (addwidth - 1)) & 1;
            bool count_addwidth_minus_two = (count >> (addwidth - 2)) & 1;

            bool addzer = !count_addwidth_minus_one && !count_addwidth_minus_two && !or_reduce( count, addwidth - 2 );
            bool addone = !count_addwidth_minus_one &&  count_addwidth_minus_two && !or_reduce( count, addwidth - 2 );
            bool addtwo =  count_addwidth_minus_one && !count_addwidth_minus_two && !or_reduce( count, addwidth - 2 );
            bool addthr =  count_addwidth_minus_one &&  count_addwidth_minus_two && !or_reduce( count, addwidth - 2 );

            bool addtwaddind = addone | addtwo | addthr;

            int rvsadd_scale = radix_2_lp && stage == 0 ? 2 : 1;
            if ( addzer ) {
                twaddind = 0;
            } else if (addtwaddind) {
                twaddind += (rvsadd * rvsadd_scale & rvsadd_mask);
            }
            double exp_real = cos(-1 * TWO_PI_F * twaddind / ((double)rom_pts));
            double exp_imag = sin(-1 * TWO_PI_F * twaddind / ((double)rom_pts));
            twid_real[addr] = (float)exp_real;
            twid_imag[addr] = (float)exp_imag;
            addr++;
        }
    } else {
        //determine how many rom points in this stage

        rom_pts = (int)(effective_fftpts / (pow(4.0, stage)));
        int ma[3];

        //  R22SDF FLOATPT
        //  ma[0] = effective_fftpts/rom_pts*2;
        //  ma[1] = effective_fftpts/rom_pts*1;
        //  ma[2] = effective_fftpts/rom_pts*3;

        //  MR42 FLOATPT
        ma[0] = effective_fftpts / rom_pts * 1;
        ma[1] = effective_fftpts / rom_pts * 2;
        ma[2] = effective_fftpts / rom_pts * 3;

        //first n/4 points are 1
        for (int n = 0; n < rom_pts / 4; n++) {
            twid_real[addr] = 1.0;
            twid_imag[addr] = 0.0;
            addr++;
        }
        for (int m = 0; m <= 2; m++) {
            for (int n = 0; n <= (rom_pts / 4 - 1); n++) {
                double exp_real = cos(-1 * TWO_PI_F * n * ma[m] / ((double)effective_fftpts));
                double exp_imag = sin(-1 * TWO_PI_F * n * ma[m] / ((double)effective_fftpts));
                twid_real[addr] = (float)exp_real;
                twid_imag[addr] = (float)exp_imag;
                addr++;
            }
        }
    }
#ifdef DEBUG_FFT
    print_floatpt_values(twid_real, twid_imag, "func_gen_floatpt_twids", stage, addr) ;
#endif
    return rom_pts;
}

void FFT_NAME::fft_floatpt_mr42_kernel(double* real, double* imag, double* real_twid, double* imag_twid, int delay, int num_twids, int laststage)
{
    int twid_index = 0;
    int twid_use_cnt = 0;
    bool doing_smaller_fft_than_max = this->this_fftpts != this->max_fftpts;
    bool is_last_stage = (laststage == 1);
    bool do_multiply = !is_last_stage || (doing_smaller_fft_than_max && is_reverse_float_fft());
    bool laststage_radix_2 = radix_2_lp && is_last_stage && !is_reverse_float_fft();
    bool first_stage_radix_2 = radix_2_lp && delay == 1 && is_reverse_float_fft();
    delay = is_reverse_float_fft() && radix_2_lp && delay > 1 ? delay / 2 : delay;

    for (int m = 0; m < this_fftpts; m++) {
        float real_in_float_d = real[m];
        float imag_in_float_d = imag[m];
        float real_in_float_c = 0;
        float imag_in_float_c = 0;
        float real_in_float_b = 0;
        float imag_in_float_b = 0;
        float real_in_float_a = 0;
        float imag_in_float_a = 0;

        if ((m - delay) >= 0) {
            real_in_float_c = real[m - delay];
            imag_in_float_c = imag[m - delay];
        }

        if ( first_stage_radix_2 ) {
            real_in_float_b = 0.0;
            imag_in_float_b = 0.0;
            real_in_float_a = 0.0;
            imag_in_float_a = 0.0;
        } else if (!laststage_radix_2) {
            if ((m - 2 * delay) >= 0) {
                real_in_float_b = real[m - 2 * delay];
                imag_in_float_b = imag[m - 2 * delay];
            }

            if ((m - 3 * delay) >= 0) {
                real_in_float_a = real[m - 3 * delay];
                imag_in_float_a = imag[m - 3 * delay];
            }
        }

        float real_twid_in_float_d = 0;
        float imag_twid_in_float_d = 0;
        float real_twid_in_float_c = 0;
        float imag_twid_in_float_c = 0;
        float real_twid_in_float_b = 0;
        float imag_twid_in_float_b = 0;
        float real_twid_in_float_a = 0;
        float imag_twid_in_float_a = 0;

        if ( is_reverse_float_fft() ) {
            if ( first_stage_radix_2 && m % 2 ) {
                real_twid_in_float_b = real_twid[(twid_index + 1) % num_twids];
                imag_twid_in_float_b = imag_twid[(twid_index + 1) % num_twids];
                real_twid_in_float_a = real_twid[(twid_index + 0) % num_twids];
                imag_twid_in_float_a = imag_twid[(twid_index + 0) % num_twids];
                ++twid_use_cnt;
                if ( twid_use_cnt == delay ) {
                    twid_index += 2;
                    twid_use_cnt = 0;
                }
            } else if ((m % (4 * delay) - 3 * delay) >= 0) {
                real_twid_in_float_d = real_twid[(twid_index + 3) % num_twids];
                imag_twid_in_float_d = imag_twid[(twid_index + 3) % num_twids];
                real_twid_in_float_c = real_twid[(twid_index + 2) % num_twids];
                imag_twid_in_float_c = imag_twid[(twid_index + 2) % num_twids];
                real_twid_in_float_b = real_twid[(twid_index + 1) % num_twids];
                imag_twid_in_float_b = imag_twid[(twid_index + 1) % num_twids];
                real_twid_in_float_a = real_twid[(twid_index + 0) % num_twids];
                imag_twid_in_float_a = imag_twid[(twid_index + 0) % num_twids];
                ++twid_use_cnt;
                if ( twid_use_cnt == delay ) {
                    twid_index += 4;
                    twid_use_cnt = 0;
                }
            }
        } else {
            if (!laststage_radix_2) {
                real_twid_in_float_d = real_twid[m % num_twids];
                imag_twid_in_float_d = imag_twid[m % num_twids];
                if (radix_2_lp) {
                    real_twid_in_float_d = real_twid[(2 * m) % num_twids];
                    imag_twid_in_float_d = imag_twid[(2 * m) % num_twids];
                }

                if ((m % (4 * delay) - delay) >= 0) {
                    real_twid_in_float_c = real_twid[(m % num_twids) - delay];
                    imag_twid_in_float_c = imag_twid[(m % num_twids) - delay];
                    if (radix_2_lp) {
                        real_twid_in_float_c = real_twid[((2 * m) % num_twids) - 2 * delay];
                        imag_twid_in_float_c = imag_twid[((2 * m) % num_twids) - 2 * delay];
                    }
                }

                if ((m % (4 * delay) - 2 * delay) >= 0) {
                    real_twid_in_float_b = real_twid[(m % num_twids) - 2 * delay];
                    imag_twid_in_float_b = imag_twid[(m % num_twids) - 2 * delay];
                    if (radix_2_lp) {
                        real_twid_in_float_b = real_twid[((2 * m) % num_twids) - 4 * delay];
                        imag_twid_in_float_b = imag_twid[((2 * m) % num_twids) - 4 * delay];
                    }
                }

                if ((m % (4 * delay) - 3 * delay) >= 0) {
                    real_twid_in_float_a = real_twid[(m % num_twids) - 3 * delay];
                    imag_twid_in_float_a = imag_twid[(m % num_twids) - 3 * delay];
                    if (radix_2_lp) {
                        real_twid_in_float_a = real_twid[((2 * m) % num_twids) - 6 * delay];
                        imag_twid_in_float_a = imag_twid[((2 * m) % num_twids) - 6 * delay];
                    }
                }
            }
        }

        if (svopt == 3) {

            float tempr1;
            float tempr2;
            float tempr;

            float tempi1;
            float tempi2;
            float tempi;

            float real_mult;
            float imag_mult;

            if ( first_stage_radix_2 ) {
                if (m % 2) {
                    //part 1
                    tempr1 = real_in_float_a + real_in_float_b; // a and b are zeros
                    tempr2 = real_in_float_c + real_in_float_d;
                    tempr = tempr1 + tempr2;
                    tempi1 = imag_in_float_a + imag_in_float_b; // a and b are zeros
                    tempi2 = imag_in_float_c + imag_in_float_d;
                    tempi = tempi1 + tempi2;

                    if (do_multiply) {
                        real_mult = (tempr * real_twid_in_float_a) - (tempi * imag_twid_in_float_a);
                        imag_mult = (tempi * real_twid_in_float_a) + (tempr * imag_twid_in_float_a);

                    } else {
                        real_mult = tempr;
                        imag_mult = tempi;
                    }

                    real[m - 1] = real_mult;
                    imag[m - 1] = imag_mult;

                    //part 2
                    tempr1 = real_in_float_a + real_in_float_b; // a and b are zeros
                    tempr2 = real_in_float_c - real_in_float_d;
                    tempr = tempr1 + tempr2;
                    tempi1 = imag_in_float_a + imag_in_float_b; // a and b are zeros
                    tempi2 = imag_in_float_c - imag_in_float_d;
                    tempi = tempi1 + tempi2;

                    if (do_multiply) {
                        real_mult = (tempr * real_twid_in_float_b) - (tempi * imag_twid_in_float_b);
                        imag_mult = (tempi * real_twid_in_float_b) + (tempr * imag_twid_in_float_b);
                    } else {
                        real_mult = tempr;
                        imag_mult = tempi;
                    }

                    real[m] = real_mult;
                    imag[m] = imag_mult;
                }
            } else if (!laststage_radix_2) {

                if ((m % (4 * delay) - 3 * delay) >= 0) {

                    //part 1
                    tempr1 = real_in_float_a + real_in_float_b;
                    tempr2 = real_in_float_c + real_in_float_d;
                    tempr = tempr1 + tempr2;
                    tempi1 = imag_in_float_a + imag_in_float_b;
                    tempi2 = imag_in_float_c + imag_in_float_d;
                    tempi = tempi1 + tempi2;

                    if (do_multiply) {
                        real_mult = (tempr * real_twid_in_float_a) - tempi * (imag_twid_in_float_a);
                        imag_mult = (tempi * real_twid_in_float_a) + tempr * (imag_twid_in_float_a);

                    } else {
                        real_mult = tempr;
                        imag_mult = tempi;
                    }

                    real[m - 3 * delay] = real_mult;
                    imag[m - 3 * delay] = imag_mult;

                    //part 2
                    tempr1 = real_in_float_a + imag_in_float_b;
                    tempr2 =  - real_in_float_c - imag_in_float_d;
                    tempr = tempr1 + tempr2;
                    tempi1 = imag_in_float_a - real_in_float_b;
                    tempi2 =  - imag_in_float_c + real_in_float_d;
                    tempi = tempi1 + tempi2;

                    if (do_multiply) {
                        real_mult = (tempr * real_twid_in_float_b) - (tempi * imag_twid_in_float_b);
                        imag_mult = (tempi * real_twid_in_float_b) + (tempr * imag_twid_in_float_b);
                    } else {
                        real_mult = tempr;
                        imag_mult = tempi;
                    }

                    real[m - 2 * delay] = real_mult;
                    imag[m - 2 * delay] = imag_mult;

                    //part 3
                    tempr1 = real_in_float_a - real_in_float_b;
                    tempr2 = real_in_float_c - real_in_float_d;
                    tempr = tempr1 + tempr2;
                    tempi1 = imag_in_float_a - imag_in_float_b;
                    tempi2 = imag_in_float_c - imag_in_float_d;
                    tempi = tempi1 + tempi2;

                    if (do_multiply) {
                        real_mult = (tempr * real_twid_in_float_c) - (tempi * imag_twid_in_float_c);
                        imag_mult = (tempi * real_twid_in_float_c) + (tempr * imag_twid_in_float_c);
                    } else {
                        real_mult = tempr;
                        imag_mult = tempi;
                    }

                    real[m - delay] = real_mult;
                    imag[m - delay] = imag_mult;

                    //part 4
                    tempr1 = real_in_float_a - imag_in_float_b;
                    tempr2 =  - real_in_float_c + imag_in_float_d;
                    tempr = tempr1 + tempr2;
                    tempi1 = imag_in_float_a + real_in_float_b;
                    tempi2 =  - imag_in_float_c - real_in_float_d;
                    tempi = tempi1 + tempi2;

                    if (do_multiply) {
                        real_mult = (tempr * real_twid_in_float_d) - (tempi * imag_twid_in_float_d);
                        imag_mult = (tempi * real_twid_in_float_d) + (tempr * imag_twid_in_float_d);
                    } else {
                        real_mult = tempr;
                        imag_mult = tempi;
                    }

                    real[m] = real_mult;
                    imag[m] = imag_mult;
                }

            } else {

                if (m % 2) {


                    tempr = real_in_float_c + real_in_float_d;
                    tempi = imag_in_float_c + imag_in_float_d;
                    real[m - 1] = tempr;
                    imag[m - 1] = tempi;

                    tempr = real_in_float_c - real_in_float_d;
                    tempi = imag_in_float_c - imag_in_float_d;
                    real[m] = tempr;
                    imag[m] = tempi;
                }

            }
        } else {
            fpCompiler real_in_a(real_in_float_a, 0);
            fpCompiler imag_in_a(imag_in_float_a, 0);
            fpCompiler real_in_b(real_in_float_b, 0);
            fpCompiler imag_in_b(imag_in_float_b, 0);
            fpCompiler real_in_c(real_in_float_c, 0);
            fpCompiler imag_in_c(imag_in_float_c, 0);
            fpCompiler real_in_d(real_in_float_d, 0);
            fpCompiler imag_in_d(imag_in_float_d, 0);

            fpCompiler real_twid_in_a(real_twid_in_float_a, 1);
            fpCompiler imag_twid_in_a(imag_twid_in_float_a, 1);
            fpCompiler real_twid_in_b(real_twid_in_float_b, 1);
            fpCompiler imag_twid_in_b(imag_twid_in_float_b, 1);
            fpCompiler real_twid_in_c(real_twid_in_float_c, 1);
            fpCompiler imag_twid_in_c(imag_twid_in_float_c, 1);
            fpCompiler real_twid_in_d(real_twid_in_float_d, 1);
            fpCompiler imag_twid_in_d(imag_twid_in_float_d, 1);

            fpCompiler real_in_bn(real_in_float_b, 2);
            fpCompiler real_in_cn(real_in_float_c, 2);
            fpCompiler real_in_dn(real_in_float_d, 2);
            fpCompiler imag_in_bn(imag_in_float_b, 2);
            fpCompiler imag_in_cn(imag_in_float_c, 2);
            fpCompiler imag_in_dn(imag_in_float_d, 2);

            fpCompiler tempr1(0);
            fpCompiler tempr2(0);
            fpCompiler tempr(0);

            fpCompiler tempi1(0);
            fpCompiler tempi2(0);
            fpCompiler tempi(0);

            fpCompiler real_mult(0);
            fpCompiler imag_mult(0);

            if ( first_stage_radix_2 ) {
                if (m % 2) {
                    //part 1
                    tempr1 = real_in_a.add(real_in_b); // a and b are zeros
                    tempr2 = real_in_c.add(real_in_d);
                    tempr = tempr1.add(tempr2);
                    tempi1 = imag_in_a.add(imag_in_b); // a and b are zeros
                    tempi2 = imag_in_c.add(imag_in_d);
                    tempi = tempi1.add(tempi2);


                    if (do_multiply) {
                        tempr.signNorm();
                        tempi.signNorm();
                        real_mult = (tempr.mult(real_twid_in_a, svopt)).sub(tempi.mult(imag_twid_in_a, svopt));
                        imag_mult = (tempi.mult(real_twid_in_a, svopt)).add(tempr.mult(imag_twid_in_a, svopt));

                    } else {
                        real_mult = tempr;
                        imag_mult = tempi;
                    }

                    real[m - 1] = real_mult.cast2float();
                    imag[m - 1] = imag_mult.cast2float();

                    tempr1.clearObj();
                    tempr2.clearObj();
                    tempr.clearObj();
                    tempi1.clearObj();
                    tempi2.clearObj();
                    tempi.clearObj();

                    //part 2
                    tempr1 = real_in_a.add(real_in_b); // a and b are zeros
                    tempr2 = real_in_c.add(real_in_dn);
                    tempr = tempr1.add(tempr2);
                    tempi1 = imag_in_a.add(imag_in_b); // a and b are zeros
                    tempi2 = imag_in_c.add(imag_in_dn);
                    tempi = tempi1.add(tempi2);

                    if (do_multiply) {
                        tempr.signNorm();
                        tempi.signNorm();
                        real_mult = (tempr.mult(real_twid_in_b, svopt)).sub(tempi.mult(imag_twid_in_b, svopt));
                        imag_mult = (tempi.mult(real_twid_in_b, svopt)).add(tempr.mult(imag_twid_in_b, svopt));
                    } else {
                        real_mult = tempr;
                        imag_mult = tempi;
                    }

                    real[m] = real_mult.cast2float();
                    imag[m] = imag_mult.cast2float();

                    tempr1.clearObj();
                    tempr2.clearObj();
                    tempr.clearObj();
                    tempi1.clearObj();
                    tempi2.clearObj();
                    tempi.clearObj();
                }
            } else if (!laststage_radix_2) {

                if ((m % (4 * delay) - 3 * delay) >= 0) {

                    //part 1
                    tempr1 = real_in_a.add(real_in_b);
                    tempr2 = real_in_c.add(real_in_d);
                    tempr = tempr1.add(tempr2);
                    tempi1 = imag_in_a.add(imag_in_b);
                    tempi2 = imag_in_c.add(imag_in_d);
                    tempi = tempi1.add(tempi2);

                    if (do_multiply) {
                        tempr.signNorm();
                        tempi.signNorm();
                        real_mult = (tempr.mult(real_twid_in_a, svopt)).sub(tempi.mult(imag_twid_in_a, svopt));
                        imag_mult = (tempi.mult(real_twid_in_a, svopt)).add(tempr.mult(imag_twid_in_a, svopt));

                    } else {
                        real_mult = tempr;
                        imag_mult = tempi;
                    }

                    real[m - 3 * delay] = real_mult.cast2float();
                    imag[m - 3 * delay] = imag_mult.cast2float();

                    tempr1.clearObj();
                    tempr2.clearObj();
                    tempr.clearObj();
                    tempi1.clearObj();
                    tempi2.clearObj();
                    tempi.clearObj();

                    //part 2
                    tempr1 = real_in_a.add(imag_in_b);
                    tempr2 = real_in_cn.add(imag_in_dn);
                    tempr = tempr1.add(tempr2);
                    tempi1 = imag_in_a.add(real_in_bn);
                    tempi2 = imag_in_cn.add(real_in_d);
                    tempi = tempi1.add(tempi2);

                    if (do_multiply) {
                        tempr.signNorm();
                        tempi.signNorm();
                        real_mult = (tempr.mult(real_twid_in_b, svopt)).sub(tempi.mult(imag_twid_in_b, svopt));
                        imag_mult = (tempi.mult(real_twid_in_b, svopt)).add(tempr.mult(imag_twid_in_b, svopt));
                    } else {
                        real_mult = tempr;
                        imag_mult = tempi;
                    }

                    real[m - 2 * delay] = real_mult.cast2float();
                    imag[m - 2 * delay] = imag_mult.cast2float();

                    tempr1.clearObj();
                    tempr2.clearObj();
                    tempr.clearObj();
                    tempi1.clearObj();
                    tempi2.clearObj();
                    tempi.clearObj();

                    //part 3
                    tempr1 = real_in_a.add(real_in_bn);
                    tempr2 = real_in_c.add(real_in_dn);
                    tempr = tempr1.add(tempr2);
                    tempi1 = imag_in_a.add(imag_in_bn);
                    tempi2 = imag_in_c.add(imag_in_dn);
                    tempi = tempi1.add(tempi2);

                    if (do_multiply) {
                        tempr.signNorm();
                        tempi.signNorm();
                        real_mult = (tempr.mult(real_twid_in_c, svopt)).sub(tempi.mult(imag_twid_in_c, svopt));
                        imag_mult = (tempi.mult(real_twid_in_c, svopt)).add(tempr.mult(imag_twid_in_c, svopt));
                    } else {
                        real_mult = tempr;
                        imag_mult = tempi;
                    }

                    real[m - delay] = real_mult.cast2float();
                    imag[m - delay] = imag_mult.cast2float();

                    tempr1.clearObj();
                    tempr2.clearObj();
                    tempr.clearObj();
                    tempi1.clearObj();
                    tempi2.clearObj();
                    tempi.clearObj();

                    //part 4
                    tempr1 = real_in_a.add(imag_in_bn);
                    tempr2 = real_in_cn.add(imag_in_d);
                    tempr = tempr1.add(tempr2);
                    tempi1 = imag_in_a.add(real_in_b);
                    tempi2 = imag_in_cn.add(real_in_dn);
                    tempi = tempi1.add(tempi2);

                    if (do_multiply) {
                        tempr.signNorm();
                        tempi.signNorm();
                        real_mult = (tempr.mult(real_twid_in_d, svopt)).sub(tempi.mult(imag_twid_in_d, svopt));
                        imag_mult = (tempi.mult(real_twid_in_d, svopt)).add(tempr.mult(imag_twid_in_d, svopt));
                    } else {
                        real_mult = tempr;
                        imag_mult = tempi;
                    }

                    real[m] = real_mult.cast2float();
                    imag[m] = imag_mult.cast2float();
                }

            } else {

                if (m % 2) {

                    tempr1.clearObj();
                    tempr2.clearObj();
                    tempr.clearObj();
                    tempi1.clearObj();
                    tempi2.clearObj();
                    tempi.clearObj();

                    tempr = real_in_c.add(real_in_d);
                    tempi = imag_in_c.add(imag_in_d);
                    real[m - 1] = tempr.cast2float();
                    imag[m - 1] = tempi.cast2float();

                    tempr = real_in_c.sub(real_in_d);
                    tempi = imag_in_c.sub(imag_in_d);
                    real[m] = tempr.cast2float();
                    imag[m] = tempi.cast2float();
                }

            }
        }
    }
}

void FFT_NAME::fft_floatpt_kernel(double* real, double* imag, double* real_twid, double* imag_twid, int delay, int dw, int num_twids)
{

    for (int m = 0; m < this_fftpts; m++) {
        int grp = m / delay;
        int index = m % delay;

        float real_in = (float)real[m];
        float imag_in = (float)imag[m];

        float real_in_delay = 0;
        float imag_in_delay = 0;
        if ((m - delay) >= 0) {
            real_in_delay = (float)real[m - delay];
            imag_in_delay = (float)imag[m - delay];
        }
        float real_twid_in = (float)real_twid[m % num_twids];
        float imag_twid_in = (float)imag_twid[m % num_twids];
        // if this is a radix 2 size fft then we need to take only every 2nd memory address in the twiddle memory
        if (radix_2_lp) {
            real_twid_in = (float)real_twid[(2 * m) % num_twids];
            imag_twid_in = (float)imag_twid[(2 * m) % num_twids];
        }



        float real_out = 0.0;
        float imag_out = 0.0;
        float real_out_delay = 0.0;
        float imag_out_delay = 0.0;

        // twiddles for this computation
        float real_mult = 0.0;
        real_mult = real_in * real_twid_in - imag_in * imag_twid_in;
        float imag_mult = 0.0;
        imag_mult = imag_in * real_twid_in + real_in * imag_twid_in;

        //butterfly addtitions/subtractions
        real_out =  real_in_delay - real_mult;
        imag_out =  imag_in_delay - imag_mult;

        real_out_delay = real_mult + real_in_delay;
        imag_out_delay = imag_mult + imag_in_delay;

        

        //decide what to do with the computations
        if (grp % 2 == 0) {
            //pass through
            real[m] = (double)real_mult;
            imag[m] = (double)imag_mult;
        } else {
            real[m] = (double)real_out;
            imag[m] = (double)imag_out;
            real[m - delay] = (double)real_out_delay;
            imag[m - delay] = (double)imag_out_delay;
        }
        
    }

    
}

void FFT_NAME::fft_fixedpt_kernel(double* real, double* imag, double* real_twid, double* imag_twid, int delay, int dw, int num_twids)
{
    // combine bfi, multiplication into single operation
    /*
    Complex multiplication (x+iy)*(a+ib)= xa -yb + i(ya +xb), followed by butterfly additions and subtractions

    Switch to sc_fix to perform the multiplication. The output is rounded down, which for the parameter
    combinations possible, will always result in a number that can be represented as a double.
    So only the complex multiplication  needs to be done in sc_fix format.
    */
    //dw=32;

    //twiddle fixed point type
    sc_fxtype_params param_twid_conv(twidw, twidw, SC_RND_CONV, SC_WRAP);
    sc_fxtype_context twid_conv_cxt(param_twid_conv, SC_LATER);
    twid_conv_cxt.begin();
    sc_fix real_twid_in;
    sc_fix imag_twid_in;
    //cout << "delay is " << delay << endl;
    for (int m = 0; m < this_fftpts; m++) {
        int grp = m / delay;
        int index = m % delay;
        //cout << "m is  "<< m <<" grp is " << grp  << " index is " << index;

        //data fixed point type, multiplication size
        sc_fxtype_params param_data_mult_conv(dw, dw, SC_RND_CONV, SC_WRAP);
        sc_fxtype_params param_data_bfi_conv(dw + 1, dw + 1, SC_RND_CONV, SC_WRAP);
        sc_fxtype_context data_mult_cxt(param_data_mult_conv, SC_LATER);
        sc_fxtype_context data_bfi_cxt(param_data_bfi_conv, SC_LATER);
        //multiplication fixed point type
        sc_fxtype_params param_mult_conv(dw + twidw + 1, dw + twidw + 1, SC_RND_CONV, SC_WRAP);
        sc_fxtype_context mult_conv_cxt(param_mult_conv, SC_LATER);

        data_mult_cxt.begin();

        sc_fix real_in = real[m];
        sc_fix imag_in = imag[m];

        sc_fix real_in_delay = 0;
        sc_fix imag_in_delay = 0;
        if ((m - delay) >= 0) {
            real_in_delay = real[m - delay];
            imag_in_delay = imag[m - delay];
        }

        // if this is a radix 2 size fft then we need to take only evey 2nd memory address in the twiddle memory

        if (!radix_2_lp) {
            real_twid_in = real_twid[m % num_twids];
            imag_twid_in = imag_twid[m % num_twids];
            //cout << " twid index " << m ;
        } else {
            real_twid_in = real_twid[(2 * m) % num_twids];
            imag_twid_in = imag_twid[(2 * m) % num_twids];
            //cout << " twid index " << 2*m ;
        }
        mult_conv_cxt.begin();

        //cout << "   real_in " << real_in << " imag_in " << imag_in ;

        // twiddles for this computation
        sc_fix real_mult = (real_in * real_twid_in - imag_in * imag_twid_in);
        sc_fix imag_mult = (imag_in * real_twid_in + real_in * imag_twid_in);

        //cout << "  before rounding real_mult " << real_mult << " imag_mult " << imag_mult ;

        real_mult = real_mult >> (twidw - 1);
        imag_mult = imag_mult >> (twidw - 1);

        //cout << " real_mult " << real_mult << " imag_mult " << imag_mult ;

        data_bfi_cxt.begin();

        sc_fix real_out;
        sc_fix imag_out;

        sc_fix real_out_delay;
        sc_fix imag_out_delay;

        //butterfly addtitions/subtractions
        real_out =  real_in_delay - real_mult;
        imag_out =  imag_in_delay - imag_mult;

        real_out_delay = real_mult + real_in_delay;
        imag_out_delay = imag_mult + imag_in_delay;

        //decide what to do with the computations
        if (grp % 2 == 0) {
            //pass through
            real[m] = real_mult;
            imag[m] = imag_mult ;
            //cout << " pass through setting real["<<m<<"] to " << real[m] << " imag["<<m<<"] to " << imag[m] << endl;
        } else {
            real[m] = real_out;
            imag[m] = imag_out;
            real[m - delay] = real_out_delay;
            imag[m - delay] = imag_out_delay;
            //cout << " perfoming multiplication setting real["<<m<<"] to " << real[m] << " imag["<<m<<"] to " << imag[m];
            //cout << " real["<<m-delay<<"] to " << real[m-delay] << " imag["<<m-delay<<"] to " << imag[m-delay] << endl;
        }
    }

    print_fixedpt_values(real, imag, dw + 1, "func_compute_fft: after fft kernel", 0, this_fftpts);
}

void FFT_NAME::print_fixedpt_values(double* real, double* imag, int this_dw, const string& func_name, int stage, int size)
{
#ifdef DEBUG_FFT
    cout << "fft: fixed pt" << func_name << ": stage: " << stage << ": dw: " << this_dw << endl;
    for (int s = 0; s < size; s++) {
        sc_fix  real_tmp(this_dw, this_dw);
        sc_fix  imag_tmp(this_dw, this_dw);
        real_tmp = real[s] ;
        imag_tmp = imag[s];
        cout << "fft:" << func_name << ": " << s ;
        cout << " real " << real_tmp.to_string(COUT_FMT);
        cout << " imag " << imag_tmp.to_string(COUT_FMT) << endl;
    }
    cout << "fft:" << func_name << ": End " << endl;
#endif
}
void FFT_NAME::print_floatpt_values(double* real, double* imag, const string& func_name, int stage, int size)
{
#ifdef DEBUG_FFT
    cout << "fft:" << func_name << ": stage: " << stage << endl;
    for (int s = 0; s < size; s++) {
        float freal = (float)real[s];
        float fimag = (float)imag[s];
        sc_fixed<32, 32> fpbinreal = floatToBin(&freal, sizeof(freal));
        sc_fixed<32, 32> fpbinimag = floatToBin(&fimag, sizeof(fimag));
        cout.precision(8);
        cout.width(15);
        //cout.fill('0');
        cout << "real\t" << real[s] << "   \t(" << fpbinreal.to_string(SC_HEX) << ")   \t";
        cout << "imag\t" << imag[s] << "   \t(" << fpbinimag.to_string(SC_HEX) << ")" << endl;
    }
    cout << "fft:" << func_name << ": End " << endl;
#endif
}

bool FFT_NAME::perform_mult(int num_stages, int this_stage)
{
    //if bit reverse
    int max_num_stages = (int)ceil(log2_int(max_fftpts) / (double)log2_int(4));
#ifdef DEBUG_FFT
    cout << "perfom_mult: this_stage " << this_stage << "is_first_stage " << is_first_stage(num_stages, this_stage);
    cout << " num_stages " << num_stages;
    cout << " max_num_stages " << max_num_stages << " radix_2_lp " << radix_2_lp;
    cout << " max_pwr_2 " << max_pwr_2 << endl;
#endif
    if (bit_reverse_core) {
        // No multiplicaiton in the first stage unless we have max_pwr_2 = 1 and
        // fftpts which is a pwr of 4. in this case the first bf is bypassed and the
        // first operation is a multiplicaiton by 1.
        if  (
            is_first_stage(num_stages, this_stage) && !(!radix_2_lp && max_pwr_2)
        ) {
            return false;
        }
        return true;
    } else {
        //first stage has a multiplication by 1 if it is  not the absolute first stage.
        //if it i sthe first stage, then only do the multiplication
        if (
            (!is_first_stage(num_stages, this_stage) &&
             ((this_stage < num_stages) || (( this_stage == num_stages) && ( !radix_2_lp  && max_pwr_2)))) ||
            (is_first_stage(num_stages, this_stage) && ( num_stages != max_num_stages) &&
             !(num_stages == max_num_stages - 1 && !radix_2_lp && max_pwr_2))
        ) {
            return true;
        }
        return false;
    }
}

bool FFT_NAME::perform_bfii(int num_stages, int this_stage)
{
    //if bit reverse
    int max_num_stages = (int)ceil(log2_int(max_fftpts) / (double)log2_int(4));
    if (bit_reverse_core) {
        //second stage bf unit. The bfii unit is not used if
        // 1. This is the first stage(absolute) and max_nps is a power of 4, and nps is a power of 2
        // 2. This is the first stage(absolute) and max_nps is a power of 2, and nps is a power of 2
        if ((is_first_stage(num_stages, this_stage) &&
                ( (radix_2_lp && max_pwr_2 ) || (!max_pwr_2 && radix_2_lp)))) {
            return false;
        }
        return true;
    } else {
        //second stage bf unit. If the last stage is radix 2 then no bfII
        if (! ( (this_stage == num_stages - 1) && radix_2_lp ))  {
            return true;
        }
        return false;
    }
}

void FFT_NAME::inverse_data(double*& real, double*& imag)
{
    double* tmp_imag = imag;
    imag = real;
    real = tmp_imag;
}

//for fixed point and r22 fpfft
int FFT_NAME::calc_delay(int this_stage_delay)
{
    if (bit_reverse_core) {
        return this_stage_delay * 2;
    } else {
        return this_stage_delay / 2;
    }
}

//for mr42 fpfft
int FFT_NAME::calc_delay(int this_stage_delay, int laststage)
{
    if (bit_reverse_core) {
        return this_stage_delay * 4;
    } else {
        if (radix_2_lp && ((laststage - 1) == 1)) {
            return this_stage_delay / 2;
        } else {
            return this_stage_delay / 4;
        }
    }
}

bool FFT_NAME::is_first_stage(int num_stages, int stage)
{
    if (bit_reverse_core) {
        if (stage == num_stages) {
            return true;
        }
        return false;
    } else {
        if (stage == 0) {
            return true;
        }
        return false;
    }
}

void FFT_NAME::calc_all_cma_datawidths(double* prune)
{
    //this is for the maximum size.
    //start with input datawidth, contains the input datawidth to each stage
    int datawidth = in_dw;

    //the datawidht at the output of the complex multiplier is calcuated
    cma_datawidths[0] = in_dw;
    for (int i = 0; i < max_num_stages; i++) {
        //pwr 4
        if (! max_pwr_2 ) {
            //second stage always returns 3, otherwise return 2.
            if (i == 1) {
                cma_datawidths[i] = datawidth + 1 - (int)prune[i];
                datawidth = datawidth + 3 - (int)prune[i];
            } else {
                cma_datawidths[i] = datawidth - (int)prune[i];
                datawidth = datawidth + 2 - (int)prune[i];
            }
        }

        //odd number of stages, pwr 2
        else {
            if (input_order == NATURAL_ORDER || input_order == DC_CENTER_ORDER) {
                //second stage always returns 3, last stage (radix 2) returns 1, otherwise return 2.
                if (i == 1) {
                    cma_datawidths[i] = datawidth + 1 - (int)prune[i];
                    datawidth = datawidth + 3 - (int)prune[i];
                } else {
                    cma_datawidths[i] = datawidth - (int)prune[i];
                    if (i == max_num_stages - 1) {
                        datawidth = datawidth + 1 - (int)prune[i];
                    } else {
                        datawidth = datawidth + 2 - (int)prune[i];
                    }
                }
            } else {
                //first stage returns 1, last stage returns 3, alternate stages, return 3
                if (i == 0) {
                    cma_datawidths[i] = datawidth - (int)prune[i];
                    datawidth = datawidth + 1  - (int)prune[i];
                } else if (i == 1) {
                    cma_datawidths[i] = datawidth + 1 - (int)prune[i];
                    datawidth = datawidth + 3 - (int)prune[i];
                } else {
                    cma_datawidths[i] = datawidth - (int)prune[i];
                    datawidth = datawidth + 2 - (int)prune[i];
                }
            }
        }
    }
}


void FFT_NAME::calc_stage(double* real, double* imag, int& this_dw, int num_stages, int& this_stage_delay, int stage, int cma_datawidth)
{
    //first stage butterfly unit, combined with multiplication, not for the first stage.
    //generate twiddles for this stage.
    double* twid_real = new double[MAX_FFTPTS];
    double* twid_imag = new double[MAX_FFTPTS];

    int num_twids = 0;
    this_dw = cma_datawidth;

    if (representation != FLOATPT || svopt == 3) {

        //----------------//
        //     R22SDF     //
        //----------------//

        if (perform_mult(num_stages, stage)) {
            if (representation == FIXEDPT) {
                num_twids = func_gen_fixedpt_twids_r22(twid_real, twid_imag, stage - 1);
            } else {
                num_twids = func_gen_floatpt_twids_r22(twid_real, twid_imag, stage - 1);
            }
        }

        if (!perform_mult(num_stages, stage)) {//is_first_stage(num_stages,stage))
            if (representation == FIXEDPT) {
                this_dw ++;
                func_radix_2_fixedpt_bfI(real, imag, this_stage_delay, this_dw);
            } else {
                func_radix_2_floatpt_bfI(real, imag, this_stage_delay, this_dw);
            }
        } else {
            if (representation == FIXEDPT) {
                fft_fixedpt_kernel(real, imag, twid_real, twid_imag, this_stage_delay, cma_datawidth, num_twids);
            } else {
                fft_floatpt_kernel(real, imag, twid_real, twid_imag, this_stage_delay, cma_datawidth, num_twids);
            }
        }
        if (representation == FIXEDPT) {
            print_fixedpt_values(real, imag, this_dw, "func_compute_fft: BFI", stage, this_fftpts);
        } else {
            print_floatpt_values(real, imag, "func_compute_fft: BFI", stage, this_fftpts);
        }

        //second stage bf unit. If the last stage is radix 2 then no bfII
        if (perform_bfii(num_stages, stage)) {
            this_stage_delay = calc_delay(this_stage_delay);
            //cout << "performing bfii" << endl;
            if (representation == FIXEDPT) {
                this_dw = cma_datawidth + 2;
                func_radix_2_fixedpt_bfII(real, imag, this_stage_delay, this_dw);
            } else {
                func_radix_2_floatpt_bfII(real, imag, this_stage_delay, this_dw);
            }
            if (representation == FIXEDPT) {
                print_fixedpt_values(real, imag, this_dw, "func_compute_fft: BFII", stage, this_fftpts);
            } else {
                print_floatpt_values(real, imag, "func_compute_fft: BFII", stage, this_fftpts);
            }
        } else {
            //cout << "not performing bfii" << endl;
        }

        this_stage_delay = calc_delay(this_stage_delay);
        delete [] twid_real;
        delete [] twid_imag;
    } else {

        //---------------------//
        //     MR42 FLOATPT    //
        //---------------------//
        num_twids = func_gen_floatpt_twids(twid_real, twid_imag, stage);
        fft_floatpt_mr42_kernel(real, imag, twid_real, twid_imag, this_stage_delay, num_twids, num_stages - stage);
        print_floatpt_values(real, imag, "func_compute_fft: MR42", stage, this_fftpts);
        this_stage_delay = calc_delay(this_stage_delay, num_stages - stage);
        delete [] twid_real;
        delete [] twid_imag;
    }
}

void FFT_NAME::func_compute_fft(double* real, double* imag)
{
    //number of stages in this transform (r22 stages, ie bfi and bfii = 1 stage)
    int num_stages = (int)ceil(log2_int(this_fftpts) / (double)log2_int(4));
    
    //determine if a radix 2 stage is needed at the last stage

    //if this is an inverse transform then we need to swap real and imag components
    if (this_inverse == 1) {
        inverse_data(real, imag);
    }

    //In the bi-directional core, the forward transform has delays decreasing through the stages,
    //but the reverse transform has delays increasing through the stages
    if ( representation == FLOATPT && svopt != 3) {
        bit_reverse_core = this_inverse;
    }

    int this_stage_delay = 0;
    if (bit_reverse_core) {
        this_stage_delay = 1;
    } else if (representation != FLOATPT || svopt == 3) {
        this_stage_delay = this_fftpts / 2;
    } else {
        this_stage_delay = this_fftpts / 4;
    }

    int this_dw = in_dw;

    //calc_all_cma_datawidths();

    // for each stage:
    if (bit_reverse_core && (representation == FIXEDPT || svopt == 3)) {
        // bit reverse core
#ifdef DEBUG_FFT
        cout << "fft: func_compute_fft:Computing bit reverse" << endl;
#endif
        for (int i = num_stages - 1; i >= 0; i--) {
#ifdef DEBUG_FFT
            cout << "fft: func_compute_fft:Computing bit reverse: stage " << i << endl;
#endif
            calc_stage( real,  imag,  this_dw, num_stages, this_stage_delay,  i + 1, cma_datawidths[max_num_stages - i - 1]);
        }
    } else {
        // natural order core
#ifdef DEBUG_FFT
        cout << "fft: func_compute_fft:Computing natural" << endl;
#endif
        for (int i = 0; i < num_stages; i++) {
#ifdef DEBUG_FFT
            cout << "fft: func_compute_fft:Computing nartural: stage " << i << endl;
#endif
            calc_stage( real,  imag,  this_dw, num_stages, this_stage_delay,  i, cma_datawidths[i]);
        }

    }

    //if this is an inverse transform then we need to swap real and imag components
    if (this_inverse == 1) {
        inverse_data(real, imag);
    }
}

const bool FFT_NAME::is_reverse_float_fft()
{
    return bit_reverse_core && (representation == FLOATPT && svopt != 3);
}

void FFT_NAME::SVSfftmodel(double* real_in, double* imag_in)
{
    // rearrange input samples to be in natural order and use natural order FFT.
    if (input_order == DC_CENTER_ORDER) {
        //copy the top half of the array to the bottom half of the copy variables
        double* real_cpy = new double[this_fftpts];//THN: Made temporary arrays the same size as the FFT size.  Previously this was equal to MAX_FFTPTS - which means memory allocated far exceeded the requirement
        double* imag_cpy = new double[this_fftpts];//THN: See above
        memcpy( real_cpy, real_in + this_fftpts / 2, (this_fftpts / 2)*sizeof(double) );
        memcpy( imag_cpy, imag_in + this_fftpts / 2, (this_fftpts / 2)*sizeof(double) );
        //copy the bottom half of the array to the top half of the copy variables
        memcpy( real_cpy + this_fftpts / 2, real_in, (this_fftpts / 2)*sizeof(double) );
        memcpy( imag_cpy + this_fftpts / 2, imag_in, (this_fftpts / 2)*sizeof(double) );
        memcpy( real_in, real_cpy, this_fftpts * sizeof(double) ); //THN: See above
        memcpy( imag_in, imag_cpy, this_fftpts * sizeof(double) ); //THN: See above
        delete [] real_cpy;
        delete [] imag_cpy;
    }

#ifdef DEBUG_FFT
    cout << "fft: SVSfftmodel: Computing FFT" << endl;
#endif
    func_compute_fft(real_in, imag_in);
    
    //if input order = NATURAL_ORDER then output of the FFT is bit reversed.
    //if input order = BIT_REVERSE then output of the FFT in natural order.
    //If the output order requires bit_reversing, do it here
    if ((output_order == NATURAL_ORDER && input_order == NATURAL_ORDER) ||
            (output_order == BIT_REVERSE && input_order == BIT_REVERSE) ||
            (output_order == NATURAL_ORDER && input_order == DC_CENTER_ORDER)
       ) {
        if (representation == FIXEDPT || svopt == 3) {
#ifdef DEBUG_FFT
            cout << "fft: SVSfftmodel: bit reversing the outputs" << endl;
#endif
            func_bit_reverse(real_in, imag_in, this_fftpts);
        } else {
#ifdef DEBUG_FFT
            cout << "fft: SVSfftmodel: index reversing the outputs" << endl;
#endif
            func_index_reverse(real_in, imag_in, this_fftpts);
        }
    }
}

#ifdef MEX_COMPILE
extern "C" {
    void mexFunction(int nlhs, mxArray* plhs[],
                     int nrhs, const mxArray* prhs[])
    {
        double* real_in;
        double* imag_in;
        double* real_out;
        double* imag_out;
        double* real_tmp = new double[MAX_FFTPTS];
        double* imag_tmp = new double[MAX_FFTPTS];

        int inverse = 0;
        int dw = 0;
        int twidw = 0;
        int nps = 0;
        int max_nps = 0;
        int output_order = 0;
        int input_order = 0;
        int representation = 0;
        int svopt = 0;
        double* prune;
        int mrows, ncols ;
        if (nrhs != 12) {
            mexErrMsgTxt("SVSfftmodel requires twelve input arguments.");
        } else if (nlhs < 2) {
            mexErrMsgTxt("SVSfftmodel requires two output argument.");
        }
        mrows = mxGetM(prhs[0]);
        ncols = mxGetN(prhs[0]);

        if (mrows != 1) {
            mexErrMsgTxt("Number of rows of the matrix must be 1");
        }

        plhs[0] = mxCreateDoubleMatrix(1, ncols, mxREAL);
        plhs[1] = mxCreateDoubleMatrix(1, ncols, mxREAL);

        //Inputs
        real_in = mxGetPr(prhs[0]);
        imag_in = mxGetPr(prhs[1]);
        dw = (int)mxGetScalar(prhs[2]);
        twidw = (int)mxGetScalar(prhs[3]);
        max_nps  = (int)mxGetScalar(prhs[4]);
        nps = (int)mxGetScalar(prhs[5]);
        inverse = (int)mxGetScalar(prhs[6]);
        input_order = (int)mxGetScalar(prhs[7]);
        output_order = (int)mxGetScalar(prhs[8]);
        representation = (int)mxGetScalar(prhs[9]);
        svopt = (int)mxGetScalar(prhs[10]);
        prune = mxGetPr(prhs[11]);

        //Outputs
        real_out = mxGetPr(plhs[0]);
        imag_out = mxGetPr(plhs[1]);

        int num_stages = (int)ceil(double(log2_int(max_nps) / log2_int(4)));
        //int out_dw = dw + (int)ceil(2.5*num_stages);
        int out_dw = dw + (int)ceil((log((double)max_nps) / log(2.0)) + 1);
        int fftpts_size = (int)ceil(double(log2_int(max_nps))) + 1;

        int rounding_type = RND_CONV;



        //declare an instance of the fft
        FFT_NAME this_fft(dw, out_dw, fftpts_size, twidw, rounding_type, output_order, input_order, representation, svopt, prune);

        this_fft.setThisFftpts(nps);
        this_fft.setThisInverse(inverse);

        memcpy( real_tmp, real_in, ncols * sizeof(double) );
        memcpy( imag_tmp, imag_in, ncols * sizeof(double) );

        this_fft.SVSfftmodel(real_tmp, imag_tmp);

        memcpy( real_out, real_tmp, ncols * sizeof(double) );
        memcpy( imag_out, imag_tmp, ncols * sizeof(double) );

        delete [] real_tmp;
        delete [] imag_tmp;

        return;
    }
}
#endif
