#include "stdio.h"
#include "math.h"
#include "stdlib.h"

#if MEX_COMPILE
#include "mex.h"
#endif

void Sfftmodel(double* fft_real_out,
               double* fft_imag_out,
               double* exponent_out,
               double* real_data_in,
               double* imag_data_in,
               double points,
               double throughput,
               double arch,
               double mpr,
               double twr,
               double direction
              )
{
    double dblmod(double, double);
    double log2(double);
    int local_round(double);
    int bfp(int, double[], double[], int, int);
    int bitrev(int, int);
    int findscale(int, int, int, int, int);
    const double pi = 3.14159265358979;

    int k, m, rk = 0;
    int N = (int)points;
    int pass = 1;

    double Gr1, Gr2, Gr3, Gr4 = 0;
    double Gi1, Gi2, Gi3, Gi4 = 0;
    double Gr_t1, Gr_t2, Gr_t3, Gr_t4 = 0;
    double Gi_t1, Gi_t2, Gi_t3, Gi_t4 = 0;
    /* Output temporary arrays */
    double* xreal = {'\0'};
    double* ximag = {'\0'};
    double* xrealt = {'\0'};
    double* ximagt = {'\0'};
    double temp = 0.0;

    int step = N / 4;
    int jjj = 0;
    int exp_temp = 0;
    double c0 = 1;
    double c1 = 1;
    double c2 = 1;
    double c3 = 1;
    double s0 = 0;
    double s1 = 0;
    double s2 = 0;
    double s3 = 0;
    int sc = 1;
    int bfp_factor_i = 1;
    /* Output Block scaling for continuos (streaming 512/1024) */
    int sco = 1;
    int power_of_n4 = 1;
    double power_of_4 = (log2((double)N) / log2(4.0));
    int n_by_4 = (int)N / 4;
    int mixed = 0;
    int npasses = 1;
    int twiddle_addr = 0;
    double tempr = 0;
    double tempi = 0;
    double At = pow(2.0, (double)twr - 1.0) - 1.0;
    int Am = (int) pow(2, mpr - 1) - 1;
    double A = pow(2.0, (double)twr);

    int cont = 0;
    /* BFP for Streaming 512/1024 requires adjusted algorithm */
    if (throughput == 4.0 && arch == 0.0 && (N == 512 || N == 1024)) {
        cont = 1;
    } else {
        cont = 0;
    }
    /* Set number of passes and detect radix of last pass */
    if ((power_of_4 - floor(power_of_4)) == 0.0) {
        power_of_n4 = (int)ceil(log2((double)N) / log2(4.0));
        mixed = 0;
        npasses = power_of_n4;

    } else {
        mixed = 1;
        power_of_n4 = (int)floor(log2((double)N) / log2(4.0));
        npasses = power_of_n4;
    }

    xrealt = malloc(sizeof(double) * N);
    ximagt = malloc(sizeof(double) * N);
    xreal  = malloc(sizeof(double) * N);
    ximag  = malloc(sizeof(double) * N);
    N = (int)points;

    /* Initialize array */
    for (k = 0; k < N; k++) {
        if (direction == 0.0) {
            xreal[k] = local_round(real_data_in[k] / 1.0);
            ximag[k] = local_round(imag_data_in[k] / 1.0);
        } else {
            ximag[k] = local_round(real_data_in[k] / 1.0);
            xreal[k] = local_round(imag_data_in[k] / 1.0);
        }
    }
    if (throughput == 4.0) {
        if (mixed == 0) {
            exp_temp = -3 * (npasses - 1) - 2;
        } else {
            exp_temp = -3 * (npasses) - 1;
        }
    } else {
        if (mixed == 0) {
            exp_temp = -3 * (npasses) ;
        } else {
            exp_temp = -3 * (npasses + 1) + 1;
        }
    }
    /* printf("npasses = %d exp_init = %d\n",npasses,exp_temp); */

    for (pass = 1; pass <= npasses; pass++) {
        m = (int)floor(pow(4.0, (double)(pass - 1)));
        if (mixed == 0 && pass == npasses && throughput == 4.0) {
            sc = 1;
        } else {
            sc = bfp_factor_i;
        }
        exp_temp = exp_temp + (int)log2(sc);
        for (k = 0; k < N / 4; k++) {
            /***********************************************************************************
            / For continuous (streaming 512,1024) case, don't scale first 16 points
            /**********************************************************************************/
            if (throughput == 4.0 && mixed == 0 && pass == npasses) {
                sc = 1;
            } else {
                sc = bfp_factor_i;
                if (cont == 1) {
                    sc = findscale(N, pass, k, bfp_factor_i, 1);
                } else {
                    sc = sc;
                }
            }
            /***********************************************************************************
            / Radix-4 Butterfly
            /**********************************************************************************/
            Gr1 = local_round(((double)sc * (xreal[k] + xreal[k + n_by_4] + xreal[k + 2 * n_by_4] + xreal[k + 3 * n_by_4]))  / 4.0);
            Gi1 = local_round(((double)sc * (ximag[k] + ximag[k + n_by_4] + ximag[k + 2 * n_by_4] + ximag[k + 3 * n_by_4]))  / 4.0);
            Gr2 = local_round(((double)sc * (xreal[k] + ximag[k + n_by_4] - xreal[k + 2 * n_by_4] - ximag[k + 3 * n_by_4]))  / 4.0);
            Gi2 = local_round(((double)sc * (ximag[k] - xreal[k + n_by_4] - ximag[k + 2 * n_by_4] + xreal[k + 3 * n_by_4]))  / 4.0);
            Gr3 = local_round(((double)sc * (xreal[k] - xreal[k + n_by_4] + xreal[k + 2 * n_by_4] - xreal[k + 3 * n_by_4]))  / 4.0);
            Gi3 = local_round(((double)sc * (ximag[k] - ximag[k + n_by_4] + ximag[k + 2 * n_by_4] - ximag[k + 3 * n_by_4]))  / 4.0);
            Gr4 = local_round(((double)sc * (xreal[k] - ximag[k + n_by_4] - xreal[k + 2 * n_by_4] + ximag[k + 3 * n_by_4]))  / 4.0);
            Gi4 = local_round(((double)sc * (ximag[k] + xreal[k + n_by_4] - ximag[k + 2 * n_by_4] - xreal[k + 3 * n_by_4]))  / 4.0);

            twiddle_addr = (int)m * (int)floor(k / m);

            s0 = local_round(At * sin( 0 * 6.283185307179586476925286766559 / N));
            c0 = local_round(At * cos( 0 * 6.283185307179586476925286766559 / N));
            s1 = local_round(At * sin(1 * twiddle_addr * 6.283185307179586476925286766559 / N));
            c1 = local_round(At * cos(1 * twiddle_addr * 6.283185307179586476925286766559 / N));
            s2 = local_round(At * sin(2 * twiddle_addr * 6.283185307179586476925286766559 / N));
            c2 = local_round(At * cos(2 * twiddle_addr * 6.283185307179586476925286766559 / N));
            s3 = local_round(At * sin(3 * twiddle_addr * 6.283185307179586476925286766559 / N));
            c3 = local_round(At * cos(3 * twiddle_addr * 6.283185307179586476925286766559 / N));

            if (mixed == 0 && pass == npasses && throughput == 4.0) {
                Gr_t1 = Gr1;
                Gi_t1 = Gi1;
                Gr_t2 = Gr2;
                Gi_t2 = Gi2;
                Gr_t3 = Gr3;
                Gi_t3 = Gi3;
                Gr_t4 = Gr4;
                Gi_t4 = Gi4;
            } else {
                if (throughput == 1.0) {
                    Gr_t1 = local_round((Gr1 * c0 + Gi1 * s0) / A);
                    Gi_t1 = local_round((Gi1 * c0 - Gr1 * s0) / A);
                } else {
                    Gr_t1 = local_round((double)Gr1 / 2.0);
                    Gi_t1 = local_round((double)Gi1 / 2.0);
                }
                Gr_t2 = local_round((double)(Gr2 * c1 + Gi2 * s1) / (double)A);
                Gi_t2 = local_round((double)(Gi2 * c1 - Gr2 * s1) / (double)A);
                Gr_t3 = local_round((double)(Gr3 * c2 + Gi3 * s2) / (double)A);
                Gi_t3 = local_round((double)(Gi3 * c2 - Gr3 * s2) / (double)A);
                Gr_t4 = local_round((double)(Gr4 * c3 + Gi4 * s3) / (double)A);
                Gi_t4 = local_round((double)(Gi4 * c3 - Gr4 * s3) / (double)A);
            }
            /***********************************************************************************
            / For continuous (streaming 512,1024) case, first 16 outputs need to be scaled to
            / account for missed input scaling
            /**********************************************************************************/
            if (throughput == 4.0 && mixed == 0 && pass == npasses) {
                sco = 1;
            } else {
                if (cont == 1) {
                    sco = findscale(N, pass, k, bfp_factor_i, 0);
                } else {
                    sco = 1;
                }
            }
            xrealt[jjj] =    (double)sco * Gr_t1;
            ximagt[jjj] =    (double)sco * Gi_t1;
            xrealt[jjj + 1] =  (double)sco * Gr_t2;
            ximagt[jjj + 1] =  (double)sco * Gi_t2;
            xrealt[jjj + 2] =  (double)sco * Gr_t3;
            ximagt[jjj + 2] =  (double)sco * Gi_t3;
            xrealt[jjj + 3] =  (double)sco * Gr_t4;
            ximagt[jjj + 3] =  (double)sco * Gi_t4;
            jjj = jjj + 4;
        }
        bfp_factor_i = bfp((int)N, xrealt, ximagt, (int)mpr, 4);
        for (k = 0; k < N ; k++) {
            xreal[k] = xrealt[k];
            ximag[k] = ximagt[k];
        }
        jjj = 0;
    }

    if (throughput == 1.0) {
        sc = bfp_factor_i;
        if (mixed == 1.0) {
            exp_temp = exp_temp + (int)log2(sc);
        }
        /* exp_temp = exp_temp + (int)log2((double)bfp_factor_i); */
    } else {
        sc = 1;
    }

    if (mixed == 1) {
        if (throughput == 4.0) {
            for (k = 0; k < N / 2 ; k++) {
                tempr = local_round((xreal[k] + xreal[k + (N / 2)]) / 2);
                tempi = local_round((ximag[k] + ximag[k + (N / 2)]) / 2);
                xreal[k + N / 2] = local_round((xreal[k] - xreal[k + (N / 2)]) / 2);
                ximag[k + N / 2] = local_round((ximag[k] - ximag[k + (N / 2)]) / 2);
                xreal[k] = tempr;
                ximag[k] = tempi;
            }
        } else {
            for (k = 0; k < N / 2 ; k++) {
                tempr = local_round((sc * 2 * (xreal[k] + xreal[k + (N / 2)])) / 4);
                tempi = local_round((sc * 2 * (ximag[k] + ximag[k + (N / 2)])) / 4);
                tempr = local_round((tempr * c0 + tempi * s0) / A);
                tempi = local_round((tempi * c0 - tempr * s0) / A);
                xreal[k + N / 2] = local_round((sc * 2 * (xreal[k] - xreal[k + (N / 2)])) / 4);
                ximag[k + N / 2] = local_round((sc * 2 * (ximag[k] - ximag[k + (N / 2)])) / 4);
                xreal[k + N / 2] = local_round((xreal[k + N / 2] * c0 + ximag[k + N / 2] * s0) / A);
                ximag[k + N / 2] = local_round((ximag[k + N / 2] * c0 - xreal[k + N / 2] * s0) / A);
                xreal[k] = tempr;
                ximag[k] = tempi;
            }

        }
    }

    for (k = 0; k < N ; k++) {
        /* rk = bitrev(k); */
        if (direction == 0.0) {
            fft_real_out[bitrev(k, N)] = xreal[k];
            fft_imag_out[bitrev(k, N)] = ximag[k];
        } else {
            fft_imag_out[bitrev(k, N)] = xreal[k];
            fft_real_out[bitrev(k, N)] = ximag[k];
        }
        exponent_out[k] = exp_temp;
        /* printf("index=%d fft_real_out[%d]=%f fft_imag_out[%d]=%f\n",  k,bitrev(k),fft_real_out[bitrev(k)],bitrev(k),fft_imag_out[bitrev(k)]); */
    }
    free(xrealt) ;
    free(ximagt) ;
    free(xreal)  ;
    free(ximag)  ;

}

