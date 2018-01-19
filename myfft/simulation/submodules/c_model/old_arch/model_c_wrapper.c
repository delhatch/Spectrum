//******************************************************
// This file is used for C wrapper testbench
// Code writter: thnguyen
//******************************************************
#include "stdio.h"
#include "math.h"
#include "stdlib.h"
#include "string.h"

int main(int argc, char** argv)
{
//-----------------------------------------------
// Initialize variables
//-------------------------------------------------
    FILE* fidro;    // File handle for  Real Output
    FILE* fidio;    //                  Imag Output
    FILE* fideo;    //                  Exponent Output
    FILE* fidr;     //                  Real Input
    FILE* fidi;     //                  Imag Input

    double* real_data_in = {'\0'};      // These values are either read from the input files, or written
    double* imag_data_in = {'\0'};      // to output files
    double* fft_real_out = {'\0'};
    double* fft_imag_out = {'\0'};
    double* exponent_out = {'\0'};
    int* dr_in = {'\0'};                // These values are used to read the data from input in int format and then will be convert to double format
    int* di_in = {'\0'};

    // These values will be assigned to from argv
    double data_prec = 16.0;
    double twiddle_prec = 16.0;
    double N = 2048.0;
    double arch = 0.0;
    double throughput = 4.0;
    double direction = 0.0;
    int i;

    // These variables store the directory and filenames of the i/o
    char* variation_name;
    char* directory;
    char* real_input_file;
    char* imag_input_file;

    char* real_output_file;
    char* imag_output_file;
    char* exponent_output_file;

    //N block
    int size_of_file = 0;
    int number_of_block = 0;
    int* ch1 = {'\0'};          // this is used to catch the enter

//-----------------------------------------------
// Function prototype for Sfftmodel (Bit accurate Model for Streaming, Buffered Burst, Burst architectures)
//-------------------------------------------------
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


    /***************************************************************************
     * Parse the argument into parameter
     **************************************************************************/

    printf ("\n Parse the argv to parameter");

    //parse the arg into the parameter
    // N = nps : FFT Transform Length
    N = atof((char*)argv[1]);

    // data_prec = mpr : Input Data Precision
    data_prec = atof((char*)argv[2]);

    // twiddle_prec =twr : Twiddle Factor Precision
    twiddle_prec = atof((char*)argv[3]);

    // direction : FFT Transform direction
    // 0.0 : FFT
    // 1.0 : Inverse FFT
    direction = 0.0; // ??? where it comes from

    // arch : FFT Architecture
    // 0.0 : Streaming Architecture
    // 1.0 : Buffered Burst Architecture
    // 2.0 : Burst Architecture
    arch = atof((char*)argv[4]);
    // throughput = $THRU : FFT Engine Throughput
    // 1.0 Single Output
    // 4.0 Quad Output
    throughput = atof((char*)argv[5]);

    variation_name = (char*)malloc(sizeof(char) * strlen(argv[6]));
    variation_name = argv[6];
    directory = (char*)malloc(sizeof(char) * strlen(argv[7]));
    directory = argv[7];

    real_data_in = malloc(sizeof(double) * (int)N);
    imag_data_in = malloc(sizeof(double) * (int)N);
    fft_real_out = malloc(sizeof(double) * (int)N);
    fft_imag_out = malloc(sizeof(double) * (int)N);
    exponent_out = malloc(sizeof(double) * (int)N);
    dr_in = malloc(sizeof(int) * (int)N);
    di_in = malloc(sizeof(int) * (int)N);

    //Create strings (char arrays) with exactly the right number of elements
    //Number of elements = length of file name + length of directory + Forward slash (1)
    real_input_file = (char*)malloc(sizeof(char) * (strlen(variation_name) + strlen("_real_input.txt") + strlen(directory) + 2));
    imag_input_file = (char*)malloc(sizeof(char) * (strlen(variation_name) + strlen("_imag_input.txt") + strlen(directory) + 2));
    real_output_file = (char*)malloc(sizeof(char) * (strlen(variation_name) + strlen("_real_output_c_model.txt") + strlen(directory) + 2));
    imag_output_file = (char*)malloc(sizeof(char) * (strlen(variation_name) + strlen("_imag_output_c_model.txt") + strlen(directory) + 2));
    exponent_output_file = (char*)malloc(sizeof(char) * (strlen(variation_name) + strlen("_exponent_output_c_model.txt") + strlen(directory) + 2));

    strcpy(real_input_file, directory);
    strcat(real_input_file, "/");
    strcat(real_input_file, variation_name);
    strcat(real_input_file, "_real_input.txt");
    strcpy(imag_input_file, directory);
    strcat(imag_input_file, "/");
    strcat(imag_input_file, variation_name);
    strcat(imag_input_file, "_imag_input.txt");

    strcpy(real_output_file, directory);
    strcat(real_output_file, "/");
    strcat(real_output_file, variation_name);
    strcat(real_output_file, "_real_output_c_model.txt");
    strcpy(imag_output_file, directory);
    strcat(imag_output_file, "/");
    strcat(imag_output_file, variation_name);
    strcat(imag_output_file, "_imag_output_c_model.txt");
    strcpy(exponent_output_file, directory);
    strcat(exponent_output_file, "/");
    strcat(exponent_output_file, variation_name);
    strcat(exponent_output_file, "_exponent_output_c_model.txt");

    printf ("\n N = %lf ", N);
    printf ("\n data_prec = %lf", data_prec);
    printf ("\n twiddle_prec = %lf ", twiddle_prec);
    printf ("\n direction = %lf ", direction);
    printf ("\n arch = %lf ", arch);
    printf ("\n throughput = %lf ", throughput);
    printf ("\n directory = %s", directory);
    printf ("\n real_input_file = %s", real_input_file);
    printf ("\n imag_input_file = %s", imag_input_file);
    printf ("\n real_output_file = %s", real_output_file);
    printf ("\n imag_output_file = %s", imag_output_file);
    printf ("\n exponent_output_file = %s", exponent_output_file);

    //***************************************************************************
    // Test the architecture of FFT
    // arch : FFT Architecture
    // 0.0 : Streaming Architecture
    // 1.0 : Buffered Burst Architecture
    // 2.0 : Burst Architecture
    //3.0 : Streaming Variable
    //***************************************************************************

    if (arch != 3.0) {
        int j;
        printf ("\n This is the testbench generated for old architecture");

        /***************************************************************************
         * Create input arrays to model
         **************************************************************************/
        //fidr = fopen(real_input_file,"rt");
        //----------------
        size_of_file = 4 * (int)N; // For the old architecture, the generated input data is always 4N
        /*if(fidr==NULL)
            printf("\n error when open file");
        else
        {
            size_of_file=-1;
            do
            {
                printf("%d\n",size_of_file);
                //size_of_file ++;
                //fread(&ch1,sizeof(double),1,fidr);
                fscanf(fidr,"%d",&ch1);
                if (ch1=='\n');
                {
                    size_of_file++;
                }
            }
            while(!feof(fidr));

        }
        fclose(fidr);*/
        printf("\n INFO: size of file = %d", size_of_file);
        //---------------------count the size of file
        fidi = fopen(imag_input_file, "rt");
        fidr = fopen(real_input_file, "rt");
        fidro = fopen(real_output_file, "wt");
        fidio = fopen(imag_output_file, "wt");
        fideo = fopen(exponent_output_file, "wt");
        if (fidr < 0 || fidi < 0) {
            printf("can't open input files\n");
        }
        number_of_block = size_of_file / (int)N;
        printf("\n INFO number of block = %d\n", number_of_block);
        for (j = 0; j < number_of_block; j++) {
            //start for 1 block
            for (i = 0; i < N; i++) {
                fscanf(fidr, "%d", &dr_in[i]);
                real_data_in[i] = (double)dr_in[i]; //[thn] convert the file format
                //real_data_in[i] = 0;
                fscanf(fidi, "%d", &di_in[i]);
                //imag_data_in[i] = 0;
                imag_data_in[i] = (double)di_in[i];
            }


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
             * Write Results to File
             *******************************************************************************/
            for (i = 0; i < (int)N; i++) {
                fprintf(fidro, "%.0f\n", fft_real_out[i]);
                fprintf(fidio, "%.0f\n", fft_imag_out[i]);
                fprintf(fideo, "%.0f\n", exponent_out[i]);
            }
            // end for 1block
        }
        fclose(fidro);
        fclose(fidio);
        fclose(fideo);
        fclose(fidr);
        fclose(fidi);
    } else {
        printf ("\n This is the testbench generated for new architecture");
    }
    return 0;
}

//numch_t = atof((char*)argv[1]);
