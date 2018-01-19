/*******************************************************************************
Function:
	An IP used ton control a seg7 array.
	

Parameters:
	s_address: index used to specfied seg7 unit, 0 means first seg7 unit
	s_writedata: 8 bits map to seg7 as beblow (1:on, 0:off)

      0
	------
	|    |
   5| 6  |1
	------
	|    |
   4|    |2
	------  . 7
      3
      
Map Array:
    unsigned char szMap[] = {
        63, 6, 91, 79, 102, 109, 125, 7, 
        127, 111, 119, 124, 57, 94, 121, 113
    };  // 0,1,2,....9, a, b, c, d, e, f      

Customization:
	SEG7_NUM: 
		specify the number of seg7 unit
		
	ADDR_WIDTH: 
		log2(SEG7_NUM)
		
	DEFAULT_ACTIVE: 
		1-> defualt to turn on all of segments, 
		0: turn off all of segements
		
	LOW_ACTIVE: 
		1->segment is low active, 
		0->segment is high active


******************************************************************************/


module SEG7_IF(	
					//===== avalon MM s1 slave (read/write)
					// write
					s_clk,
					s_address,
					s_read,
					s_readdata,
					s_write,
					s_writedata,
					s_reset,
					//

					//===== avalon MM s1 to export (read)
					// read/write
					SEG7
				 );
				
/*****************************************************************************
 *                           Parameter Declarations                          *
 *****************************************************************************/
parameter	SEG7_NUM		=   8;
parameter	ADDR_WIDTH		=	3;		
parameter	DEFAULT_ACTIVE  =   1;
parameter	LOW_ACTIVE  	=   1;

//`define 	SEG7_NUM		   8
//`define		ADDR_WIDTH		   3		
//`define		DEFAULT_ACTIVE     1
//`define		LOW_ACTIVE  	   1




/*****************************************************************************
 *                             Internal Wire/Register                         *
 *****************************************************************************/

reg		[7:0]				base_index;
reg		[7:0]				write_data;
reg		[7:0]				read_data;
reg		[(SEG7_NUM*8-1):0]  reg_file;



/*****************************************************************************
 *                             Port Declarations                             *
 *****************************************************************************/
 // s1
input						s_clk;
input	[(ADDR_WIDTH-1):0]	s_address;
input						s_read;
output	[7:0]				s_readdata;
input						s_write;
input	[7:0]				s_writedata;
input						s_reset;


//===== Interface to export
 // s1
output	[(SEG7_NUM*8-1):0]  SEG7;




/*****************************************************************************
 *                            Sequence logic                                  *
 *****************************************************************************/
 
always @ (negedge s_clk)
begin
	
	if (s_reset)
	begin
		integer i;
		for(i=0;i<SEG7_NUM*8;i=i+1)
		begin
			reg_file[i] = (DEFAULT_ACTIVE)?1'b1:1'b0; // trun on or off 
		end
	end
	else if (s_write)
	begin
		integer j;
		write_data = s_writedata;
		base_index = s_address;
		base_index = base_index << 3;
		for(j=0;j<8;j=j+1)
		begin
			reg_file[base_index+j] = write_data[j];
		end
	end
	else if (s_read)
	begin
		integer k;
		base_index = s_address;
		base_index = base_index << 3;
		for(k=0;k<8;k=k+1)
		begin
			read_data[k] = reg_file[base_index+k];
		end
	end	
end
 


/*****************************************************************************
 *                            Combinational logic                            *
 *****************************************************************************/
assign SEG7 = (LOW_ACTIVE)?~reg_file:reg_file;
assign s_readdata = read_data;


endmodule