/*********************************************************************************************
/ Method : dblmod
/ Compute a%b where a and b are integral but double values
/********************************************************************************************/
double dblmod(double a, double b)
{
    int divided_by;
    double b_tmp = 0.0;
    divided_by = 1;
    b_tmp = 0.0;
    if (b == 0.0 || a == 0) {
        b_tmp = a;
    } else if (a < b) {
        b_tmp = a;
    } else if (a == b) {
        b_tmp = 0.0;
    } else {
        while (a >= b) {
            a = a - b;
        }
        b_tmp = a;
    }
    return b_tmp;
}

double log2(double N)
{
    double a = log(N) / log(2.0);
    return (double)local_round(a);
}

/******************************************************************************************************
/ Symmetrical Local_Rounding
/*****************************************************************************************************/
int local_round(double a)
{
    if (a > 0.0) {
        return (int)floor(a + 0.5);
    } else {
        return (int)ceil(a - 0.5);
    }
}

/******************************************************************************************************
/ Block Floating Point Processor
/*****************************************************************************************************/
int bfp(int N, double xrealt[], double ximagt[], int mpr, int fpr)
{
    int bfp_factor = 1;
    int floatmul = 1;
    int j, k = 0;
    int neg = 0;
    int pos = 0;

    int bfpvec[5] = {0, 0, 0, 0, 0};
    for (k = 0; k < N; k++) {
        for (j = 0; j < fpr; j++) {
            pos = (int) pow(2, (mpr - j - 2));
            neg = -1 * (pos + 1);
            if ((xrealt[k] >= pos) | (xrealt[k] <= neg)) {
                bfpvec[j] = 1;
            }
            if ((ximagt[k] >= pos) | (ximagt[k] <= neg)) {
                bfpvec[j] = 1;
            }
        }
    }
    for (j = 0; j < fpr; j++) {
        if (bfpvec[j] == 0) {
            floatmul = floatmul * 2;
        }
    }
    bfp_factor = floatmul;
    /* fprintf(stdout,"bfp_factor=%d\n",bfp_factor); */
    return bfp_factor;
}


