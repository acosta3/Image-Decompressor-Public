
`timescale 1ns/100ps
`ifndef DISABLE_DEFAULT_NET
`default_nettype none
`endif

`include "define_state.h"


// It connects the UART, SRAM and VGA together.
// It gives access to the SRAM for UART and VGA
module M2 (
    input logic Clock_50,
	 input logic Resetn,
	 input logic [15:0]SRAM_read_data,
	 input logic M2_start,
	 
	 output logic SRAM_we_n,
    output logic M2_done,
	 output logic  [15:0] SRAM_write_data,
	 output logic [17:0] SRAM_address

);


M2_state_type M2_state;



logic signed [32:0] T_0,T_1,T_2,T_3,T_2_BUF, T_3_BUF;
logic signed [32:0] S_0,S_1,S_2,S_3,S_2_BUF, S_3_BUF;
logic first_pass;
logic stop_write_S_SRAM,final_write_S_flag;

//multipliers 

//multiplier params
logic signed[31:0] Mult_M2_op_0_1, Mult_M2_op_0_2, Mult_M2_result_0;
logic signed[63:0] Mult_M2_result_long_0;
logic signed[31:0] Mult_M2_op_1_1, Mult_M2_op_1_2, Mult_M2_result_1;
logic signed[63:0] Mult_M2_result_long_1;
logic signed[31:0] Mult_M2_op_2_1, Mult_M2_op_2_2, Mult_M2_result_2;
logic signed[63:0] Mult_M2_result_long_2;
logic signed[31:0] Mult_M2_op_3_1, Mult_M2_op_3_2, Mult_M2_result_3;
logic signed[63:0] Mult_M2_result_long_3;

///memory addressing for DPRAM 32 bit write and 7 bit addressing

logic unsigned [6:0] address_s_prime_0, address_s_prime_1, address_T_0, address_T_1, address_S_0, address_S_1;
logic unsigned [31:0] write_s_prime_0, write_s_prime_1, write_T_0, write_T_1,write_S_0,write_S_1;
logic unsigned WE_s_prime_0,WE_s_prime_1,WE_T_0,WE_T_1,WE_S_0,WE_S_1;
logic [31:0] read_data_s_prime_0,read_data_s_prime_1,read_data_T_0,read_data_T_1,read_data_S_0,read_data_S_1;
			 
//test
			 
// counters
// sample counter = 6 bit signal
// row_index,col_index = 3 bits signals 
logic [5:0] Sample_counter,Write_Sample_counter;
logic [2:0] row_index;
logic [2:0] col_index;
logic [6:0] column_block;
logic [5:0] row_block;

logic[5:0] DPRAM_S_READ_COUNTER;

///// Anthony////
////Added Post Idct Variables////////

logic [2:0] row_index_POST_IDCT; /// Count up to 0-7
logic [1:0] col_index_POST_IDCT; // counts up to 0-3
logic [6:0] column_block_POST_IDCT;
logic [5:0] row_block_POST_IDCT,write_column_block,write_row_block;



logic [11:0] blocks_read, blocks_written;

logic stop_fs_prime,last_write_s_prime;


/// consider the base address offsets
// read address offset = Y = 0, U = 153600, V = 192160
// write address offset = Y = 0, U = 38400 , V = 57600
parameter Y_base_address = 18'd76800,
				Y_write_offset=18'd0,
				U_write_offset=18'd38400,
				V_write_offset=18'd57600,
				Y_read_offset = 18'd76800,
				U_read_offset = 18'd153600,
				V_read_offset = 18'd192000;




// coefficient matrix wires

logic[5:0] c_index_0,c_index_1,c_index_2,c_index_3;
logic[3:0] mux_counter;
// C matrix counters
logic signed [31:0] C0,C1,C2,C3;
logic [7:0] C_multiplier_row, C_multiplier_column;


logic flag_increment_row;
logic flag_increment_column;
logic FS_CC_transition;
// RAM 0 = RAM S'
dual_port_RAM_0 RAM_inst0 (
	.address_a ( address_s_prime_0 ),
	.address_b ( address_s_prime_1 ),
	.clock ( Clock_50 ),
	.data_a ( write_s_prime_0 ),
	.data_b ( write_s_prime_1 ),
	.wren_a ( WE_s_prime_0 ),
	.wren_b ( WE_s_prime_1 ),
	.q_a ( read_data_s_prime_0 ),
	.q_b ( read_data_s_prime_1 )
   );
// RAM 1 = RAM T
dual_port_RAM_1 RAM_inst1 (
	.address_a ( address_T_0 ),
	.address_b ( address_T_1 ),
	.clock ( Clock_50 ),
	.data_a ( write_T_0 ),
	.data_b ( write_T_1 ),
	.wren_a ( WE_T_0 ),
	.wren_b ( WE_T_1 ),
	.q_a ( read_data_T_0 ),
	.q_b ( read_data_T_1 )
	);
	
// RAM 1 = RAM S
dual_port_RAM_2 RAM_inst2 (
	.address_a ( address_S_0 ),
	.address_b ( address_S_1 ),
	.clock ( Clock_50 ),
	.data_a ( write_S_0 ),
	.data_b ( write_S_1 ),
	.wren_a ( WE_S_0 ),
	.wren_b ( WE_S_1 ),
	.q_a ( read_data_S_0 ),
	.q_b ( read_data_S_1 )
	);
	
	
	
logic [7:0] MSB,LSB;
always_comb begin
// if all MSB are 1
    MSB =read_data_S_0[23:16];
    if (|read_data_S_0[30:24]) MSB = 8'hFF;
    if (read_data_S_0[31]) MSB = 8'h00;

end 	
always_comb begin
// if all MSB are 1
    LSB =read_data_S_1[23:16];
    if (|read_data_S_1[30:24]) LSB = 8'hFF;
    if (read_data_S_1[31]) LSB = 8'h00;

end 

	
//counter logic 
logic [17:0]read_address_PRE_IDCT,read_address_POST_IDCT,read_address_PRE_IDCT_U_V,write_address_POST_IDCT_U_V;

logic [17:0] read_address_SRAM,write_address_SRAM;
// 320*(8*(RB)+(ri) + 8*(CB)+ci)

// row index = lsb for sample counter counts up to 7 // here you can add the Y base to this equation rather than in the loops
assign read_address_PRE_IDCT = (((row_index + (row_block << 3)) << 8) + ((row_index + (row_block << 3)) << 6)) + (col_index + (column_block << 3));
assign read_address_POST_IDCT = (((row_index_POST_IDCT + (write_row_block << 3)) << 7) + ((row_index_POST_IDCT + (write_row_block << 3)) << 5)) + (col_index_POST_IDCT + (write_column_block << 2));

logic Y_flag_read, U_flag_read, Y_flag_write,U_flag_write;
///

assign read_address_PRE_IDCT_U_V = (((row_index + (row_block << 3)) << 7) + ((row_index + (row_block << 3)) << 5)) + (col_index + (column_block << 3));
assign write_address_POST_IDCT_U_V = (((row_index_POST_IDCT + (write_row_block << 3)) << 6) + ((row_index_POST_IDCT + (write_row_block << 3)) << 4)) + (col_index_POST_IDCT + (write_column_block << 2));

//assign read_address_SRAM = if(Y_flag)?(read_address_PRE_IDCT + Y_read_offset): (if (U_flag)?(read_address_PRE_IDCT_U_V+ U_read_offset):(read_address_PRE_IDCT_U_V+ V_read_offset));
//assign write_address_SRAM = if(Y_flag)?(read_address_POST_IDCT + Y_write_offset): (if (U_flag)?(write_address_POST_IDCT_U_V+ U_write_offset):(write_address_POST_IDCT_U_V+ V_write_offset));

always_comb begin

	read_address_SRAM = read_address_PRE_IDCT_U_V + V_read_offset;
    if (Y_flag_read) read_address_SRAM = read_address_PRE_IDCT + Y_read_offset;
    if (U_flag_read) read_address_SRAM = read_address_PRE_IDCT_U_V + U_read_offset;
end

always_comb begin
//V_write_offset
	write_address_SRAM = write_address_POST_IDCT_U_V + V_write_offset;
	if (Y_flag_write) write_address_SRAM = read_address_POST_IDCT + Y_write_offset;
	if (U_flag_write) write_address_SRAM = write_address_POST_IDCT_U_V + U_write_offset;


end




///
assign col_index = Sample_counter[2:0];
assign row_index = Sample_counter[5:3];

// here counter is different
assign col_index_POST_IDCT = Write_Sample_counter[1:0];
assign row_index_POST_IDCT = Write_Sample_counter[5:2];

logic[2:0] row_index_DPRAM_S_Prime,col_index_DPRAM_S_Prime;
//counter logic 
logic [17:0]read_address_compute_T;
/// Compute T counters;
assign read_address_compute_T = (row_index_DPRAM_S_Prime<<3) + col_index_DPRAM_S_Prime;


// DRAM ADDRESS Sprime_counter
logic [6:0] dram_address_counter_s_prime;	

// DRAM ADDRESS T _counter
logic [7:0] dram_address_counter_T;


logic [2:0] COL_ADDRESS_T,ROW_ADDRESS_T;
logic [17:0]read_address_compute_S;

// row address increments each cycle 0-7 and col address only when row address rolls over.
assign read_address_compute_S = (ROW_ADDRESS_T<<3) + COL_ADDRESS_T;  // 8*Row Address + Col addr


// s counter for writing to DRAM to store S during compute T

logic [6:0]S_counter;

logic [6:0] DS_DP_S0, DS_DP_S1, DS_DP_S2, DS_DP_S3;



/// variables for Write S after Compute S
logic write_even_counter_S_flag,odd_cycle_flag;
logic [2:0] write_even_counter_S, write_odd_counter_S, wrote_even, wrote_odd;
logic [2:0] write_s_twos_counter;
logic [3:0] row_dp_ram_s;
// 4 special addresses 2 for even 2 for odd

logic [6:0] DPRAM_0, DPRAM_1, odd_S_to_DPRAM_0, odd_S_to_DPRAM_1;

assign DPRAM_0 = (write_s_twos_counter<<3) + row_dp_ram_s;
assign DPRAM_1 = (write_s_twos_counter<<3) + row_dp_ram_s + 8'd8;
//assign odd_S_to_DPRAM_0 = (write_s_twos_counter<<3) + (write_odd_counter_S<<1) +6'd1;
//assign odd_S_to_DPRAM_1 = (write_s_twos_counter<<3) + (write_odd_counter_S<<1) + 6'd9;

assign DS_DP_S0 = S_counter;
assign DS_DP_S1 = 6'd8 + S_counter;
assign DS_DP_S2 = 6'd16 + S_counter;
assign DS_DP_S3 = 6'd24 + S_counter;

assign address_s_prime_1 = 7'd0;
assign write_s_prime_1 = 1'b0;

always_ff @ (posedge Clock_50 or negedge Resetn) begin

	if (~Resetn) begin
	row_index_DPRAM_S_Prime<=0;
	col_index_DPRAM_S_Prime<=0;
	blocks_read<=0;
	blocks_written<=0;
	address_s_prime_0<=0; 
	//address_s_prime_1<=0; 
	address_T_0<=0; 
	address_T_1<=0; 
	address_S_0<=0; 
	address_S_1<=0;
	first_pass<=0;
	write_s_prime_0<=0; 
	//write_s_prime_1<=0; 
	write_T_0<=0; 
	write_T_1<=0;
	write_S_0<=0;
	write_S_1<=0;
	WE_s_prime_0<=0;
	WE_s_prime_1<=0;
	WE_T_0<=0;
	WE_T_1<=0;
	WE_S_0<=0;
	WE_S_1<=0;
	M2_done<=0;
	T_0<=0;
	T_1<=0;
	T_2<=0;
	T_2_BUF<=0;
	T_3_BUF<=0;
	Write_Sample_counter<=0;
	//counter reset
	Sample_counter<=0;
	column_block<=0;
	row_block<=0;
	dram_address_counter_s_prime<=0;
	C_multiplier_row<=0;
	C_multiplier_column<=0;
	flag_increment_row<=0;
	flag_increment_column<=0;
	dram_address_counter_T<=0;
	FS_CC_transition<=1;
	mux_counter<=0;
	ROW_ADDRESS_T<=0;
	COL_ADDRESS_T<=0;
	write_column_block<=0;
	write_row_block<=0;
	S_0<=0;
	S_1<=0;
	S_2<=0;
	S_3<=0;
	S_2_BUF<=0; 
	S_3_BUF<=0;
	S_counter<=0;
	stop_write_S_SRAM<=0;
	//// Write S Compute T/////////

	column_block_POST_IDCT<=0;
	row_block_POST_IDCT<=0;
	stop_fs_prime<=0;
	last_write_s_prime<=0;
	write_even_counter_S_flag<=1;
	write_even_counter_S<=0; 
	write_odd_counter_S<=0;
	write_s_twos_counter<=0;
	odd_cycle_flag<=0;
	wrote_even<=0;
	wrote_odd<=0;
	row_dp_ram_s<=0;
	DPRAM_S_READ_COUNTER<=0;
	Y_flag_write<=1;
	U_flag_write<=0;
	Y_flag_read<=1;
	U_flag_read<=0;
	final_write_S_flag<=0;
	//need to set U and Y to zero

	
	end else begin

// READ FIRST 3 S PRIME VALUES 
	case (M2_state)
		
		S_IDLE_M2: begin
		M2_state<= S_IDLE_M2;
		if (M2_start == 1'b1) begin
		Y_flag_read<=1;
		M2_state<= S_LEADIN_Fs_0;
		end
		
		end

		
		S_LEADIN_Fs_0: begin
		//Prepare read S'00
	

		SRAM_address<= read_address_SRAM;
		Sample_counter<= Sample_counter+1'd1; 
		SRAM_we_n<=1;
		SRAM_write_data<=0;


		M2_state<=S_LEADIN_Fs_1;
		end

		S_LEADIN_Fs_1: begin
		SRAM_address<= read_address_SRAM;
		Sample_counter<= Sample_counter+1'd1; 
		SRAM_we_n<=1;

		M2_state<=S_LEADIN_Fs_2;
		end

		S_LEADIN_Fs_2: begin
		SRAM_address<= read_address_SRAM;
		Sample_counter<= Sample_counter+1'd1; 
		SRAM_we_n<=1;

		M2_state<=S_LEADIN_Fs_3;

		end

		// READ AND STORE ALL 64 values into DP RAM FIRST VALUE AVAILABLE HERE

		S_LEADIN_Fs_3: begin

		SRAM_address<= read_address_SRAM;
		Sample_counter<= Sample_counter+1'd1; 
		SRAM_we_n<=1;

		//fill in S00 to location 0 on DPRAM 0
		address_s_prime_0 <=dram_address_counter_s_prime;
		dram_address_counter_s_prime<= dram_address_counter_s_prime+1'd1;
		write_s_prime_0<= {{16{SRAM_read_data[15]}}, SRAM_read_data[15:0]}; // Signed extension to 32-bits;
		WE_s_prime_0<=1'd1;

		M2_state<=S_LEADIN_CC_Fs;

		end

		S_LEADIN_CC_Fs: begin

		SRAM_address<= read_address_SRAM;
		Sample_counter<= Sample_counter+1'd1; 
		SRAM_we_n<=1;

		//fill in S00 to location 0 on DPRAM 0
		address_s_prime_0 <=dram_address_counter_s_prime;
		dram_address_counter_s_prime<= dram_address_counter_s_prime+1'd1;
		write_s_prime_0<= {{16{SRAM_read_data[15]}}, SRAM_read_data[15:0]}; // Signed extension to 32-bits;;
		WE_s_prime_0<=1'd1;


		if(Sample_counter == 7'd63) begin 
		M2_state<=S_LEADOUT_Fs_0;
		WE_s_prime_0<= 1'd0;
		end
		else M2_state<=S_LEADIN_CC_Fs;

		end


		/// send last 2/3 values from SRAM read into DP memory

		S_LEADOUT_Fs_0: begin

		//fill in S75/Y2245 to location 0 on DPRAM 0
		address_s_prime_0 <=dram_address_counter_s_prime;
		dram_address_counter_s_prime<= dram_address_counter_s_prime+1'd1;
		write_s_prime_0<= {{16{SRAM_read_data[15]}}, SRAM_read_data[15:0]}; // Signed extension to 32-bits;;
		WE_s_prime_0<=1'd1;

		M2_state<=S_LEADOUT_Fs_1;

		end

		S_LEADOUT_Fs_1: begin
		//fill in S76/Y2246 to location 0 on DPRAM 0
		address_s_prime_0 <=dram_address_counter_s_prime;
		dram_address_counter_s_prime<= dram_address_counter_s_prime+1'd1;
		write_s_prime_0<= {{16{SRAM_read_data[15]}}, SRAM_read_data[15:0]}; // Signed extension to 32-bits;;
		WE_s_prime_0<=1'd1;


		M2_state<=S_LEADOUT_Fs_2;
		end

		S_LEADOUT_Fs_2: begin
		//fill in S77/Y2247 to location 0 on DPRAM 0
		address_s_prime_0 <=dram_address_counter_s_prime;
		write_s_prime_0<= {{16{SRAM_read_data[15]}}, SRAM_read_data[15:0]}; // Signed extension to 32-bits;;
		WE_s_prime_0<=1'd1;
		// reach 64 and reset to zero and also reset DPRAM for S' to prepare for CT reads starting at zero
		Sample_counter<=0;
		dram_address_counter_s_prime<=0;
		C_multiplier_row<= 0;
		M2_state<=S_LEADIN_CT_0;
		
		//// here column block would need to go to 19 
		column_block <= column_block+1'd1;
		blocks_read <= blocks_read+1'd1;
		
		end


		S_LEADIN_CT_0: begin
		
		address_s_prime_0 <=read_address_compute_T+dram_address_counter_s_prime;
		//dram_address_counter_s_prime<= dram_address_counter_s_prime+1'd1;
		Sample_counter<= Sample_counter+1'd1; 
		WE_s_prime_0<=1'd0;
		// column must increment 
		col_index_DPRAM_S_Prime<= col_index_DPRAM_S_Prime+1'd1;
		// column must increment 
		
		// increment row/column -> in this case would be?
		C_multiplier_row<= C_multiplier_row;
		M2_state<= S_LEADIN_CT_0_0;
		
		end
		
		S_LEADIN_CT_0_0: begin
		
		address_s_prime_0 <=read_address_compute_T;
		
		// column must increment 
		col_index_DPRAM_S_Prime<= col_index_DPRAM_S_Prime+1'd1;
		
		Sample_counter<= Sample_counter+1'd1; 
		WE_s_prime_0<=1'd0;
		
		// increment row/column -> in this case would be?
		C_multiplier_row<= C_multiplier_row;

		
		M2_state<= S_LEADIN_CT_1;
		end
		
		
		S_LEADIN_CT_1: begin
		address_s_prime_0 <=read_address_compute_T;
		
		
		// column must increment 
		col_index_DPRAM_S_Prime<= col_index_DPRAM_S_Prime+1'd1;
		
		
		Sample_counter<= Sample_counter+1'd1; 
		WE_s_prime_0<=1'd0;
		
		
		//MULTIPLIERS
		// c row c column
		Mult_M2_op_0_1<= read_data_s_prime_0;
		Mult_M2_op_0_2<=C0;
		Mult_M2_op_1_1<=read_data_s_prime_0;
		Mult_M2_op_1_2<=C1;
		Mult_M2_op_2_1<=read_data_s_prime_0;
		Mult_M2_op_2_2<=C2;
		Mult_M2_op_3_1<=read_data_s_prime_0;
		Mult_M2_op_3_2<=C3;
		
		mux_counter<= mux_counter+1'd1;
		// once read one column then update C index
		
		C_multiplier_row<= C_multiplier_row+1'd1;
		
		M2_state<= S_LEADIN_CT_2;
		
		end

		S_LEADIN_CT_2: begin

		
		// column must increment 
		col_index_DPRAM_S_Prime<= col_index_DPRAM_S_Prime+1'd1;
		
		
		address_s_prime_0 <=read_address_compute_T;
		
		Sample_counter<= Sample_counter+1'd1; 
		WE_s_prime_0<=1'd0;
		
		
		//MULTIPLIERS
		// c row c column
		Mult_M2_op_0_1<= read_data_s_prime_0;
		Mult_M2_op_0_2<=C0;
		Mult_M2_op_1_1<=read_data_s_prime_0;
		Mult_M2_op_1_2<=C1;
		Mult_M2_op_2_1<=read_data_s_prime_0;
		Mult_M2_op_2_2<=C2;
		Mult_M2_op_3_1<=read_data_s_prime_0;
		Mult_M2_op_3_2<=C3;
		
		mux_counter<= mux_counter+1'd1;
		// once read one column then update C index
		
		C_multiplier_row<= C_multiplier_row+1'd1;
		//  fill in T values into locaitons
		T_0<= Mult_M2_result_0;
		T_1<= Mult_M2_result_1;
		T_2<= Mult_M2_result_2;
		T_3<= Mult_M2_result_3;
		
		
		
		
		M2_state<= S_LEADIN_CT_3;
		end
		
		
		S_LEADIN_CT_3: begin
		
		
		
		// column must increment 
		col_index_DPRAM_S_Prime<= col_index_DPRAM_S_Prime+1'd1;
		
		address_s_prime_0 <=read_address_compute_T;
		Sample_counter<= Sample_counter+1'd1; 
		WE_s_prime_0<=1'd0;
		
		
		//MULTIPLIERS
		// c row c column
		Mult_M2_op_0_1<= read_data_s_prime_0;
		Mult_M2_op_0_2<=C0;
		Mult_M2_op_1_1<=read_data_s_prime_0;
		Mult_M2_op_1_2<=C1;
		Mult_M2_op_2_1<=read_data_s_prime_0;
		Mult_M2_op_2_2<=C2;
		Mult_M2_op_3_1<=read_data_s_prime_0;
		Mult_M2_op_3_2<=C3;
		
		mux_counter<= mux_counter+1'd1;
		// once read one column then update C index
		
		C_multiplier_row<= C_multiplier_row+1'd1;
		//  fill in T values into locaitons
		T_0<= T_0+ Mult_M2_result_0;
		T_1<= T_1+Mult_M2_result_1;
		T_2<= T_2+Mult_M2_result_2;
		T_3<= T_3+Mult_M2_result_3;
		
		
		
		
		
		
		
		
		
		
		
	
		
		address_s_prime_0 <=read_address_compute_T;
		Sample_counter<= Sample_counter+1'd1; 
		WE_s_prime_0<=1'd0;
		
		
		//MULTIPLIERS
		// c row c column
		Mult_M2_op_0_1<= read_data_s_prime_0;
		Mult_M2_op_0_2<=C0;
		Mult_M2_op_1_1<=read_data_s_prime_0;
		Mult_M2_op_1_2<=C1;
		Mult_M2_op_2_1<=read_data_s_prime_0;
		Mult_M2_op_2_2<=C2;
		Mult_M2_op_3_1<=read_data_s_prime_0;
		Mult_M2_op_3_2<=C3;
		mux_counter<= mux_counter+1'd1;
		// once read one column then update C index
		
		C_multiplier_row<= C_multiplier_row+1'd1;
			//  fill in T values into locaitons
		T_0<= T_0+ Mult_M2_result_0;
		T_1<= T_1+Mult_M2_result_1;
		T_2<= T_2+Mult_M2_result_2;
		T_3<= T_3+Mult_M2_result_3;
		
		M2_state<= S_LEADIN_CT_4;
		
		end
		S_LEADIN_CT_4: begin
		
		
		
		
		// column must increment 
		col_index_DPRAM_S_Prime<= col_index_DPRAM_S_Prime+1'd1;
		
		address_s_prime_0 <=read_address_compute_T;
		Sample_counter<= Sample_counter+1'd1; 
		WE_s_prime_0<=1'd0;
		
		
		//MULTIPLIERS
		// c row c column
		Mult_M2_op_0_1<= read_data_s_prime_0;
		Mult_M2_op_0_2<=C0;
		Mult_M2_op_1_1<=read_data_s_prime_0;
		Mult_M2_op_1_2<=C1;
		Mult_M2_op_2_1<=read_data_s_prime_0;
		Mult_M2_op_2_2<=C2;
		Mult_M2_op_3_1<=read_data_s_prime_0;
		Mult_M2_op_3_2<=C3;
		mux_counter<= mux_counter+1'd1;
		// once read one column then update C index
		
		C_multiplier_row<= C_multiplier_row+1'd1;
			//  fill in T values into locaitons
		T_0<= T_0+ Mult_M2_result_0;
		T_1<= T_1+Mult_M2_result_1;
		T_2<= T_2+Mult_M2_result_2;
		T_3<= T_3+Mult_M2_result_3;
		
		
		M2_state<= S_LEADIN_CT_5;
		end 
		S_LEADIN_CT_5: begin
		
		
		// column must increment 
		col_index_DPRAM_S_Prime<= col_index_DPRAM_S_Prime+1'd1;
		address_s_prime_0 <=read_address_compute_T;
		
		Sample_counter<= Sample_counter+1'd1; 
		WE_s_prime_0<=1'd0;
		
		
		//MULTIPLIERS
		// c row c column
		Mult_M2_op_0_1<= read_data_s_prime_0;
		Mult_M2_op_0_2<=C0;
		Mult_M2_op_1_1<=read_data_s_prime_0;
		Mult_M2_op_1_2<=C1;
		Mult_M2_op_2_1<=read_data_s_prime_0;
		Mult_M2_op_2_2<=C2;
		Mult_M2_op_3_1<=read_data_s_prime_0;
		Mult_M2_op_3_2<=C3;
		mux_counter<= mux_counter+1'd1;
		// once read one column then update C index
		
		C_multiplier_row<= C_multiplier_row+1'd1;
		//  fill in T values into locaitons
		T_0<= T_0+ Mult_M2_result_0;
		T_1<= T_1+Mult_M2_result_1;
		T_2<= T_2+Mult_M2_result_2;
		T_3<= T_3+Mult_M2_result_3;
		
		M2_state<= S_LEADIN_CT_6;
		end 
		
		S_LEADIN_CT_6: begin
		
		
		// column must increment 
		col_index_DPRAM_S_Prime<= col_index_DPRAM_S_Prime+1'd1;
		
		
		address_s_prime_0 <=read_address_compute_T;
		Sample_counter<= Sample_counter+1'd1; 
		WE_s_prime_0<=1'd0;
		
		
		//MULTIPLIERS
		// c row c column
		Mult_M2_op_0_1<= read_data_s_prime_0;
		Mult_M2_op_0_2<=C0;
		Mult_M2_op_1_1<=read_data_s_prime_0;
		Mult_M2_op_1_2<=C1;
		Mult_M2_op_2_1<=read_data_s_prime_0;
		Mult_M2_op_2_2<=C2;
		Mult_M2_op_3_1<=read_data_s_prime_0;
		Mult_M2_op_3_2<=C3;
		mux_counter<= mux_counter+1'd1;
		// once read one column then update C index
		
		C_multiplier_row<= C_multiplier_row+1'd1;
			//  fill in T values into locaitons
		T_0<= T_0+ Mult_M2_result_0;
		T_1<= T_1+Mult_M2_result_1;
		T_2<= T_2+Mult_M2_result_2;
		T_3<= T_3+Mult_M2_result_3;
		
		M2_state<= S_LEADIN_CT_7;
		end 
		S_LEADIN_CT_7: begin
		
		
		// RESET TO ZERO IN CT_7 from lead in case.
		// column must increment 
		col_index_DPRAM_S_Prime<= col_index_DPRAM_S_Prime+1'd1;
		
		address_s_prime_0 <=read_address_compute_T;
		Sample_counter<= Sample_counter+1'd1; 
		WE_s_prime_0<=1'd0;
		
		
		//MULTIPLIERS
		// c row c column
		Mult_M2_op_0_1<= read_data_s_prime_0;
		Mult_M2_op_0_2<=C0;
		Mult_M2_op_1_1<=read_data_s_prime_0;
		Mult_M2_op_1_2<=C1;
		Mult_M2_op_2_1<=read_data_s_prime_0;
		Mult_M2_op_2_2<=C2;
		Mult_M2_op_3_1<=read_data_s_prime_0;
		Mult_M2_op_3_2<=C3;
		mux_counter<= mux_counter+1'd1;
		// once read one column then update C index
		
		C_multiplier_row<= C_multiplier_row+1'd1;
			//  fill in T values into locaitons
		T_0<= T_0+ Mult_M2_result_0;
		T_1<= T_1+Mult_M2_result_1;
		T_2<= T_2+Mult_M2_result_2;
		T_3<= T_3+Mult_M2_result_3;
		
		M2_state<= S_LEADIN_CT_8;
		end 
		S_LEADIN_CT_8: begin
		
		
		// column must increment 
		col_index_DPRAM_S_Prime<= col_index_DPRAM_S_Prime+1'd1;
		
		address_s_prime_0 <=read_address_compute_T;	
		Sample_counter<= Sample_counter+1'd1; 
		WE_s_prime_0<=1'd0;
		
		
		//MULTIPLIERS
		// c row c column
		Mult_M2_op_0_1<= read_data_s_prime_0;
		Mult_M2_op_0_2<=C0;
		Mult_M2_op_1_1<=read_data_s_prime_0;
		Mult_M2_op_1_2<=C1;
		Mult_M2_op_2_1<=read_data_s_prime_0;
		Mult_M2_op_2_2<=C2;
		Mult_M2_op_3_1<=read_data_s_prime_0;
		Mult_M2_op_3_2<=C3;
		mux_counter<= mux_counter+1'd1;
		// once read one column then update C index
		
	
		// RESET TO ZERO
		C_multiplier_row<= 0;
		//  fill in T values into locaitons
			//  fill in T values into locaitons
		T_0<= T_0+ Mult_M2_result_0;
		T_1<= T_1+Mult_M2_result_1;
		T_2<= T_2+Mult_M2_result_2;
		T_3<= T_3+Mult_M2_result_3;
		
		if (FS_CC_transition==1)C_multiplier_column<=6'd4;
		FS_CC_transition<=0;
		if (c_index_3 == 16'd59) FS_CC_transition<=1;
		
		M2_state<= S_CC_CT_0;
		end 
		
		
		
		
		/// COMMON CASE FOR COMPUTE T BEGINS HERE?
		S_CC_CT_0: begin
		
		
		col_index_DPRAM_S_Prime<= col_index_DPRAM_S_Prime+1'd1;
		
		address_s_prime_0 <=read_address_compute_T;
		Sample_counter<= Sample_counter+1'd1; 
		// each cycle column counter is either 0 or 4
		//need to be changed
		
//		if (c_index_3 == 16'd59) C_multiplier_column<=6'd4;
//		else C_multiplier_column<=6'd0;
		 
		 
		M2_state<= S_CC_CT_1;
		if (dram_address_counter_T == 16'd64) M2_state<=S_CC_CT_LO_0;	
		
		flag_increment_row <= ~flag_increment_row;
		
		C_multiplier_row <= C_multiplier_row+1;
		
		//MULTIPLIERS
		// c row c column
		Mult_M2_op_0_1<= read_data_s_prime_0;
		Mult_M2_op_0_2<=C0;
		Mult_M2_op_1_1<=read_data_s_prime_0;
		Mult_M2_op_1_2<=C1;
		Mult_M2_op_2_1<=read_data_s_prime_0;
		Mult_M2_op_2_2<=C2;
		Mult_M2_op_3_1<=read_data_s_prime_0;
		Mult_M2_op_3_2<=C3;
		mux_counter<= mux_counter+1'd1;
		
		//  READY HERE
		T_0<= T_0+Mult_M2_result_0;
		T_1<= T_1+Mult_M2_result_1;
		T_2<= T_2+Mult_M2_result_2;
		T_3<= T_3+Mult_M2_result_3;
		
		
		
		
		
		end

		S_CC_CT_1: begin
		
		
		col_index_DPRAM_S_Prime<= col_index_DPRAM_S_Prime+1'd1;
		
		address_s_prime_0 <=read_address_compute_T;
		
		Sample_counter<= Sample_counter+1'd1; 

			
		address_s_prime_0 <=read_address_compute_T+dram_address_counter_s_prime;
		//dram_address_counter_s_prime<= dram_address_counter_s_prime+1'd1;
		Sample_counter<= Sample_counter+1'd1; 
		WE_s_prime_0<=1'd0;
		
		
		// write to DPRAM_T write 2 values at once COUNTER GOES UP BY +2
		dram_address_counter_T<= dram_address_counter_T+2'd2;
		
		C_multiplier_row <= C_multiplier_row+1;
	
		address_T_0<=dram_address_counter_T;
		address_T_1<=dram_address_counter_T+1'd1;
		write_T_0<=T_0>>>8;
		write_T_1<=T_1>>>8;
		WE_T_0<=1'd1;
		WE_T_1<=1'd1;
		
		// BUFFER VALUES FOR NEXT WRITE BUT ALSO COMPUTE NEW VALUES AT THE SAME TIME
		T_2_BUF<= T_2;
		T_3_BUF<= T_3;
	
		
		
		
		//MULTIPLIERS
		// c row c column
		Mult_M2_op_0_1<= read_data_s_prime_0;
		Mult_M2_op_0_2<=C0;
		Mult_M2_op_1_1<=read_data_s_prime_0;
		Mult_M2_op_1_2<=C1;
		Mult_M2_op_2_1<=read_data_s_prime_0;
		Mult_M2_op_2_2<=C2;
		Mult_M2_op_3_1<=read_data_s_prime_0;
		Mult_M2_op_3_2<=C3;
		mux_counter<= mux_counter+1'd1;
		
		//  brand new
		T_0<= Mult_M2_result_0;
		T_1<= Mult_M2_result_1;
		T_2<= Mult_M2_result_2;
		T_3<= Mult_M2_result_3;
		
		
		M2_state<= S_CC_CT_2;
		
		end
		S_CC_CT_2: begin
		
		col_index_DPRAM_S_Prime<= col_index_DPRAM_S_Prime+1'd1;
		
		address_s_prime_0 <=read_address_compute_T;
		//dram_address_counter_s_prime<= dram_address_counter_s_prime+1'd1;
		Sample_counter<= Sample_counter+1'd1; 
		WE_s_prime_0<=1'd0;
		
		
		C_multiplier_row <= C_multiplier_row+1;
		
		
		
		// write to DPRAM_T write 2 values at once
		dram_address_counter_T<= dram_address_counter_T+2'd2;
		address_T_0<=dram_address_counter_T;
		address_T_1<=dram_address_counter_T+1'd1;
		write_T_0<=T_2_BUF>>>8;
		write_T_1<=T_3_BUF>>>8;
		WE_T_0<=1'd1;
		WE_T_1<=1'd1;
		

		
		
		
		//MULTIPLIERS
		// c row c column
		Mult_M2_op_0_1<= read_data_s_prime_0;
		Mult_M2_op_0_2<=C0;
		Mult_M2_op_1_1<=read_data_s_prime_0;
		Mult_M2_op_1_2<=C1;
		Mult_M2_op_2_1<=read_data_s_prime_0;
		Mult_M2_op_2_2<=C2;
		Mult_M2_op_3_1<=read_data_s_prime_0;
		Mult_M2_op_3_2<=C3;
		
		mux_counter<= mux_counter+1'd1;

		T_0<= T_0+Mult_M2_result_0;
		T_1<= T_1+Mult_M2_result_1;
		T_2<= T_2+Mult_M2_result_2;
		T_3<= T_3+Mult_M2_result_3;
		
		
		M2_state<= S_CC_CT_3;
		end 
		S_CC_CT_3: begin
		
		
		col_index_DPRAM_S_Prime<= col_index_DPRAM_S_Prime+1'd1;
		// ALWAYS AFTER WRITING RESET THE WE EN TO 0 TO ENSURE NO CORRUPTION 
		WE_T_0<=1'd0;
		WE_T_1<=1'd0;
		
		C_multiplier_row <= C_multiplier_row+1;
		address_s_prime_0 <=read_address_compute_T;
		Sample_counter<= Sample_counter+1'd1; 
		WE_s_prime_0<=1'd0;
		
		
				
		//MULTIPLIERS
		// c row c column
		Mult_M2_op_0_1<= read_data_s_prime_0;
		Mult_M2_op_0_2<=C0;
		Mult_M2_op_1_1<=read_data_s_prime_0;
		Mult_M2_op_1_2<=C1;
		Mult_M2_op_2_1<=read_data_s_prime_0;
		Mult_M2_op_2_2<=C2;
		Mult_M2_op_3_1<=read_data_s_prime_0;
		Mult_M2_op_3_2<=C3;
		
		mux_counter<= mux_counter+1'd1;

		T_0<= T_0+Mult_M2_result_0;
		T_1<= T_1+Mult_M2_result_1;
		T_2<= T_2+Mult_M2_result_2;
		T_3<= T_3+Mult_M2_result_3;
		
		M2_state<= S_CC_CT_4;
		end
		S_CC_CT_4: begin
		
		col_index_DPRAM_S_Prime<= col_index_DPRAM_S_Prime+1'd1;
		// ALWAYS AFTER WRITING RESET THE WE EN TO 0 TO ENSURE NO CORRUPTION 
		WE_T_0<=1'd0;
		WE_T_1<=1'd0;
		
		
		address_s_prime_0 <=read_address_compute_T;
		
		Sample_counter<= Sample_counter+1'd1; 
		WE_s_prime_0<=1'd0;
		
		
		C_multiplier_row <= C_multiplier_row+1;		
		//MULTIPLIERS
		// c row c column
		Mult_M2_op_0_1<= read_data_s_prime_0;
		Mult_M2_op_0_2<=C0;
		Mult_M2_op_1_1<=read_data_s_prime_0;
		Mult_M2_op_1_2<=C1;
		Mult_M2_op_2_1<=read_data_s_prime_0;
		Mult_M2_op_2_2<=C2;
		Mult_M2_op_3_1<=read_data_s_prime_0;
		Mult_M2_op_3_2<=C3;
		
		mux_counter<= mux_counter+1'd1;

		T_0<= T_0+Mult_M2_result_0;
		T_1<= T_1+Mult_M2_result_1;
		T_2<= T_2+Mult_M2_result_2;
		T_3<= T_3+Mult_M2_result_3;
		
		
		
		M2_state<= S_CC_CT_5;
		end
		S_CC_CT_5: begin
		
		
		col_index_DPRAM_S_Prime<= col_index_DPRAM_S_Prime+1'd1;
		// ALWAYS AFTER WRITING RESET THE WE EN TO 0 TO ENSURE NO CORRUPTION 
		WE_T_0<=1'd0;
		WE_T_1<=1'd0;
		
		
		address_s_prime_0 <=read_address_compute_T;
		Sample_counter<= Sample_counter+1'd1; 
		WE_s_prime_0<=1'd0;
		
		C_multiplier_row <= C_multiplier_row+1;
				
		//MULTIPLIERS
		// c row c column
		Mult_M2_op_0_1<= read_data_s_prime_0;
		Mult_M2_op_0_2<=C0;
		Mult_M2_op_1_1<=read_data_s_prime_0;
		Mult_M2_op_1_2<=C1;
		Mult_M2_op_2_1<=read_data_s_prime_0;
		Mult_M2_op_2_2<=C2;
		Mult_M2_op_3_1<=read_data_s_prime_0;
		Mult_M2_op_3_2<=C3;
		
		mux_counter<= mux_counter+1'd1;

		T_0<= T_0+Mult_M2_result_0;
		T_1<= T_1+Mult_M2_result_1;
		T_2<= T_2+Mult_M2_result_2;
		T_3<= T_3+Mult_M2_result_3;
		
			//special case
		//logic for incrementing row counter for C
		if (flag_increment_row==1'b1)begin
		row_index_DPRAM_S_Prime<= row_index_DPRAM_S_Prime+1'd1;	
		end
		
		M2_state<= S_CC_CT_6;
		end
		S_CC_CT_6: begin
		
		
		col_index_DPRAM_S_Prime<= col_index_DPRAM_S_Prime+1'd1;	
		// ALWAYS AFTER WRITING RESET THE WE EN TO 0 TO ENSURE NO CORRUPTION 
		WE_T_0<=1'd0;
		WE_T_1<=1'd0;
		
		
		address_s_prime_0 <=read_address_compute_T;
		Sample_counter<= Sample_counter+1'd1; 
		WE_s_prime_0<=1'd0;
		
		
		C_multiplier_row <= C_multiplier_row+1;		
		//MULTIPLIERS
		// c row c column
		Mult_M2_op_0_1<= read_data_s_prime_0;
		Mult_M2_op_0_2<=C0;
		Mult_M2_op_1_1<=read_data_s_prime_0;
		Mult_M2_op_1_2<=C1;
		Mult_M2_op_2_1<=read_data_s_prime_0;
		Mult_M2_op_2_2<=C2;
		Mult_M2_op_3_1<=read_data_s_prime_0;
		Mult_M2_op_3_2<=C3;
		
		mux_counter<= mux_counter+1'd1;

		T_0<= T_0+Mult_M2_result_0;
		T_1<= T_1+Mult_M2_result_1;
		T_2<= T_2+Mult_M2_result_2;
		T_3<= T_3+Mult_M2_result_3;
		
		
	
		
		
		M2_state<= S_CC_CT_7;
		end
		S_CC_CT_7: begin
		
		col_index_DPRAM_S_Prime<= col_index_DPRAM_S_Prime+1'd1;	
		
		// ALWAYS AFTER WRITING RESET THE WE EN TO 0 TO ENSURE NO CORRUPTION 
		WE_T_0<=1'd0;
		WE_T_1<=1'd0;
		
		
		address_s_prime_0 <=read_address_compute_T;
		
		Sample_counter<= Sample_counter+1'd1; 
		WE_s_prime_0<=1'd0;
		
		
		C_multiplier_row <= C_multiplier_row+1;		
		//MULTIPLIERS
		// c row c column
		Mult_M2_op_0_1<= read_data_s_prime_0;
		Mult_M2_op_0_2<=C0;
		Mult_M2_op_1_1<=read_data_s_prime_0;
		Mult_M2_op_1_2<=C1;
		Mult_M2_op_2_1<=read_data_s_prime_0;
		Mult_M2_op_2_2<=C2;
		Mult_M2_op_3_1<=read_data_s_prime_0;
		Mult_M2_op_3_2<=C3;
		
		mux_counter<= mux_counter+1'd1;

		T_0<= T_0+Mult_M2_result_0; 
		T_1<= T_1+Mult_M2_result_1;
		T_2<= T_2+Mult_M2_result_2;
		T_3<= T_3+Mult_M2_result_3;
		
		//logic for incrementing row counter for C
		if (flag_increment_row==1'b1)begin
		C_multiplier_row <= C_multiplier_row+1;
		//row_index_DPRAM_S_Prime<= row_index_DPRAM_S_Prime+1'd1;	
		end
		else C_multiplier_row <= C_multiplier_row;
	

		if (c_index_3 == 16'd59) C_multiplier_column<=6'd4;
		else C_multiplier_column<=6'd0;
		
		
		first_pass<=0;
		M2_state<= S_CC_CT_0;	
		
		// how do you come out of this state
		
		// 
		
		
		end
		S_CC_CT_LO_0: begin
		
		if (first_pass ==1'b1) begin
		// 2 LEAD OUT CASES FOR WRITE T FOR LAST 4 T VALUES ...
			// write to DPRAM_T write 2 values at once
		dram_address_counter_T<= dram_address_counter_T+2'd2;
		address_T_0<=dram_address_counter_T;
		address_T_1<=dram_address_counter_T+1'd1;
		
		
		//note these should be T2/T3 if it makes sense
		write_T_0<=T_2>>>8;
		write_T_1<=T_3>>>8;
		WE_T_0<=1'd1;
		WE_T_1<=1'd1;
		end
		
		
		M2_state<= S_CC_CT_LO_1;
	
		
		end
		
		S_CC_CT_LO_1: begin
		WE_S_0 <= 1'b0;
		WE_S_1 <=1'b0;
		S_0 <= 0;
		S_1 <= 0;
		S_2 <= 0;
		S_3 <= 0;
		write_s_twos_counter<=0;
		row_dp_ram_s<=0;
		ROW_ADDRESS_T<=0;
		COL_ADDRESS_T<=0;
		address_S_0<=0;
		address_S_1<=0;
		//reset mux_counter
		DPRAM_S_READ_COUNTER<=0;
		mux_counter<=0;
		WE_T_0<=1'd0;
		WE_T_1<=1'd0;
		Sample_counter<=0;
	
		//M2_done<=1;
		
		// to prepare for next T
		dram_address_counter_T<=0;
		M2_state<= S_CS_FS_LI_0;
		
		
		//IMPORTANT UPDATE ROW COUNTER OR COLUMN BLOCK
		
		//// here column block would need to go to 19 
//		column_block <= column_block+1'd1;
//		blocks_read <= blocks_read+1'd1;
//		//enclosed IF based on the flag 
//		// if (Y)
//		// else do UV
//		// last write needs to go to ONLY WRITE STATE NOT YET IMPLEMENTED incode change 3 blocks of code and assign statements
//		// hit  go to Y
//		// hit 600 go to U
//		
//		if (Y_flag_read) begin
//		
//			if (column_block == 6'd39) begin
//				row_block <= row_block +1'd1;
//				column_block<=0;
//			end
//		
//			if ((row_block == 5'd29) && (column_block == 6'd39)) begin
//			row_block <= 0;
//			column_block<=0;
//			end	
//		
//		end
//		
//		else begin
//		
//			if (column_block == 6'd19) begin
//				row_block <= row_block +1'd1;
//				column_block<=0;
//			
//			end
//		
//			if ((row_block == 5'd29) && (column_block == 6'd19)) begin
//			row_block <= 0;
//			column_block<=0;
//			end
//		
//		
//		
//		
//		
//		
//		end
		
		stop_write_S_SRAM<=0;
	end
		S_CS_FS_LI_0: begin
		// indicating that we no longer need to do all the LO functions
		mux_counter<=0;
		first_pass<=1;
		// reset flag
		stop_fs_prime <=0;
		///// Fetch S'
		
		SRAM_address<= read_address_SRAM;
		Sample_counter<= Sample_counter+1'd1; 
		SRAM_we_n<=1;
		
		/// Compute S
		ROW_ADDRESS_T<=ROW_ADDRESS_T+1'd1;
		address_T_0<= read_address_compute_S;
		WE_T_0 <=0;
		
		M2_state<= S_CS_FS_LI_1;
		
		
		end
		
		S_CS_FS_LI_1: begin
		
		
		/// Fetch S'
		SRAM_address<= read_address_SRAM;
		Sample_counter<= Sample_counter+1'd1; 
		SRAM_we_n<=1;
		
		
		/// Compute S
		ROW_ADDRESS_T<=ROW_ADDRESS_T+1'd1;
		address_T_0<= read_address_compute_S;
		WE_T_0 <=0;
		

		M2_state<= S_CS_FS_LI_2;
		end
		
		S_CS_FS_LI_2: begin
		
		/// Fetch S'
		SRAM_address<= read_address_SRAM;
		Sample_counter<= Sample_counter+1'd1; 
		SRAM_we_n<=1;
		
		
		
		
		/// Compute S
		ROW_ADDRESS_T<=ROW_ADDRESS_T+1'd1;
		address_T_0<= read_address_compute_S;
		WE_T_0 <=0;
		
		
		// c row c column
		Mult_M2_op_0_1<= read_data_T_0;
		Mult_M2_op_0_2<=C0;
		Mult_M2_op_1_1<=read_data_T_0;
		Mult_M2_op_1_2<=C1;
		Mult_M2_op_2_1<=read_data_T_0;
		Mult_M2_op_2_2<=C2;
		Mult_M2_op_3_1<=read_data_T_0;
		Mult_M2_op_3_2<=C3;
		mux_counter<= mux_counter+1'd1;
		
		M2_state<= S_CS_FS_LI_3;

		
		end
		
		S_CS_FS_LI_3: begin
			// fetch s'
			/// Fetch S'
		SRAM_address<= read_address_SRAM;
		Sample_counter<= Sample_counter+1'd1; 
		SRAM_we_n<=1;
		
		// first LI_3
		
		//fill in S76/Y2246 to location 0 on DPRAM 0
		address_s_prime_0 <=dram_address_counter_s_prime;
		dram_address_counter_s_prime<= dram_address_counter_s_prime+1'd1;
		write_s_prime_0<= {{16{SRAM_read_data[15]}}, SRAM_read_data[15:0]}; // Signed extension to 32-bits;;
		WE_s_prime_0<=1'd1;

		
		

		/// Compute S
		ROW_ADDRESS_T<=ROW_ADDRESS_T+1'd1;
		address_T_0<= read_address_compute_S;
		WE_T_0 <=0;
		
		// c row c column
		Mult_M2_op_0_1<= read_data_T_0;
		Mult_M2_op_0_2<=C0;
		Mult_M2_op_1_1<=read_data_T_0;
		Mult_M2_op_1_2<=C1;
		Mult_M2_op_2_1<=read_data_T_0;
		Mult_M2_op_2_2<=C2;
		Mult_M2_op_3_1<=read_data_T_0;
		Mult_M2_op_3_2<=C3;
		mux_counter<= mux_counter+1'd1;
		
		//addtion BRAND NEW
		S_0 <= S_0+Mult_M2_result_0;
		S_1 <= S_1+Mult_M2_result_1;
		S_2 <= S_2+Mult_M2_result_2;
		S_3 <= S_3+Mult_M2_result_3;
		
		M2_state<= S_CS_FS_LI_4;
		end
		
		S_CS_FS_LI_4: begin
		
				// fetch s'
			/// Fetch S'
		SRAM_address<= read_address_SRAM;
		Sample_counter<= Sample_counter+1'd1; 
		SRAM_we_n<=1;
		
			//fill in S76/Y2246 to location 0 on DPRAM 0
		address_s_prime_0 <=dram_address_counter_s_prime;
		dram_address_counter_s_prime<= dram_address_counter_s_prime+1'd1;
		write_s_prime_0<= {{16{SRAM_read_data[15]}}, SRAM_read_data[15:0]}; // Signed extension to 32-bits;;
		WE_s_prime_0<=1'd1;
		

		/// Compute S
		ROW_ADDRESS_T<=ROW_ADDRESS_T+1'd1;
		address_T_0<= read_address_compute_S;
		WE_T_0 <=0;
		
		// c row c column
		Mult_M2_op_0_1<= read_data_T_0;
		Mult_M2_op_0_2<=C0;
		Mult_M2_op_1_1<=read_data_T_0;
		Mult_M2_op_1_2<=C1;
		Mult_M2_op_2_1<=read_data_T_0;
		Mult_M2_op_2_2<=C2;
		Mult_M2_op_3_1<=read_data_T_0;
		Mult_M2_op_3_2<=C3;
		mux_counter<= mux_counter+1'd1;
		
		//addtion BRAND NEW
		S_0 <= S_0+Mult_M2_result_0;
		S_1 <= S_1+Mult_M2_result_1;
		S_2 <= S_2+Mult_M2_result_2;
		S_3 <= S_3+Mult_M2_result_3;
		
		
		
		
		
		M2_state<= S_CS_FS_LI_5;
		end
		S_CS_FS_LI_5: begin
		
				// fetch s'
			/// Fetch S'
		SRAM_address<= read_address_SRAM;
		Sample_counter<= Sample_counter+1'd1; 
		SRAM_we_n<=1;
		
		
			//fill in S76/Y2246 to location 0 on DPRAM 0
		address_s_prime_0 <=dram_address_counter_s_prime;
		dram_address_counter_s_prime<= dram_address_counter_s_prime+1'd1;
		write_s_prime_0<= {{16{SRAM_read_data[15]}}, SRAM_read_data[15:0]}; // Signed extension to 32-bits;;
		WE_s_prime_0<=1'd1;
		
		

		/// Compute S
		ROW_ADDRESS_T<=ROW_ADDRESS_T+1'd1;
		address_T_0<= read_address_compute_S;
		WE_T_0 <=0;
		
		// c row c column
		Mult_M2_op_0_1<= read_data_T_0;
		Mult_M2_op_0_2<=C0;
		Mult_M2_op_1_1<=read_data_T_0;
		Mult_M2_op_1_2<=C1;
		Mult_M2_op_2_1<=read_data_T_0;
		Mult_M2_op_2_2<=C2;
		Mult_M2_op_3_1<=read_data_T_0;
		Mult_M2_op_3_2<=C3;
		mux_counter<= mux_counter+1'd1;
		
		//addtion BRAND NEW
		S_0 <= S_0+Mult_M2_result_0;
		S_1 <= S_1+Mult_M2_result_1;
		S_2 <= S_2+Mult_M2_result_2;
		S_3 <= S_3+Mult_M2_result_3;
		
		
		M2_state<= S_CS_FS_LI_6;
		end
		S_CS_FS_LI_6: begin
		
				// fetch s'
			/// Fetch S'
		SRAM_address<= read_address_SRAM;
		Sample_counter<= Sample_counter+1'd1; 
		SRAM_we_n<=1;
		
			//fill in S76/Y2246 to location 0 on DPRAM 0
		address_s_prime_0 <=dram_address_counter_s_prime;
		dram_address_counter_s_prime<= dram_address_counter_s_prime+1'd1;
		write_s_prime_0<= {{16{SRAM_read_data[15]}}, SRAM_read_data[15:0]}; // Signed extension to 32-bits;;
		WE_s_prime_0<=1'd1;
		
		
		

		/// Compute S
		ROW_ADDRESS_T<=ROW_ADDRESS_T+1'd1;
		address_T_0<= read_address_compute_S;
		WE_T_0 <=0;
		
		// c row c column
		Mult_M2_op_0_1<= read_data_T_0;
		Mult_M2_op_0_2<=C0;
		Mult_M2_op_1_1<=read_data_T_0;
		Mult_M2_op_1_2<=C1;
		Mult_M2_op_2_1<=read_data_T_0;
		Mult_M2_op_2_2<=C2;
		Mult_M2_op_3_1<=read_data_T_0;
		Mult_M2_op_3_2<=C3;
		mux_counter<= mux_counter+1'd1;
		
		//addtion BRAND NEW
		S_0 <= S_0+Mult_M2_result_0;
		S_1 <= S_1+Mult_M2_result_1;
		S_2 <= S_2+Mult_M2_result_2;
		S_3 <= S_3+Mult_M2_result_3;
		
		
		M2_state<= S_CS_FS_LI_7;
		end
		S_CS_FS_LI_7: begin
		
				// fetch s'
			/// Fetch S'
		SRAM_address<= read_address_SRAM;
		Sample_counter<= Sample_counter+1'd1; 
		SRAM_we_n<=1;
		
			//fill in S76/Y2246 to location 0 on DPRAM 0
		address_s_prime_0 <=dram_address_counter_s_prime;
		dram_address_counter_s_prime<= dram_address_counter_s_prime+1'd1;
		write_s_prime_0<= {{16{SRAM_read_data[15]}}, SRAM_read_data[15:0]}; // Signed extension to 32-bits;;
		WE_s_prime_0<=1'd1;
		

		/// Compute S
		ROW_ADDRESS_T<=ROW_ADDRESS_T+1'd1;
		address_T_0<= read_address_compute_S;
		WE_T_0 <=0;
		
		// c row c column
		Mult_M2_op_0_1<= read_data_T_0;
		Mult_M2_op_0_2<=C0;
		Mult_M2_op_1_1<=read_data_T_0;
		Mult_M2_op_1_2<=C1;
		Mult_M2_op_2_1<=read_data_T_0;
		Mult_M2_op_2_2<=C2;
		Mult_M2_op_3_1<=read_data_T_0;
		Mult_M2_op_3_2<=C3;
		mux_counter<= mux_counter+1'd1;
		
		//addtion BRAND NEW
		S_0 <= S_0+Mult_M2_result_0;
		S_1 <= S_1+Mult_M2_result_1;
		S_2 <= S_2+Mult_M2_result_2;
		S_3 <= S_3+Mult_M2_result_3;
		
		
		M2_state<= S_CS_FS_LI_8;
		
		
		
		
		
		
		
		end
		S_CS_FS_LI_8: begin
		
		// fetch s'
		/// Fetch S'
		SRAM_address<= read_address_SRAM;
		Sample_counter<= Sample_counter+1'd1; 
		SRAM_we_n<=1;
		
			//fill in S76/Y2246 to location 0 on DPRAM 0
		address_s_prime_0 <=dram_address_counter_s_prime;
		dram_address_counter_s_prime<= dram_address_counter_s_prime+1'd1;
		write_s_prime_0<= {{16{SRAM_read_data[15]}}, SRAM_read_data[15:0]}; // Signed extension to 32-bits;;
		WE_s_prime_0<=1'd1;
		

		/// Compute S
		ROW_ADDRESS_T<=ROW_ADDRESS_T+1'd1;
		address_T_0<= read_address_compute_S;
		WE_T_0 <=0;
		
		// c row c column
		Mult_M2_op_0_1<= read_data_T_0;
		Mult_M2_op_0_2<=C0;
		Mult_M2_op_1_1<=read_data_T_0;
		Mult_M2_op_1_2<=C1;
		Mult_M2_op_2_1<=read_data_T_0;
		Mult_M2_op_2_2<=C2;
		Mult_M2_op_3_1<=read_data_T_0;
		Mult_M2_op_3_2<=C3;
		mux_counter<= mux_counter+1'd1;
		
		//addtion 
		S_0 <= S_0+Mult_M2_result_0;
		S_1 <= S_1+Mult_M2_result_1;
		S_2 <= S_2+Mult_M2_result_2;
		S_3 <= S_3+Mult_M2_result_3;
	
		M2_state<= S_CS_FS_CC_0;
		end
		
		S_CS_FS_CC_0: begin
		
		
		
		if (stop_fs_prime ==0) begin
		SRAM_address<= read_address_SRAM;
		Sample_counter<= Sample_counter+1'd1; 
		SRAM_we_n<=1;
		
		
		//fill in S76/Y2246 to location 0 on DPRAM 0
		address_s_prime_0 <=dram_address_counter_s_prime;
		dram_address_counter_s_prime<= dram_address_counter_s_prime+1'd1;
		write_s_prime_0<= {{16{SRAM_read_data[15]}}, SRAM_read_data[15:0]}; // Signed extension to 32-bits;;
		WE_s_prime_0<=1'd1;
		end
		
		if (last_write_s_prime ==1) begin
		//fill in S76/Y2246 to location 0 on DPRAM 0
		address_s_prime_0 <=dram_address_counter_s_prime;
		dram_address_counter_s_prime<= dram_address_counter_s_prime+1'd1;
		write_s_prime_0<= {{16{SRAM_read_data[15]}}, SRAM_read_data[15:0]}; // Signed extension to 32-bits;;
		WE_s_prime_0<=1'd1;
		//last_write_s_prime<=0;
		end
		

		

		/// Compute S
		ROW_ADDRESS_T<=ROW_ADDRESS_T+1'd1;
		address_T_0<= read_address_compute_S;
		WE_T_0 <=0;
		
		// c row c column
		Mult_M2_op_0_1<= read_data_T_0;
		Mult_M2_op_0_2<=C0;
		Mult_M2_op_1_1<=read_data_T_0;
		Mult_M2_op_1_2<=C1;
		Mult_M2_op_2_1<=read_data_T_0;
		Mult_M2_op_2_2<=C2;
		Mult_M2_op_3_1<=read_data_T_0;
		Mult_M2_op_3_2<=C3;
		mux_counter<= mux_counter+1'd1;
		
		//addtion 
		S_0 <= S_0+Mult_M2_result_0;
		S_1 <= S_1+Mult_M2_result_1;
		S_2 <= S_2+Mult_M2_result_2;
		S_3 <= S_3+Mult_M2_result_3;
		
	
		
		M2_state<= S_CS_FS_CC_1;
		
		end
		
		
		
		
		S_CS_FS_CC_1: begin
		
		
		// toggle flag
		flag_increment_column <= ~flag_increment_column;
		
		
		
		if (stop_fs_prime ==0) begin
		SRAM_address<= read_address_SRAM;
		Sample_counter<= Sample_counter+1'd1; 
		SRAM_we_n<=1;
		
		
		//fill in S76/Y2246 to location 0 on DPRAM 0
		address_s_prime_0 <=dram_address_counter_s_prime;
		dram_address_counter_s_prime<= dram_address_counter_s_prime+1'd1;
		write_s_prime_0<= {{16{SRAM_read_data[15]}}, SRAM_read_data[15:0]}; // Signed extension to 32-bits;;
		WE_s_prime_0<=1'd1;


		
		end
		
		if (last_write_s_prime ==1) begin
		//fill in S76/Y2246 to location 0 on DPRAM 0
		address_s_prime_0 <=dram_address_counter_s_prime;
		dram_address_counter_s_prime<= dram_address_counter_s_prime+1'd1;
		write_s_prime_0<= {{16{SRAM_read_data[15]}}, SRAM_read_data[15:0]}; // Signed extension to 32-bits;;
		WE_s_prime_0<=1'd1;
		last_write_s_prime<=0;
		
		end
	
		

		/// Compute S
		ROW_ADDRESS_T<=ROW_ADDRESS_T+1'd1;
		address_T_0<= read_address_compute_S;
		WE_T_0 <=0;
		
		// c row c column
		Mult_M2_op_0_1<= read_data_T_0;
		Mult_M2_op_0_2<=C0;
		Mult_M2_op_1_1<=read_data_T_0;
		Mult_M2_op_1_2<=C1;
		Mult_M2_op_2_1<=read_data_T_0;
		Mult_M2_op_2_2<=C2;
		Mult_M2_op_3_1<=read_data_T_0;
		Mult_M2_op_3_2<=C3;
		mux_counter<= mux_counter+1'd1;
		
		S_0 <= S_0+Mult_M2_result_0;
		S_1 <= S_1+Mult_M2_result_1;
		S_2 <= S_2+Mult_M2_result_2;
		S_3 <= S_3+Mult_M2_result_3;
		
		M2_state<= S_CS_FS_CC_2;
		
		end
		
		S_CS_FS_CC_2: begin
		
		
				
		if (stop_fs_prime ==0) begin
		SRAM_address<= read_address_SRAM;
		Sample_counter<= Sample_counter+1'd1; 
		SRAM_we_n<=1;
		
		
		//fill in S76/Y2246 to location 0 on DPRAM 0
		address_s_prime_0 <=dram_address_counter_s_prime;
		dram_address_counter_s_prime<= dram_address_counter_s_prime+1'd1;
		write_s_prime_0<= {{16{SRAM_read_data[15]}}, SRAM_read_data[15:0]}; // Signed extension to 32-bits;;
		WE_s_prime_0<=1'd1;
		
		end
		
		
		

		/// Compute S
		ROW_ADDRESS_T<=ROW_ADDRESS_T+1'd1;
		address_T_0<= read_address_compute_S;
		WE_T_0 <=0;
		
		// c row c column
		Mult_M2_op_0_1<= read_data_T_0;
		Mult_M2_op_0_2<=C0;
		Mult_M2_op_1_1<=read_data_T_0;
		Mult_M2_op_1_2<=C1;
		Mult_M2_op_2_1<=read_data_T_0;
		Mult_M2_op_2_2<=C2;
		Mult_M2_op_3_1<=read_data_T_0;
		Mult_M2_op_3_2<=C3;
		mux_counter<= mux_counter+1'd1;
		
	//addtion new 
		S_0 <= Mult_M2_result_0;
		S_1 <= Mult_M2_result_1;
		S_2 <= Mult_M2_result_2;
		S_3 <= Mult_M2_result_3;
		
		
		
		
		address_S_0<=DPRAM_0;
		address_S_1<=DPRAM_1; 
	
		 
		// update counter 
		
		// update counter 
		//write_s_twos_counter <= write_s_twos_counter+2'd2;
		
		write_s_twos_counter <= write_s_twos_counter+2'd2;
		//buffer values
		
		S_3_BUF<=S_3;
		S_2_BUF<=S_2;
		
		write_S_0 <=(S_0);
		write_S_1 <=(S_1);
		// set to zero after writing
		WE_S_0 <= 1'b1;
		WE_S_1 <=1'b1;
		
		
		
		
		
		
		
		
	
		// update counter after last here
		//S_counter <= S_counter+1'd1;
		
		M2_state<= S_CS_FS_CC_3;
		
		
		
		
		
		
		end
		
		S_CS_FS_CC_3: begin
		
			//second two writes
		
		// logic writing affected by even and odd to DPRAM
		
	
		address_S_0<=DPRAM_0;
		address_S_1<=DPRAM_1; 
		
		// update counter 
		write_s_twos_counter <= write_s_twos_counter+2'd2;
		
		write_S_0 <=(S_2_BUF);
		write_S_1 <=(S_3_BUF);
		// set to zero after writing
		WE_S_0 <= 1'b1;
		WE_S_1 <=1'b1;
		
		//update s counter once every 2 cycles
		S_counter <= S_counter+1'd1;
		
		if (write_s_twos_counter ==6'd6) row_dp_ram_s<=row_dp_ram_s+1'd1;
		else row_dp_ram_s<=row_dp_ram_s;
	
		S_0 <= S_0+Mult_M2_result_0;
		S_1 <= S_1+Mult_M2_result_1;
		S_2 <= S_2+Mult_M2_result_2;
		S_3 <= S_3+Mult_M2_result_3;
		
		// from CC1
		
		
		if (stop_fs_prime ==0) begin
		SRAM_address<= read_address_SRAM;
		Sample_counter<= Sample_counter+1'd1; 
		SRAM_we_n<=1;
		
		
		//fill in S76/Y2246 to location 0 on DPRAM 0
		address_s_prime_0 <=dram_address_counter_s_prime;
		dram_address_counter_s_prime<= dram_address_counter_s_prime+1'd1;
		write_s_prime_0<= {{16{SRAM_read_data[15]}}, SRAM_read_data[15:0]}; // Signed extension to 32-bits;;
		WE_s_prime_0<=1'd1;
		end
		
	
		
	

		/// Compute S
		ROW_ADDRESS_T<=ROW_ADDRESS_T+1'd1;
		address_T_0<= read_address_compute_S;
		WE_T_0 <=0;
		
		// c row c column
		Mult_M2_op_0_1<= read_data_T_0;
		Mult_M2_op_0_2<=C0;
		Mult_M2_op_1_1<=read_data_T_0;
		Mult_M2_op_1_2<=C1;
		Mult_M2_op_2_1<=read_data_T_0;
		Mult_M2_op_2_2<=C2;
		Mult_M2_op_3_1<=read_data_T_0;
		Mult_M2_op_3_2<=C3;
		mux_counter<= mux_counter+1'd1;
		
		S_0 <= S_0+Mult_M2_result_0;
		S_1 <= S_1+Mult_M2_result_1;
		S_2 <= S_2+Mult_M2_result_2;
		S_3 <= S_3+Mult_M2_result_3;
		
		
		//update s counter once every 2 cycles
		//S_counter <= S_counter+1'd1;
		
		M2_state<= S_CS_FS_CC_4;
	
		
		end
		
		S_CS_FS_CC_4: begin
			
		WE_S_0 <= 1'b0;
		WE_S_1 <=1'b0;
		
		if (stop_fs_prime ==0) begin
		SRAM_address<= read_address_SRAM;
		Sample_counter<= Sample_counter+1'd1; 
		SRAM_we_n<=1;
		
		//fill in S76/Y2246 to location 0 on DPRAM 0
		address_s_prime_0 <=dram_address_counter_s_prime;
		dram_address_counter_s_prime<= dram_address_counter_s_prime+1'd1;
		write_s_prime_0<= {{16{SRAM_read_data[15]}}, SRAM_read_data[15:0]}; // Signed extension to 32-bits;;
		WE_s_prime_0<=1'd1;
		
		
		
		
		end
		
		

		/// Compute S
		ROW_ADDRESS_T<=ROW_ADDRESS_T+1'd1;
		address_T_0<= read_address_compute_S;
		WE_T_0 <=0;
		
		// c row c column
		Mult_M2_op_0_1<= read_data_T_0;
		Mult_M2_op_0_2<=C0;
		Mult_M2_op_1_1<=read_data_T_0;
		Mult_M2_op_1_2<=C1;
		Mult_M2_op_2_1<=read_data_T_0;
		Mult_M2_op_2_2<=C2;
		Mult_M2_op_3_1<=read_data_T_0;
		Mult_M2_op_3_2<=C3;
		mux_counter<= mux_counter+1'd1;
		
		S_0 <= S_0+Mult_M2_result_0;
		S_1 <= S_1+Mult_M2_result_1;
		S_2 <= S_2+Mult_M2_result_2;
		S_3 <= S_3+Mult_M2_result_3;

		
		M2_state<= S_CS_FS_CC_5;
		if (S_counter== 16'd16) begin M2_state<=S_CS_FS_LO_0;
		S_counter<=0;
		end
		
		
		
		end
		
		S_CS_FS_CC_5: begin
		
		if (stop_fs_prime ==0) begin
		SRAM_address<= read_address_SRAM;
		Sample_counter<= Sample_counter+1'd1; 
		SRAM_we_n<=1;
		
		
		//fill in S76/Y2246 to location 0 on DPRAM 0
		address_s_prime_0 <=dram_address_counter_s_prime;
		dram_address_counter_s_prime<= dram_address_counter_s_prime+1'd1;
		write_s_prime_0<= {{16{SRAM_read_data[15]}}, SRAM_read_data[15:0]}; // Signed extension to 32-bits;;
		WE_s_prime_0<=1'd1;
		
		
		end
		
		
		

		/// Compute S
		ROW_ADDRESS_T<=ROW_ADDRESS_T+1'd1;
		address_T_0<= read_address_compute_S;
		WE_T_0 <=0;
		
		// c row c column
		Mult_M2_op_0_1<= read_data_T_0;
		Mult_M2_op_0_2<=C0;
		Mult_M2_op_1_1<=read_data_T_0;
		Mult_M2_op_1_2<=C1;
		Mult_M2_op_2_1<=read_data_T_0;
		Mult_M2_op_2_2<=C2;
		Mult_M2_op_3_1<=read_data_T_0;
		Mult_M2_op_3_2<=C3;
		mux_counter<= mux_counter+1'd1;
		
		S_0 <= S_0+Mult_M2_result_0;
		S_1 <= S_1+Mult_M2_result_1;
		S_2 <= S_2+Mult_M2_result_2;
		S_3 <= S_3+Mult_M2_result_3;
		
		
		
		M2_state<= S_CS_FS_CC_6;
		end
		S_CS_FS_CC_6: begin
		
		
		if (stop_fs_prime ==0) begin
		SRAM_address<= read_address_SRAM;
		Sample_counter<= Sample_counter+1'd1; 
		SRAM_we_n<=1;
		
		
		//fill in S76/Y2246 to location 0 on DPRAM 0
		address_s_prime_0 <=dram_address_counter_s_prime;
		dram_address_counter_s_prime<= dram_address_counter_s_prime+1'd1;
		write_s_prime_0<= {{16{SRAM_read_data[15]}}, SRAM_read_data[15:0]}; // Signed extension to 32-bits;;
		WE_s_prime_0<=1'd1;
		
		end
		
		

		/// Compute S
		ROW_ADDRESS_T<=ROW_ADDRESS_T+1'd1;
		address_T_0<= read_address_compute_S;
		WE_T_0 <=0;
		
		// c row c column
		Mult_M2_op_0_1<= read_data_T_0;
		Mult_M2_op_0_2<=C0;
		Mult_M2_op_1_1<=read_data_T_0;
		Mult_M2_op_1_2<=C1;
		Mult_M2_op_2_1<=read_data_T_0;
		Mult_M2_op_2_2<=C2;
		Mult_M2_op_3_1<=read_data_T_0;
		Mult_M2_op_3_2<=C3;
		mux_counter<= mux_counter+1'd1;
		
		S_0 <= S_0+Mult_M2_result_0;
		S_1 <= S_1+Mult_M2_result_1;
		S_2 <= S_2+Mult_M2_result_2;
		S_3 <= S_3+Mult_M2_result_3;
		
		// once sample counter stops you need to write to DP ram S' for 2 more CC's to finish writing all values.
		//64
		if (Sample_counter == 6'b111111) begin
			stop_fs_prime<=1'b1;
			last_write_s_prime<=1'b1;
		end 
		
		
		
		if(flag_increment_column == 1'd1) begin
		COL_ADDRESS_T<=COL_ADDRESS_T+1'd1;
		end
		
		
		M2_state<= S_CS_FS_CC_7;
		
		end
		
		
		
		S_CS_FS_CC_7: begin
		
		// check if write two's counter is 6 = 8 sent values then do odd even logic
		
		
		
		
		
		if (stop_fs_prime ==0) begin
		SRAM_address<= read_address_SRAM;
		Sample_counter<= Sample_counter+1'd1; 
		SRAM_we_n<=1;
		
		//fill in S76/Y2246 to location 0 on DPRAM 0
		address_s_prime_0 <=dram_address_counter_s_prime;
		dram_address_counter_s_prime<= dram_address_counter_s_prime+1'd1;
		write_s_prime_0<= {{16{SRAM_read_data[15]}}, SRAM_read_data[15:0]}; // Signed extension to 32-bits;;
		WE_s_prime_0<=1'd1;
		
		end
		if (last_write_s_prime ==1) begin
	
		
		//fill in S76/Y2246 to location 0 on DPRAM 0
		address_s_prime_0 <=dram_address_counter_s_prime;
		dram_address_counter_s_prime<= dram_address_counter_s_prime+1'd1;
		write_s_prime_0<= {{16{SRAM_read_data[15]}}, SRAM_read_data[15:0]}; // Signed extension to 32-bits;;
		WE_s_prime_0<=1'd1;
		
		end
		
		

		/// Compute S
		ROW_ADDRESS_T<=ROW_ADDRESS_T+1'd1;
		
		
		
		//COL_ADDRESS_T<=COL_ADDRESS_T+1'd1;
		address_T_0<= read_address_compute_S;
		WE_T_0 <=0;
		
		// c row c column
		Mult_M2_op_0_1<= read_data_T_0;
		Mult_M2_op_0_2<=C0;
		Mult_M2_op_1_1<=read_data_T_0;
		Mult_M2_op_1_2<=C1;
		Mult_M2_op_2_1<=read_data_T_0;
		Mult_M2_op_2_2<=C2;
		Mult_M2_op_3_1<=read_data_T_0;
		Mult_M2_op_3_2<=C3;
		mux_counter<= mux_counter+1'd1;
		
		S_0 <= S_0+Mult_M2_result_0;
		S_1 <= S_1+Mult_M2_result_1;
		S_2 <= S_2+Mult_M2_result_2;
		S_3 <= S_3+Mult_M2_result_3;
		
		
		
		M2_state<= S_CS_FS_CC_0;
		
		end

		S_CS_FS_LO_0: begin
		WE_S_0 <= 1'b0;
		WE_S_1 <=1'b0;
//			S_counter <= S_counter +1'd1;
//					// write to DP ram 
//			address_S_0<=DPRAM_0;
//
//			address_S_1<=DPRAM_1; 
//			write_S_0 <=(S_1>>>16);
//			write_S_1 <=(S_2>>>16);
//			// set to zero after writing
//			WE_S_0 <= 1'b1;
//			WE_S_1 <=1'b1;
//			
//		// update counter after last here
//		//S_counter <= S_counter+1'd1;
//		write_s_twos_counter <= write_s_twos_counter+2'd2;
		
		M2_state<=S_CS_FS_LO_2;
			
		
			
		
		end
		S_CS_FS_LO_2: begin
		
//			//S_counter <= S_counter +1'd1;
//					// write to DP ram 
//			address_S_0<=DPRAM_0;
//
//			address_S_1<=DPRAM_1; 
//			write_S_0 <=(S_2>>>16);
//			write_S_1 <=(S_3>>>16);
//			// set to zero after writing
//			WE_S_0 <= 1'b1;
//			WE_S_1 <=1'b1;
//		
		// update counter after last here
		//S_counter <= S_counter+1'd1;
			WE_s_prime_0<=1'd1;
			// reach 64 and reset to zero and also reset DPRAM for S' to prepare for CT reads starting at zero
			Sample_counter<=0;
			dram_address_counter_s_prime<=0;
			row_index_DPRAM_S_Prime<=0;
			C_multiplier_row<= 0;
			flag_increment_row<=0;
			flag_increment_column<=0;
			col_index_DPRAM_S_Prime<=0;
	
			M2_state<=S_WS_CT_LI_0;	
			
			
			
			// INCREMENT BLOCKS READ
			
		column_block <= column_block+1'd1;
		blocks_read <= blocks_read+1'd1;
		//enclosed IF based on the flag 
		// if (Y)
		// else do UV
		// last write needs to go to ONLY WRITE STATE NOT YET IMPLEMENTED incode change 3 blocks of code and assign statements
		// hit  go to Y
		// hit 600 go to U
		
		if (Y_flag_read) begin
		
			if (column_block == 6'd39) begin
				row_block <= row_block +1'd1;
				column_block<=0;
			end
		
			if ((row_block == 5'd29) && (column_block == 6'd39)) begin
			row_block <= 0;
			column_block<=0;
			end	
		
		end
		
		else begin
		
			if (column_block == 6'd19) begin
				row_block <= row_block +1'd1;
				column_block<=0;
			
			end
		
			if ((row_block == 5'd29) && (column_block == 6'd19)) begin
			row_block <= 0;
			column_block<=0;
			end
		
		
		
		
		
		
		end
			
			
			
			
			
			
		end
		
	
		S_WS_CT_LI_0: begin
		
		
		/// READ S DP SRAM
		address_S_0<=DPRAM_S_READ_COUNTER;
		address_S_1<=DPRAM_S_READ_COUNTER+1'd1;
		WE_S_0<=0;
		WE_S_1<=0;
		DPRAM_S_READ_COUNTER<=DPRAM_S_READ_COUNTER+2'd2;
			//  brand new
		T_0<= 0;
		T_1<=0;
		T_2<= 0;
		T_3<= 0;
		mux_counter<=0;
		
		
		
		
		
	
		/// COMPUTE T
		address_s_prime_0 <=read_address_compute_T+dram_address_counter_s_prime;
		//dram_address_counter_s_prime<= dram_address_counter_s_prime+1'd1;
		Sample_counter<= Sample_counter+1'd1; 
		WE_s_prime_0<=1'd0;
		// column must increment 
		col_index_DPRAM_S_Prime<= col_index_DPRAM_S_Prime+1'd1;
		// column must increment 
		
		// increment row/column -> in this case would be?
		C_multiplier_row<= C_multiplier_row;
		
		Write_Sample_counter<=0;
		SRAM_address<=0;
		SRAM_write_data<=0;
		
		M2_state<= S_WS_CT_LI_1;
		end
		
		
		S_WS_CT_LI_1: begin
		
				/// READ S DP SRAM
		address_S_0<=DPRAM_S_READ_COUNTER;
		address_S_1<=DPRAM_S_READ_COUNTER+1'd1;
		WE_S_0<=0;
		WE_S_1<=0;
		DPRAM_S_READ_COUNTER<=DPRAM_S_READ_COUNTER+2'd2;
		
		
		//compute T
		address_s_prime_0 <=read_address_compute_T;
		
		// column must increment 
		col_index_DPRAM_S_Prime<= col_index_DPRAM_S_Prime+1'd1;
		
		Sample_counter<= Sample_counter+1'd1; 
		WE_s_prime_0<=1'd0;
		
		// increment row/column -> in this case would be?
		C_multiplier_row<= C_multiplier_row;

		
		
	
		
		M2_state<= S_WS_CT_LI_2;
		end
		
		
		
		S_WS_CT_LI_2: begin
		
		/// READ S DP SRAM
		address_S_0<=DPRAM_S_READ_COUNTER;
		address_S_1<=DPRAM_S_READ_COUNTER+1'd1;
		WE_S_0<=0;
		WE_S_1<=0;
		DPRAM_S_READ_COUNTER<=DPRAM_S_READ_COUNTER+2'd2;
		
		
		// WRITE TO SRAM 
		SRAM_address<=write_address_SRAM;
		SRAM_write_data<= {MSB,LSB};
		SRAM_we_n <= 0;
		Write_Sample_counter <=Write_Sample_counter+1'd1;
		
		
		
		
		//COMPUTE T
		address_s_prime_0 <=read_address_compute_T;
		
		
		// column must increment 
		col_index_DPRAM_S_Prime<= col_index_DPRAM_S_Prime+1'd1;
		
		
		Sample_counter<= Sample_counter+1'd1; 
		WE_s_prime_0<=1'd0;
		
		
		//MULTIPLIERS
		// c row c column
		Mult_M2_op_0_1<= read_data_s_prime_0;
		Mult_M2_op_0_2<=C0;
		Mult_M2_op_1_1<=read_data_s_prime_0;
		Mult_M2_op_1_2<=C1;
		Mult_M2_op_2_1<=read_data_s_prime_0;
		Mult_M2_op_2_2<=C2;
		Mult_M2_op_3_1<=read_data_s_prime_0;
		Mult_M2_op_3_2<=C3;
		
		mux_counter<= mux_counter+1'd1;
		// once read one column then update C index
		
		C_multiplier_row<= C_multiplier_row+1'd1;
		
		
		
		
		
	
		M2_state<= S_WS_CT_LI_3;
		end
		
		S_WS_CT_LI_3: begin
		
		///
		/// READ S DP SRAM
		address_S_0<=DPRAM_S_READ_COUNTER;
		address_S_1<=DPRAM_S_READ_COUNTER+1'd1;
		WE_S_0<=0;
		WE_S_1<=0;
		DPRAM_S_READ_COUNTER<=DPRAM_S_READ_COUNTER+2'd2;
		
		
		// WRITE TO SRAM 
		SRAM_address<=write_address_SRAM;
		SRAM_write_data<= {MSB,LSB};
		SRAM_we_n <= 0;
		Write_Sample_counter <=Write_Sample_counter+1'd1;
		
	
		//COMPUTE T
		// column must increment 
		col_index_DPRAM_S_Prime<= col_index_DPRAM_S_Prime+1'd1;
		
		
		address_s_prime_0 <=read_address_compute_T;
		
		Sample_counter<= Sample_counter+1'd1; 
		WE_s_prime_0<=1'd0;
		
		
		//MULTIPLIERS
		// c row c column
		Mult_M2_op_0_1<= read_data_s_prime_0;
		Mult_M2_op_0_2<=C0;
		Mult_M2_op_1_1<=read_data_s_prime_0;
		Mult_M2_op_1_2<=C1;
		Mult_M2_op_2_1<=read_data_s_prime_0;
		Mult_M2_op_2_2<=C2;
		Mult_M2_op_3_1<=read_data_s_prime_0;
		Mult_M2_op_3_2<=C3;
		
		mux_counter<= mux_counter+1'd1;
		// once read one column then update C index
		
		C_multiplier_row<= C_multiplier_row+1'd1;
		//  fill in T values into locaitons
		T_0<= Mult_M2_result_0;
		T_1<= Mult_M2_result_1;
		T_2<= Mult_M2_result_2;
		T_3<= Mult_M2_result_3;
	
	
		
		M2_state<= S_WS_CT_LI_4;
		end
		
		S_WS_CT_LI_4: begin
		
		
		/// READ S DP SRAM
		address_S_0<=DPRAM_S_READ_COUNTER;
		address_S_1<=DPRAM_S_READ_COUNTER+1'd1;
		WE_S_0<=0;
		WE_S_1<=0;
		DPRAM_S_READ_COUNTER<=DPRAM_S_READ_COUNTER+2'd2;
		
		
		// WRITE TO SRAM 
		SRAM_address<=write_address_SRAM;
		SRAM_write_data<= {MSB,LSB};
		SRAM_we_n <= 0;
		Write_Sample_counter <=Write_Sample_counter+1'd1;
		
		//compute T
		// column must increment 
		col_index_DPRAM_S_Prime<= col_index_DPRAM_S_Prime+1'd1;
		
		address_s_prime_0 <=read_address_compute_T;
		Sample_counter<= Sample_counter+1'd1; 
		WE_s_prime_0<=1'd0;
		
		
		//MULTIPLIERS
		// c row c column
		Mult_M2_op_0_1<= read_data_s_prime_0;
		Mult_M2_op_0_2<=C0;
		Mult_M2_op_1_1<=read_data_s_prime_0;
		Mult_M2_op_1_2<=C1;
		Mult_M2_op_2_1<=read_data_s_prime_0;
		Mult_M2_op_2_2<=C2;
		Mult_M2_op_3_1<=read_data_s_prime_0;
		Mult_M2_op_3_2<=C3;
		
		mux_counter<= mux_counter+1'd1;
		// once read one column then update C index
		
		C_multiplier_row<= C_multiplier_row+1'd1;
		//  fill in T values into locaitons
		T_0<= T_0+ Mult_M2_result_0;
		T_1<= T_1+Mult_M2_result_1;
		T_2<= T_2+Mult_M2_result_2;
		T_3<= T_3+Mult_M2_result_3;
		
		
		
		address_s_prime_0 <=read_address_compute_T;
		Sample_counter<= Sample_counter+1'd1; 
		WE_s_prime_0<=1'd0;
		
		
		//MULTIPLIERS
		// c row c column
		Mult_M2_op_0_1<= read_data_s_prime_0;
		Mult_M2_op_0_2<=C0;
		Mult_M2_op_1_1<=read_data_s_prime_0;
		Mult_M2_op_1_2<=C1;
		Mult_M2_op_2_1<=read_data_s_prime_0;
		Mult_M2_op_2_2<=C2;
		Mult_M2_op_3_1<=read_data_s_prime_0;
		Mult_M2_op_3_2<=C3;
		mux_counter<= mux_counter+1'd1;
		// once read one column then update C index
		
		C_multiplier_row<= C_multiplier_row+1'd1;
			//  fill in T values into locaitons
		T_0<= T_0+ Mult_M2_result_0;
		T_1<= T_1+Mult_M2_result_1;
		T_2<= T_2+Mult_M2_result_2;
		T_3<= T_3+Mult_M2_result_3;
		

		M2_state<= S_WS_CT_LI_5;
		end
		
		S_WS_CT_LI_5: begin
		
		
		/// READ S DP SRAM
		address_S_0<=DPRAM_S_READ_COUNTER;
		address_S_1<=DPRAM_S_READ_COUNTER+1'd1;
		WE_S_0<=0;
		WE_S_1<=0;
		DPRAM_S_READ_COUNTER<=DPRAM_S_READ_COUNTER+2'd2;
		
		
		// WRITE TO SRAM 
		SRAM_address<=write_address_SRAM;
		SRAM_write_data<= {MSB,LSB};
		SRAM_we_n <= 0;
		Write_Sample_counter <=Write_Sample_counter+1'd1;
		
		
		
		//COMPUTE T
		// column must increment 
		col_index_DPRAM_S_Prime<= col_index_DPRAM_S_Prime+1'd1;
		
		address_s_prime_0 <=read_address_compute_T;
		Sample_counter<= Sample_counter+1'd1; 
		WE_s_prime_0<=1'd0;
		
		
		//MULTIPLIERS
		// c row c column
		Mult_M2_op_0_1<= read_data_s_prime_0;
		Mult_M2_op_0_2<=C0;
		Mult_M2_op_1_1<=read_data_s_prime_0;
		Mult_M2_op_1_2<=C1;
		Mult_M2_op_2_1<=read_data_s_prime_0;
		Mult_M2_op_2_2<=C2;
		Mult_M2_op_3_1<=read_data_s_prime_0;
		Mult_M2_op_3_2<=C3;
		mux_counter<= mux_counter+1'd1;
		// once read one column then update C index
		
		C_multiplier_row<= C_multiplier_row+1'd1;
			//  fill in T values into locaitons
		T_0<= T_0+ Mult_M2_result_0;
		T_1<= T_1+Mult_M2_result_1;
		T_2<= T_2+Mult_M2_result_2;
		T_3<= T_3+Mult_M2_result_3;

		
		M2_state<= S_WS_CT_LI_6;
		end
		
		S_WS_CT_LI_6: begin
		
		
		/// READ S DP SRAM
		address_S_0<=DPRAM_S_READ_COUNTER;
		address_S_1<=DPRAM_S_READ_COUNTER+1'd1;
		WE_S_0<=0;
		WE_S_1<=0;
		DPRAM_S_READ_COUNTER<=DPRAM_S_READ_COUNTER+2'd2;
		
		
		// WRITE TO SRAM 
		SRAM_address<=write_address_SRAM;
		SRAM_write_data<= {MSB,LSB};
		SRAM_we_n <= 0;
		Write_Sample_counter <=Write_Sample_counter+1'd1;
		
		
		
		
		
		// COMPUTE T
		// column must increment 
		col_index_DPRAM_S_Prime<= col_index_DPRAM_S_Prime+1'd1;
		address_s_prime_0 <=read_address_compute_T;
		
		Sample_counter<= Sample_counter+1'd1; 
		WE_s_prime_0<=1'd0;
		
		
		//MULTIPLIERS
		// c row c column
		Mult_M2_op_0_1<= read_data_s_prime_0;
		Mult_M2_op_0_2<=C0;
		Mult_M2_op_1_1<=read_data_s_prime_0;
		Mult_M2_op_1_2<=C1;
		Mult_M2_op_2_1<=read_data_s_prime_0;
		Mult_M2_op_2_2<=C2;
		Mult_M2_op_3_1<=read_data_s_prime_0;
		Mult_M2_op_3_2<=C3;
		mux_counter<= mux_counter+1'd1;
		// once read one column then update C index
		
		C_multiplier_row<= C_multiplier_row+1'd1;
		//  fill in T values into locaitons
		T_0<= T_0+ Mult_M2_result_0;
		T_1<= T_1+Mult_M2_result_1;
		T_2<= T_2+Mult_M2_result_2;
		T_3<= T_3+Mult_M2_result_3;
		
		M2_state<= S_WS_CT_LI_7;
		end
		
		S_WS_CT_LI_7: begin
		
		/// READ S DP SRAM
		address_S_0<=DPRAM_S_READ_COUNTER;
		address_S_1<=DPRAM_S_READ_COUNTER+1'd1;
		WE_S_0<=0;
		WE_S_1<=0;
		DPRAM_S_READ_COUNTER<=DPRAM_S_READ_COUNTER+2'd2;
		
		
		// WRITE TO SRAM 
		SRAM_address<=write_address_SRAM;
		SRAM_write_data<= {MSB,LSB};
		SRAM_we_n <= 0;
		Write_Sample_counter <=Write_Sample_counter+1'd1;
		
		
		
		//COMPUTE T
		// column must increment 
		col_index_DPRAM_S_Prime<= col_index_DPRAM_S_Prime+1'd1;
		
		
		address_s_prime_0 <=read_address_compute_T;
		Sample_counter<= Sample_counter+1'd1; 
		WE_s_prime_0<=1'd0;
		
		
		//MULTIPLIERS
		// c row c column
		Mult_M2_op_0_1<= read_data_s_prime_0;
		Mult_M2_op_0_2<=C0;
		Mult_M2_op_1_1<=read_data_s_prime_0;
		Mult_M2_op_1_2<=C1;
		Mult_M2_op_2_1<=read_data_s_prime_0;
		Mult_M2_op_2_2<=C2;
		Mult_M2_op_3_1<=read_data_s_prime_0;
		Mult_M2_op_3_2<=C3;
		mux_counter<= mux_counter+1'd1;
		// once read one column then update C index
		
		C_multiplier_row<= C_multiplier_row+1'd1;
			//  fill in T values into locaitons
		T_0<= T_0+ Mult_M2_result_0;
		T_1<= T_1+Mult_M2_result_1;
		T_2<= T_2+Mult_M2_result_2;
		T_3<= T_3+Mult_M2_result_3;

		
		M2_state<= S_WS_CT_LI_8;
		end
		
		
		S_WS_CT_LI_8: begin
		
		
		/// READ S DP SRAM
		address_S_0<=DPRAM_S_READ_COUNTER;
		address_S_1<=DPRAM_S_READ_COUNTER+1'd1;
		WE_S_0<=0;
		WE_S_1<=0;
		DPRAM_S_READ_COUNTER<=DPRAM_S_READ_COUNTER+2'd2;
		
		
		// WRITE TO SRAM 
		SRAM_address<=write_address_SRAM;
		SRAM_write_data<= {MSB,LSB};
		SRAM_we_n <= 0;
		Write_Sample_counter <=Write_Sample_counter+1'd1;
		
		
		
		
		
		//COMPUTE T
		// RESET TO ZERO IN CT_7 from lead in case.
		// column must increment 
		col_index_DPRAM_S_Prime<= col_index_DPRAM_S_Prime+1'd1;
		
		address_s_prime_0 <=read_address_compute_T;
		Sample_counter<= Sample_counter+1'd1; 
		WE_s_prime_0<=1'd0;
		
		
		//MULTIPLIERS
		// c row c column
		Mult_M2_op_0_1<= read_data_s_prime_0;
		Mult_M2_op_0_2<=C0;
		Mult_M2_op_1_1<=read_data_s_prime_0;
		Mult_M2_op_1_2<=C1;
		Mult_M2_op_2_1<=read_data_s_prime_0;
		Mult_M2_op_2_2<=C2;
		Mult_M2_op_3_1<=read_data_s_prime_0;
		Mult_M2_op_3_2<=C3;
		mux_counter<= mux_counter+1'd1;
		// once read one column then update C index
		
		C_multiplier_row<= C_multiplier_row+1'd1;
			//  fill in T values into locaitons
		T_0<= T_0+ Mult_M2_result_0;
		T_1<= T_1+Mult_M2_result_1;
		T_2<= T_2+Mult_M2_result_2;
		T_3<= T_3+Mult_M2_result_3;
		
	
		
		M2_state<= S_WS_CT_LI_9;
		end
		
		S_WS_CT_LI_9: begin
		
		/// READ S DP SRAM
		address_S_0<=DPRAM_S_READ_COUNTER;
		address_S_1<=DPRAM_S_READ_COUNTER+1'd1;
		WE_S_0<=0;
		WE_S_1<=0;
		DPRAM_S_READ_COUNTER<=DPRAM_S_READ_COUNTER+2'd2;
		
		
		// WRITE TO SRAM 
		SRAM_address<=write_address_SRAM;
		SRAM_write_data<= {MSB,LSB};
		SRAM_we_n <= 0;
		Write_Sample_counter <=Write_Sample_counter+1'd1;
		
		
		
		
		
		//compute T
		// column must increment 
		col_index_DPRAM_S_Prime<= col_index_DPRAM_S_Prime+1'd1;
		
		address_s_prime_0 <=read_address_compute_T;	
		Sample_counter<= Sample_counter+1'd1; 
		WE_s_prime_0<=1'd0;
		
		
		//MULTIPLIERS
		// c row c column
		Mult_M2_op_0_1<= read_data_s_prime_0;
		Mult_M2_op_0_2<=C0;
		Mult_M2_op_1_1<=read_data_s_prime_0;
		Mult_M2_op_1_2<=C1;
		Mult_M2_op_2_1<=read_data_s_prime_0;
		Mult_M2_op_2_2<=C2;
		Mult_M2_op_3_1<=read_data_s_prime_0;
		Mult_M2_op_3_2<=C3;
		mux_counter<= mux_counter+1'd1;
		// once read one column then update C index
		
	
		// RESET TO ZERO
		C_multiplier_row<= 0;
		//  fill in T values into locaitons
			//  fill in T values into locaitons
		T_0<= T_0+ Mult_M2_result_0;
		T_1<= T_1+Mult_M2_result_1;
		T_2<= T_2+Mult_M2_result_2;
		T_3<= T_3+Mult_M2_result_3;
		
		if (FS_CC_transition==1)C_multiplier_column<=6'd4;
		FS_CC_transition<=0;
		if (c_index_3 == 16'd59) FS_CC_transition<=1;
		
	

	
		M2_state<= S_WS_CT_CC_0;
		end
		
		S_WS_CT_CC_0: begin
		
		
		if (stop_write_S_SRAM==1'b0) begin
		/// READ S DP SRAM
		address_S_0<=DPRAM_S_READ_COUNTER;
		address_S_1<=DPRAM_S_READ_COUNTER+1'd1;
		WE_S_0<=0;
		WE_S_1<=0;
		DPRAM_S_READ_COUNTER<=DPRAM_S_READ_COUNTER+2'd2;
		
		
		// WRITE TO SRAM 
		SRAM_address<=write_address_SRAM;
		SRAM_write_data<= {MSB,LSB};
		SRAM_we_n <= 0;
		Write_Sample_counter <=Write_Sample_counter+1'd1;
		end
		
		col_index_DPRAM_S_Prime<= col_index_DPRAM_S_Prime+1'd1;
		
		address_s_prime_0 <=read_address_compute_T;
		Sample_counter<= Sample_counter+1'd1; 
	
		 
		// TO BE CHANGED
		M2_state<= S_WS_CT_CC_1;
		if (dram_address_counter_T == 16'd64) M2_state<=S_CC_CT_LO_1;	
		
		// instead of going to L0 we need to go to Final Write S 
		//VG
		// set Y flag to 0 when hit 1200 and Set U flag similarly when we hit 600 set V flag and set U flag 0
		if (blocks_read == 12'd1200) begin
			Y_flag_read <=0;
			U_flag_read<=1;
			//V_flag_read<=0;
		end
		if (blocks_read == 12'd1800) begin
			Y_flag_read <=0;
			U_flag_read<=0;
			//V_flag_read<=0;
		end
//		if (blocks_read == 12'd2401) begin
//		/// go to special write S
//		//
//		M2_state<= S_LAST_WRITE_LI_0;
//		
//		final_write_S_flag <=1'b1;
//		end
//		
		
		
		//do samething for write
		
		if (blocks_written == 12'd1200) begin
			Y_flag_write <=0;
			U_flag_write<=1;
		//	V_flag_write<=0;
		end
		if (blocks_written == 12'd1800) begin
			Y_flag_write<=0;
			U_flag_write<=0;
		//	V_flag_write<=0;
		end
		if (blocks_written == 12'd2400) begin
		/// go to special write S
		//
		M2_state<= S_LAST_WRITE_LO_0;
		
		final_write_S_flag <=1'b1;
		end
		
		flag_increment_row <= ~flag_increment_row;
		
		C_multiplier_row <= C_multiplier_row+1;
		
		//MULTIPLIERS
		// c row c column
		Mult_M2_op_0_1<= read_data_s_prime_0;
		Mult_M2_op_0_2<=C0;
		Mult_M2_op_1_1<=read_data_s_prime_0;
		Mult_M2_op_1_2<=C1;
		Mult_M2_op_2_1<=read_data_s_prime_0;
		Mult_M2_op_2_2<=C2;
		Mult_M2_op_3_1<=read_data_s_prime_0;
		Mult_M2_op_3_2<=C3;
		mux_counter<= mux_counter+1'd1;
		
		//  READY HERE
		T_0<= T_0+Mult_M2_result_0;
		T_1<= T_1+Mult_M2_result_1;
		T_2<= T_2+Mult_M2_result_2;
		T_3<= T_3+Mult_M2_result_3;
		
		if (Write_Sample_counter == 6'd32) begin
		
		stop_write_S_SRAM <=1'd1;
		SRAM_we_n<=1;
		
		
		// do logic here to increment WRITE BLOCK BY ONE AFTER WE HAVE FINISHED ONE WRITE
			//M2_done<=1;
			// THINK ABOUT THIS IN DETAIL AFTER
			//IMPORTANT UPDATE ROW COUNTER OR COLUMN BLOCK
			write_column_block <= write_column_block+1'd1;
			blocks_written <= blocks_written+1'd1;
			
			
			
			if(Y_flag_write) begin
			
						// if not Y its gonan be U AND V then roll over at column = 19)
				if (write_column_block == 6'd39) begin
				write_row_block <= write_row_block +1'd1;
				write_column_block<=0;
				end

				if ((write_row_block == 5'd29) && (write_column_block == 6'd39)) begin
				write_row_block <= 0;
				write_column_block<=0;
			
				end	
				
			
			
			end
			
			else begin
			
						// if not Y its gonan be U AND V then roll over at column = 19)
				if (write_column_block == 6'd19) begin
				write_row_block <= write_row_block +1'd1;
				write_column_block<=0;
				end

				if ((write_row_block == 5'd29) && (write_column_block == 6'd19)) begin
				write_row_block <= 0;
				write_column_block<=0;
			
				end	
				
			
			
			
			end
			
		
		
		
		end	
	
		
		end
		
		
		S_WS_CT_CC_1: begin
		
		if (stop_write_S_SRAM==1'b0) begin
		/// READ S DP SRAM
		address_S_0<=DPRAM_S_READ_COUNTER;
		address_S_1<=DPRAM_S_READ_COUNTER+1'd1;
		WE_S_0<=0;
		WE_S_1<=0;
		DPRAM_S_READ_COUNTER<=DPRAM_S_READ_COUNTER+2'd2;
		
		
		// WRITE TO SRAM 
		SRAM_address<=write_address_SRAM;
		SRAM_write_data<= {MSB,LSB};
		SRAM_we_n <= 0;
		Write_Sample_counter <=Write_Sample_counter+1'd1;
		end
		//compute T
		
		col_index_DPRAM_S_Prime<= col_index_DPRAM_S_Prime+1'd1;
		
		address_s_prime_0 <=read_address_compute_T;
		
		Sample_counter<= Sample_counter+1'd1; 
//		WE_s_prime_0<=1'd0;
//		
//		
//		
//		// write to DPRAM_T write 2 values at once
//		dram_address_counter_T<= dram_address_counter_T+1'd1;
//		address_T_0<=dram_address_counter_T;
//		address_T_1<=dram_address_counter_T+1'd1;
//		write_T_0<=T_0;
//		write_T_1<=T_1;
//		WE_T_0<=1'd1;
//		WE_T_1<=1'd1;
		
			
		address_s_prime_0 <=read_address_compute_T+dram_address_counter_s_prime;
		//dram_address_counter_s_prime<= dram_address_counter_s_prime+1'd1;
		Sample_counter<= Sample_counter+1'd1; 
		WE_s_prime_0<=1'd0;
		
		
		// write to DPRAM_T write 2 values at once COUNTER GOES UP BY +2
		dram_address_counter_T<= dram_address_counter_T+2'd2;
		
		C_multiplier_row <= C_multiplier_row+1;
	
		address_T_0<=dram_address_counter_T;
		address_T_1<=dram_address_counter_T+1'd1;
		write_T_0<=T_0>>>8;
		write_T_1<=T_1>>>8;
		WE_T_0<=1'd1;
		WE_T_1<=1'd1;
		
		// BUFFER VALUES FOR NEXT WRITE BUT ALSO COMPUTE NEW VALUES AT THE SAME TIME
		T_2_BUF<= T_2;
		T_3_BUF<= T_3;
	
		
		
		
		//MULTIPLIERS
		// c row c column
		Mult_M2_op_0_1<= read_data_s_prime_0;
		Mult_M2_op_0_2<=C0;
		Mult_M2_op_1_1<=read_data_s_prime_0;
		Mult_M2_op_1_2<=C1;
		Mult_M2_op_2_1<=read_data_s_prime_0;
		Mult_M2_op_2_2<=C2;
		Mult_M2_op_3_1<=read_data_s_prime_0;
		Mult_M2_op_3_2<=C3;
		mux_counter<= mux_counter+1'd1;
		
		//  brand new
		T_0<= Mult_M2_result_0;
		T_1<= Mult_M2_result_1;
		T_2<= Mult_M2_result_2;
		T_3<= Mult_M2_result_3;
		
		
		
		
		
		M2_state<= S_WS_CT_CC_2;
		end
		
		S_WS_CT_CC_2: begin
		
		
		if (stop_write_S_SRAM==1'b0) begin
		/// READ S DP SRAM
		address_S_0<=DPRAM_S_READ_COUNTER;
		address_S_1<=DPRAM_S_READ_COUNTER+1'd1;
		WE_S_0<=0;
		WE_S_1<=0;
		DPRAM_S_READ_COUNTER<=DPRAM_S_READ_COUNTER+2'd2;
		
		
		// WRITE TO SRAM 
		SRAM_address<=write_address_SRAM;
		SRAM_write_data<= {MSB,LSB};
		SRAM_we_n <= 0;
		Write_Sample_counter <=Write_Sample_counter+1'd1;
		end
		//compute T
		col_index_DPRAM_S_Prime<= col_index_DPRAM_S_Prime+1'd1;
		
		address_s_prime_0 <=read_address_compute_T;
		//dram_address_counter_s_prime<= dram_address_counter_s_prime+1'd1;
		Sample_counter<= Sample_counter+1'd1; 
		WE_s_prime_0<=1'd0;
		
		
		C_multiplier_row <= C_multiplier_row+1;
		// write to DPRAM_T write 2 values at once
		dram_address_counter_T<= dram_address_counter_T+2'd2;
		address_T_0<=dram_address_counter_T;
		address_T_1<=dram_address_counter_T+1'd1;
		write_T_0<=T_2_BUF>>>8;
		write_T_1<=T_3_BUF>>>8;
		WE_T_0<=1'd1;
		WE_T_1<=1'd1;
		

		
		
		
		//MULTIPLIERS
		// c row c column
		Mult_M2_op_0_1<= read_data_s_prime_0;
		Mult_M2_op_0_2<=C0;
		Mult_M2_op_1_1<=read_data_s_prime_0;
		Mult_M2_op_1_2<=C1;
		Mult_M2_op_2_1<=read_data_s_prime_0;
		Mult_M2_op_2_2<=C2;
		Mult_M2_op_3_1<=read_data_s_prime_0;
		Mult_M2_op_3_2<=C3;
		
		mux_counter<= mux_counter+1'd1;

		T_0<= T_0+Mult_M2_result_0;
		T_1<= T_1+Mult_M2_result_1;
		T_2<= T_2+Mult_M2_result_2;
		T_3<= T_3+Mult_M2_result_3;
		
		
		M2_state<= S_WS_CT_CC_3;
		end
		
		
		S_WS_CT_CC_3: begin
		
		if (stop_write_S_SRAM==1'b0) begin
		/// READ S DP SRAM
		address_S_0<=DPRAM_S_READ_COUNTER;
		address_S_1<=DPRAM_S_READ_COUNTER+1'd1;
		WE_S_0<=0;
		WE_S_1<=0;
		DPRAM_S_READ_COUNTER<=DPRAM_S_READ_COUNTER+2'd2;
		
		
		// WRITE TO SRAM 
		SRAM_address<=write_address_SRAM;
		SRAM_write_data<= {MSB,LSB};
		SRAM_we_n <= 0;
		Write_Sample_counter <=Write_Sample_counter+1'd1;
		end
		//compute T
		col_index_DPRAM_S_Prime<= col_index_DPRAM_S_Prime+1'd1;
		// ALWAYS AFTER WRITING RESET THE WE EN TO 0 TO ENSURE NO CORRUPTION 
		WE_T_0<=1'd0;
		WE_T_1<=1'd0;
		
		C_multiplier_row <= C_multiplier_row+1;
		address_s_prime_0 <=read_address_compute_T;
		Sample_counter<= Sample_counter+1'd1; 
		WE_s_prime_0<=1'd0;
		
		
				
		//MULTIPLIERS
		// c row c column
		Mult_M2_op_0_1<= read_data_s_prime_0;
		Mult_M2_op_0_2<=C0;
		Mult_M2_op_1_1<=read_data_s_prime_0;
		Mult_M2_op_1_2<=C1;
		Mult_M2_op_2_1<=read_data_s_prime_0;
		Mult_M2_op_2_2<=C2;
		Mult_M2_op_3_1<=read_data_s_prime_0;
		Mult_M2_op_3_2<=C3;
		
		mux_counter<= mux_counter+1'd1;

		T_0<= T_0+Mult_M2_result_0;
		T_1<= T_1+Mult_M2_result_1;
		T_2<= T_2+Mult_M2_result_2;
		T_3<= T_3+Mult_M2_result_3;
		
		
		M2_state<= S_WS_CT_CC_4;
		end
		
		S_WS_CT_CC_4: begin
		
		
		if (stop_write_S_SRAM==1'b0) begin
		/// READ S DP SRAM
		address_S_0<=DPRAM_S_READ_COUNTER;
		address_S_1<=DPRAM_S_READ_COUNTER+1'd1;
		WE_S_0<=0;
		WE_S_1<=0;
		DPRAM_S_READ_COUNTER<=DPRAM_S_READ_COUNTER+2'd2;
		
		
		// WRITE TO SRAM 
		SRAM_address<=write_address_SRAM;
		SRAM_write_data<= {MSB,LSB};
		SRAM_we_n <= 0;
		Write_Sample_counter <=Write_Sample_counter+1'd1;
		end
		//compute T
		col_index_DPRAM_S_Prime<= col_index_DPRAM_S_Prime+1'd1;
		// ALWAYS AFTER WRITING RESET THE WE EN TO 0 TO ENSURE NO CORRUPTION 
		WE_T_0<=1'd0;
		WE_T_1<=1'd0;
		
		
		address_s_prime_0 <=read_address_compute_T;
		
		Sample_counter<= Sample_counter+1'd1; 
		WE_s_prime_0<=1'd0;
		
		
		C_multiplier_row <= C_multiplier_row+1;		
		//MULTIPLIERS
		// c row c column
		Mult_M2_op_0_1<= read_data_s_prime_0;
		Mult_M2_op_0_2<=C0;
		Mult_M2_op_1_1<=read_data_s_prime_0;
		Mult_M2_op_1_2<=C1;
		Mult_M2_op_2_1<=read_data_s_prime_0;
		Mult_M2_op_2_2<=C2;
		Mult_M2_op_3_1<=read_data_s_prime_0;
		Mult_M2_op_3_2<=C3;
		
		mux_counter<= mux_counter+1'd1;

		T_0<= T_0+Mult_M2_result_0;
		T_1<= T_1+Mult_M2_result_1;
		T_2<= T_2+Mult_M2_result_2;
		T_3<= T_3+Mult_M2_result_3;
		
		
		M2_state<= S_WS_CT_CC_5;
		end
		
		S_WS_CT_CC_5: begin
		
		if (stop_write_S_SRAM==1'b0) begin
		/// READ S DP SRAM
		address_S_0<=DPRAM_S_READ_COUNTER;
		address_S_1<=DPRAM_S_READ_COUNTER+1'd1;
		WE_S_0<=0;
		WE_S_1<=0;
		DPRAM_S_READ_COUNTER<=DPRAM_S_READ_COUNTER+2'd2;
		
		
		// WRITE TO SRAM 
		SRAM_address<=write_address_SRAM;
		SRAM_write_data<= {MSB,LSB};
		SRAM_we_n <= 0;
		Write_Sample_counter <=Write_Sample_counter+1'd1;
		end
		//compute T
		col_index_DPRAM_S_Prime<= col_index_DPRAM_S_Prime+1'd1;
		// ALWAYS AFTER WRITING RESET THE WE EN TO 0 TO ENSURE NO CORRUPTION 
		WE_T_0<=1'd0;
		WE_T_1<=1'd0;
		
		
		address_s_prime_0 <=read_address_compute_T;
		Sample_counter<= Sample_counter+1'd1; 
		WE_s_prime_0<=1'd0;
		
		C_multiplier_row <= C_multiplier_row+1;
				
		//MULTIPLIERS
		// c row c column
		Mult_M2_op_0_1<= read_data_s_prime_0;
		Mult_M2_op_0_2<=C0;
		Mult_M2_op_1_1<=read_data_s_prime_0;
		Mult_M2_op_1_2<=C1;
		Mult_M2_op_2_1<=read_data_s_prime_0;
		Mult_M2_op_2_2<=C2;
		Mult_M2_op_3_1<=read_data_s_prime_0;
		Mult_M2_op_3_2<=C3;
		
		mux_counter<= mux_counter+1'd1;

		T_0<= T_0+Mult_M2_result_0;
		T_1<= T_1+Mult_M2_result_1;
		T_2<= T_2+Mult_M2_result_2;
		T_3<= T_3+Mult_M2_result_3;
		
			//special case
		//logic for incrementing row counter for C
		if (flag_increment_row==1'b1)begin
		row_index_DPRAM_S_Prime<= row_index_DPRAM_S_Prime+1'd1;	
		end
		
		
		
		M2_state<= S_WS_CT_CC_6;
		end
		
		S_WS_CT_CC_6: begin
		
		if (stop_write_S_SRAM==1'b0) begin
		/// READ S DP SRAM
		address_S_0<=DPRAM_S_READ_COUNTER;
		address_S_1<=DPRAM_S_READ_COUNTER+1'd1;
		WE_S_0<=0;
		WE_S_1<=0;
		DPRAM_S_READ_COUNTER<=DPRAM_S_READ_COUNTER+2'd2;
		
		
		// WRITE TO SRAM 
		SRAM_address<=write_address_SRAM;
		SRAM_write_data<= {MSB,LSB};
		SRAM_we_n <= 0;
		Write_Sample_counter <=Write_Sample_counter+1'd1;
		end
		//compute T
		
		col_index_DPRAM_S_Prime<= col_index_DPRAM_S_Prime+1'd1;	
		// ALWAYS AFTER WRITING RESET THE WE EN TO 0 TO ENSURE NO CORRUPTION 
		WE_T_0<=1'd0;
		WE_T_1<=1'd0;
		
		
		address_s_prime_0 <=read_address_compute_T;
		Sample_counter<= Sample_counter+1'd1; 
		WE_s_prime_0<=1'd0;
		
		
		C_multiplier_row <= C_multiplier_row+1;		
		//MULTIPLIERS
		// c row c column
		Mult_M2_op_0_1<= read_data_s_prime_0;
		Mult_M2_op_0_2<=C0;
		Mult_M2_op_1_1<=read_data_s_prime_0;
		Mult_M2_op_1_2<=C1;
		Mult_M2_op_2_1<=read_data_s_prime_0;
		Mult_M2_op_2_2<=C2;
		Mult_M2_op_3_1<=read_data_s_prime_0;
		Mult_M2_op_3_2<=C3;
		
		mux_counter<= mux_counter+1'd1;

		T_0<= T_0+Mult_M2_result_0;
		T_1<= T_1+Mult_M2_result_1;
		T_2<= T_2+Mult_M2_result_2;
		T_3<= T_3+Mult_M2_result_3;
		
		M2_state<= S_WS_CT_CC_7;
		end
		
		S_WS_CT_CC_7: begin
		
		if (stop_write_S_SRAM==1'b0) begin
		/// READ S DP SRAM
		address_S_0<=DPRAM_S_READ_COUNTER;
		address_S_1<=DPRAM_S_READ_COUNTER+1'd1;
		WE_S_0<=0;
		WE_S_1<=0;
		DPRAM_S_READ_COUNTER<=DPRAM_S_READ_COUNTER+2'd2;
		
		
		// WRITE TO SRAM 
		SRAM_address<=write_address_SRAM;
		SRAM_write_data<= {MSB,LSB};
		SRAM_we_n <= 0;
		Write_Sample_counter <=Write_Sample_counter+1'd1;
		end
		//compute T 
		col_index_DPRAM_S_Prime<= col_index_DPRAM_S_Prime+1'd1;	
		
		// ALWAYS AFTER WRITING RESET THE WE EN TO 0 TO ENSURE NO CORRUPTION 
		WE_T_0<=1'd0;
		WE_T_1<=1'd0;
		
		
		address_s_prime_0 <=read_address_compute_T;
		
		Sample_counter<= Sample_counter+1'd1; 
		WE_s_prime_0<=1'd0;
		
		
		C_multiplier_row <= C_multiplier_row+1;		
		//MULTIPLIERS
		// c row c column
		Mult_M2_op_0_1<= read_data_s_prime_0;
		Mult_M2_op_0_2<=C0;
		Mult_M2_op_1_1<=read_data_s_prime_0;
		Mult_M2_op_1_2<=C1;
		Mult_M2_op_2_1<=read_data_s_prime_0;
		Mult_M2_op_2_2<=C2;
		Mult_M2_op_3_1<=read_data_s_prime_0;
		Mult_M2_op_3_2<=C3;
		
		mux_counter<= mux_counter+1'd1;

		T_0<= T_0+Mult_M2_result_0; 
		T_1<= T_1+Mult_M2_result_1;
		T_2<= T_2+Mult_M2_result_2;
		T_3<= T_3+Mult_M2_result_3;
		
		//logic for incrementing row counter for C
		if (flag_increment_row==1'b1)begin
		C_multiplier_row <= C_multiplier_row+1;
		//row_index_DPRAM_S_Prime<= row_index_DPRAM_S_Prime+1'd1;	
		end
		else C_multiplier_row <= C_multiplier_row;
	

		if (c_index_3 == 16'd59) C_multiplier_column<=6'd4;
		else C_multiplier_column<=6'd0;
		
		
		M2_state<= S_WS_CT_CC_0;
		end
		
		
		S_LAST_WRITE_LI_0 :begin
		
		/// READ S DP SRAM
		address_S_0<=DPRAM_S_READ_COUNTER;
		address_S_1<=DPRAM_S_READ_COUNTER+1'd1;
		WE_S_0<=0;
		WE_S_1<=0;
		DPRAM_S_READ_COUNTER<=DPRAM_S_READ_COUNTER+2'd2;
		
		M2_state<=S_LAST_WRITE_LI_1;
		end
		
		S_LAST_WRITE_LI_1 :begin
		
		
				/// READ S DP SRAM
		address_S_0<=DPRAM_S_READ_COUNTER;
		address_S_1<=DPRAM_S_READ_COUNTER+1'd1;
		WE_S_0<=0;
		WE_S_1<=0;
		DPRAM_S_READ_COUNTER<=DPRAM_S_READ_COUNTER+2'd2;
		
		
		M2_state<=S_LAST_WRITE_LI_2;
		end
		
		S_LAST_WRITE_LI_2 :begin
		
		/// READ S DP SRAM
		address_S_0<=DPRAM_S_READ_COUNTER;
		address_S_1<=DPRAM_S_READ_COUNTER+1'd1;
		WE_S_0<=0;
		WE_S_1<=0;
		DPRAM_S_READ_COUNTER<=DPRAM_S_READ_COUNTER+2'd2;
		
		
		// WRITE TO SRAM 
		SRAM_address<=write_address_SRAM;
		SRAM_write_data<= {MSB,LSB};
		SRAM_we_n <= 0;
		Write_Sample_counter <=Write_Sample_counter+1'd1;
		
		
		M2_state<=S_LAST_WRITE_LI_3;
		end
		
		S_LAST_WRITE_LI_3 :begin
		
		/// READ S DP SRAM
		address_S_0<=DPRAM_S_READ_COUNTER;
		address_S_1<=DPRAM_S_READ_COUNTER+1'd1;
		WE_S_0<=0;
		WE_S_1<=0;
		DPRAM_S_READ_COUNTER<=DPRAM_S_READ_COUNTER+2'd2;
		
		
		// WRITE TO SRAM 
		SRAM_address<=write_address_SRAM;
		SRAM_write_data<= {MSB,LSB};
		SRAM_we_n <= 0;
		Write_Sample_counter <=Write_Sample_counter+1'd1;
		
		M2_state<=S_LAST_WRITE_LI_3;
		if (Write_Sample_counter == 6'd32) M2_state<=S_LAST_WRITE_LO_0;
		// if condition is true then exit to lead out
		end
		
		S_LAST_WRITE_LO_0 : begin
		
		// add some code to stop writing to DPRAM and SRAM
		WE_s_prime_0<=0;
		WE_s_prime_1<=0;
		WE_T_0<=0;
		WE_T_1<=0;
		WE_S_0<=0;
		WE_S_1<=0;
		SRAM_we_n<=1'd1;
		M2_done <=1'd1;
		M2_state<=S_IDLE_M2;
		end
		
		
		
		
		
	default: M2_state<= S_IDLE_M2;
	endcase
	end
	
end

assign c_index_0 =  mux_counter;
assign c_index_1 =  mux_counter;
assign c_index_2 = mux_counter;
assign c_index_3 =  mux_counter;
	

		
//mux 0
always_comb begin
	case(c_index_0)
	
	0: C0 = 32'sd1448;   //C00
	1: C0 = 32'sd2008;   //C10
	2: C0 = 32'sd1892;   //C20
	3: C0 = 32'sd1702;   //C30
	4: C0 = 32'sd1448;   //C40
	5: C0 = 32'sd1137;   //C50
	6: C0 = 32'sd783;    //C60
	7: C0 = 32'sd399;    //C70
	8: C0 = 32'sd1448;   //C04
	9: C0 = -32'sd399;   //C14
	10:  C0 = -32'sd1892;  //C24
	11: C0 = 32'sd1137;   //C34
	12: C0 = 32'sd1448;   //C44
	13: C0 = -32'sd1702;  //C54
	14:	C0 = -32'sd783;   //C64
	15: C0 = 32'sd2008;   //C74
	
	default: C0 = 32'sd1448;   
endcase
end

//mux 0
always_comb begin
	case(c_index_1)
	
	0: C1 = 32'sd1448;   //C01
	1: C1 = 32'sd1702;   //C11
	2: C1 = 32'sd783;    //C21
	3: C1 = -32'sd399;   //C31
	4: C1 = -32'sd1448;  //C41
	5: C1 = -32'sd2008;  //C51
	6: C1 = -32'sd1892;  //C61
	7: C1 = -32'sd1137;  //C71
	8: C1 = 32'sd1448;   //C05
	9: C1 = -32'sd1137;  //C15
	10: C1 = -32'sd783;   //C25
	11: C1 = 32'sd2008;   //C35
	12: C1= -32'sd1448;  //C45
	13: C1 = -32'sd399;   //C55
	14: C1 = 32'sd1892;   //C65
	15: C1 = -32'sd1702;  //C75
	default: C1 = 32'sd1448; 
	endcase
	
end

//mux 0
always_comb begin
	case(c_index_2)
	
	0: C2 = 32'sd1448;   //C02
	1: C2 = 32'sd1137;   //C12
	2: C2 = -32'sd783;   //C22
	3: C2 = -32'sd2008;  //C32
	4: C2 = -32'sd1448;  //C42
	5: C2 = 32'sd399;    //C52
	6: C2 = 32'sd1892;   //C62
	7: C2 = 32'sd1702;   //C72
	8: C2 = 32'sd1448;   //C06
	9: C2 = -32'sd1702;  //C16
	10: C2 = 32'sd783;    //C26
	11:  C2 = 32'sd399;    //C36
	12: C2 = -32'sd1448;  //C46
	13: C2 = 32'sd2008;   //C56
	14: C2 = -32'sd1892;  //C66
	15: C2 = 32'sd1137;   //C76
	default : C2 = 32'sd1448;
	endcase
	 
end

//mux 0
always_comb begin
	case(c_index_3)
	
	0: C3 = 32'sd1448;   //C03
	1: C3 = 32'sd399;    //C13
	2: C3 = -32'sd1892;  //C23
	3: C3 = -32'sd1137;  //C33
	4: C3 = 32'sd1448;   //C43
	5: C3 = 32'sd1702;   //C53
	6: C3 = -32'sd783;   //C63
	7: C3 = -32'sd2008;  //C73
	8: C3 = 32'sd1448;   //C07
	9: C3 = -32'sd2008;  //C17
	10: C3 = 32'sd1892;   //C27
	11: C3 = -32'sd1702;  //C37
	12: C3 = 32'sd1448;   //C47
	13: C3 = -32'sd1137;  //C57
	14: C3= 32'sd783;    //C67
	15: C3 = -32'sd399;   //C77
	default: C3 = 32'sd1448;
	endcase
	 
end




//multiplioers
assign Mult_M2_result_long_0 = Mult_M2_op_0_1 * Mult_M2_op_0_2;
assign Mult_M2_result_0 = Mult_M2_result_long_0[31:0];

assign Mult_M2_result_long_1 = Mult_M2_op_1_1 * Mult_M2_op_1_2;
assign Mult_M2_result_1 = Mult_M2_result_long_1[31:0];

assign Mult_M2_result_long_2 = Mult_M2_op_2_1 * Mult_M2_op_2_2;
assign Mult_M2_result_2 = Mult_M2_result_long_2[31:0];

assign Mult_M2_result_long_3 = Mult_M2_op_3_1 * Mult_M2_op_3_2;
assign Mult_M2_result_3 = Mult_M2_result_long_3[31:0];

 
 
endmodule 