/************************************************************************************************
/ Special 1024/512 STreaming scaling factor
/ Detect if scaling can occur before or after processing
/***********************************************************************************************/
int findscale(int N, int pass, int k, int bfp_factor_i, int io)
{
    int sc = 1;
    if (N == 1024 || N == 512) {
        if (pass == 1) {
            sc = 1;
        } else if (pass == 2) {
            if (N == 1024) {
                if ((k % 64) < 4 && k < 195) {
                    if (io == 1) {
                        sc = 1;
                    } else {
                        sc = bfp_factor_i;
                    }
                } else {
                    if (io == 1) {
                        sc = bfp_factor_i;
                    } else {
                        sc = 1;
                    }
                }
            } else {
                if ((k % 32) < 4 && k < 99) {
                    if (io == 1) {
                        sc = 1;
                    } else {
                        sc = bfp_factor_i;
                    }
                } else {
                    if (io == 1) {
                        sc = bfp_factor_i;
                    } else {
                        sc = 1;
                    }
                }
            }
        } else if (pass == 3) {
            if (k < 15) {
                if (io == 1) {
                    sc = 1;
                } else {
                    sc = bfp_factor_i;
                }
            } else {
                if (io == 1) {
                    sc = bfp_factor_i;
                } else {
                    sc = 1;
                }
            }
        } else {
            if ((k % 4) == 0 && k < 60) {
                if (io == 1) {
                    sc = 1;
                } else {
                    sc = bfp_factor_i;
                }
            } else {
                if (io == 1) {
                    sc = bfp_factor_i;
                } else {
                    sc = 1;
                }
            }
        }
    }
    return sc;
}

/*************************************************************************************************
/ Output Address Bit-Reversal
/************************************************************************************************/
int bitrev(int i, int N)
{

    int revaddr = 0;
    if (N == 64) {
        revaddr = (int)(16 * (i % 4) + 4 * floor((i % 16) / 4) + floor((i % 64) / 16));
    } else if (N == 128) {
        revaddr = (int)(16 * (i % 4) + 4 * floor((i % 16) / 4) + floor((i % 64) / 16) +  64 * floor(i / 64));
    } else if (N == 256) {
        revaddr = (int)(64 * (i % 4) + 16 * floor((i % 16) / 4) + 4 * floor((i % 64) / 16) +  floor(i / 64));
    } else if (N == 512) {
        revaddr = (int)(64 * (i % 4) + 16 * floor((i % 16) / 4) + 4 * floor((i % 64) / 16)  + floor((i % 256) / 64) + 256 * floor(i / 256));
    } else if (N == 1024) {
        revaddr = (int)(256 * (i % 4) + 64 * floor((i % 16) / 4) + 16 * floor((i % 64) / 16) + 4 * floor((i % 256) / 64) + floor(i / 256));
    } else if (N == 2048) {
        revaddr = (int)(256 * (i % 4) + 64 * floor((i % 16) / 4) + 16 * floor((i % 64) / 16) +  4 * floor((i % 256) / 64) + floor((i % 1024) / 256) + 1024 * floor(i / 1024));
    } else if (N == 4096) {
        revaddr = (int)(1024 * (i % 4) + 256 * floor((i % 16) / 4) + 64 * floor((i % 64) / 16) + 16 * floor((i % 256) / 64) + 4 * floor((i % 1024) / 256) + floor(i / 1024));
    } else if (N == 8192) {
        revaddr = (int)(1024 * (i % 4) + 256 * floor((i % 16) / 4) + 64 * floor((i % 64) / 16) +  16 * floor((i % 256) / 64) + 4 * floor((i % 1024) / 256) + floor((i % 4096) / 1024) + 4096 * floor(i / 4096));
    } else if (N == 16384) {
        revaddr = (int)(4096 * (i % 4) + 1024 * floor((i % 16) / 4) + 256 * floor((i % 64) / 16) + 64 * floor((i % 256) / 64) + 16 * floor((i % 1024) / 256) + 4 * floor((i % 4096) / 1024) + floor(i / 4096));
    } else if (N == 32768) {
        revaddr = (int)(4096 * (i % 4) + 1024 * floor((i % 16) / 4) + 256 * floor((i % 64) / 16) + 64 * floor((i % 256) / 64) + 16 * floor((i % 1024) / 256) + 4 * floor((i % 4096) / 1024) + floor((i % 16384) / 4096) + 16384 * floor(i / 16384));
    } else if (N == 65536) {
        revaddr = (int)(16384 * (i % 4) + 4096 * floor((i % 16) / 4) + 1024 * floor((i % 64) / 16) + 256 * floor((i % 256) / 64) + 64 * floor((i % 1024) / 256) + 16 * floor((i % 4096) / 1024) + 4 * floor((i % 16384) / 4096) + floor(i / 16384));
    } else if (N == 131072) {
        revaddr = (int)(16384 * (i % 4) + 4096 * floor((i % 16) / 4) + 1024 * floor((i % 64) / 16) + 256 * floor((i % 256) / 64) + 64 * floor((i % 1024) / 256) + 16 * floor((i % 4096) / 1024) + 4 * floor((i % 16384) / 4096) + floor((i % 65536) / 16384) + 65536 * floor(i / 65536));
    }
    
    return revaddr;
}

#if MEX_COMPILE

void mexFunction(int nlhs, mxArray* plhs[],
                 int nrhs, const mxArray* prhs[])
{
    double* real_data_in = {'\0'};
    double* imag_data_in = {'\0'};
    double* fft_real_out = {'\0'};
    double* fft_imag_out = {'\0'};
    double* exponent_out = {'\0'};
    double direction = 0.0;
    double mpr = 0.0;
    double twr = 0.0;
    double points = 0.0;
    double arch = 0.0;
    double throughput = 0.0;
    double N = 0;
    int mrows, ncols ;

    mrows = mxGetM(prhs[0]);
    ncols = mxGetN(prhs[0]);

    plhs[0] = mxCreateDoubleMatrix(mrows, ncols, mxREAL);
    plhs[1] = mxCreateDoubleMatrix(mrows, ncols, mxREAL);
    plhs[2] = mxCreateDoubleMatrix(mrows, ncols, mxREAL);

    /* Inputs */
    real_data_in = mxGetPr(prhs[0]);
    imag_data_in = mxGetPr(prhs[1]);
    points  = mxGetScalar(prhs[2]);
    throughput  = mxGetScalar(prhs[3]);
    arch = mxGetScalar(prhs[4]);
    mpr = mxGetScalar(prhs[5]);
    twr = mxGetScalar(prhs[6]);
    direction = mxGetScalar(prhs[7]);
    /* Outputs */
    fft_real_out = mxGetPr(plhs[0]);
    fft_imag_out = mxGetPr(plhs[1]);
    exponent_out = mxGetPr(plhs[2]);


    Sfftmodel(fft_real_out,
              fft_imag_out,
              exponent_out,
              real_data_in,
              imag_data_in,
              points,
              throughput,
              arch,
              mpr,
              twr,
              direction
             );

}

#endif
