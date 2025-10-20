`timescale 1ns/100ps
`ifndef DISABLE_DEFAULT_NET
`default_nettype none
`endif

`include "define_state.h"

// This module generates the protocol signals to communicate 
// with the external SRAM (using a 2 clock cycle latency)
module M1(
		input logic Clock_50,
		input logic Resetn,
		
		input logic M1_Start,
		output logic [17:0] SRAM_address,
		output logic [15:0] SRAM_write_data,
		output logic SRAM_we_n,
		input logic [15:0] SRAM_read_data,
		
		output logic M1_Completed
		
);

M1_state_type M1_state;


////* input and parameters
parameter Y_OFFSET   = 18'd0,
			 U_OFFSET   = 18'd38400,
          V_OFFSET   = 18'd57600,
			 RGB_OFFSET = 18'd146944;
logic [17:0] Y_OFFSET_COUNTER;
logic [17:0] U_OFFSET_COUNTER;
logic [17:0] V_OFFSET_COUNTER;
logic [17:0] RGB_OFFSET_COUNTER;
//multiplier params
logic signed[31:0] Mult_op_0_1, Mult_op_0_2, Mult_result_0;
logic signed[63:0] Mult_result_long_0;
logic signed[31:0] Mult_op_1_1, Mult_op_1_2, Mult_result_1;
logic signed[63:0] Mult_result_long_1;
logic signed[31:0] Mult_op_2_1, Mult_op_2_2, Mult_result_2;
logic signed[63:0] Mult_result_long_2;
logic signed[31:0] Mult_op_3_1, Mult_op_3_2, Mult_result_3;
logic signed[63:0] Mult_result_long_3;
//THIS IS ADDING 4 MORE MULTIPLIERS // PLUS SOME 4 MORE FROM INCREASING THE SIZE OF THE BUFFERS OR SOMETHING
logic signed[31:0] Mult_op_0_1_converted;
logic signed[31:0] Mult_op_1_1_converted;
logic signed[31:0] Mult_op_2_1_converted;
logic signed[31:0] Mult_op_3_1_converted;
//multiplier buffers

logic [31:0] OP1_BUF;
logic [31:0] OP2_BUF;
logic [31:0] OP3_BUF;
logic [31:0] OP4_BUF;
logic [31:0] OP5_BUF;
logic [31:0] OP6_BUF;
logic [31:0] OP7_BUF;
logic [31:0] OP8_BUF;

logic [31:0] OP1_5BUF;
logic [31:0] OP2_5BUF;
logic[11:0] Column_Counter;



//U instantiations
logic odd_even;
logic LEADIN_TO_CC_TRANSITION;
logic signed[31:0] U_prime;
logic signed[31:0]U_prime_buf_odd_U3;
logic signed[31:0]U_prime_buf_odd_U1;
logic signed[31:0] V_prime;
logic signed[31:0]V_prime_buf_odd_V3;
logic signed[31:0]V_prime_buf_odd_V1;

//shift register
logic [7:0] U[5:0];
logic [7:0] V[5:0];
logic signed[31:0] R_EVEN;
logic signed[31:0] G_EVEN;
logic signed[31:0] B_EVEN;
logic signed[31:0] R_ODD;
logic signed[31:0] G_ODD;
logic signed[31:0] B_ODD;
logic signed[31:0] R_EVEN_2;
logic signed[31:0] G_EVEN_2;
logic signed[31:0] B_EVEN_2;
logic signed[31:0] R_ODD_2;
logic signed[31:0] G_ODD_2;
logic signed[31:0] B_ODD_2;
logic signed[15:0] U_buf[1:0];
logic signed[15:0] V_buf[1:0];
logic signed[15:0] Y_buf[1:0];

logic signed[7:0]R_ODD_SEND;
logic signed[7:0]G_ODD_SEND;
logic signed [7:0]B_ODD_SEND;
logic signed[7:0]R_EVEN_SEND;
logic signed[7:0]G_EVEN_SEND;
logic signed[7:0]B_EVEN_SEND;

logic signed[7:0]R_ODD_2_SEND;
logic signed[7:0]G_ODD_2_SEND;
logic signed [7:0]B_ODD_2_SEND;
logic signed[7:0]R_EVEN_2_SEND;
logic signed[7:0]G_EVEN_2_SEND;
logic signed[7:0]B_EVEN_2_SEND;


logic Lead_Out_Flag;

always_ff @ (posedge Clock_50 or negedge Resetn) begin
	if (~Resetn) begin
	//only outputs
	// mode set to read by default
		SRAM_we_n <= 1'b1;
		SRAM_write_data <= 16'd0;
		SRAM_address <= 18'd0;
		M1_Completed <=1'd0;
		U_prime<=0;
		U_prime_buf_odd_U3<=0;
		U_prime_buf_odd_U1<=0;
		V_prime<=0;
		V_prime_buf_odd_V3<=0;
		V_prime_buf_odd_V1<=0;
		U[5]<=8'd0;
		U[4]<=8'd0;
		U[3]<=8'd0;
		U[2]<=8'd0;
		U[1]<=8'd0;
		U[0]<=8'd0;
		V[5]<=8'd0;
		V[4]<=8'd0;
		V[3]<=8'd0;
		V[2]<=8'd0;
		V[1]<=8'd0;
		V[0]<=8'd0;
		R_EVEN<=31'd0;
		G_EVEN<=31'd0;
		B_EVEN<=31'd0;
		R_ODD<=31'd0;
		G_ODD<=31'd0;
		B_ODD<=31'd0;
		R_EVEN_2<=31'd0;
		G_EVEN_2<=31'd0;
		B_EVEN_2<=31'd0;
		R_ODD_2<=31'd0;
		G_ODD_2<=31'd0;
		B_ODD_2<=31'd0;
		U_buf[0]<=16'd0;
		U_buf[1]<=16'd0;
		Y_buf[0]<=16'd0;
		Y_buf[1]<=16'd0;
		V_buf[0]<=16'd0;
		V_buf[1]<=16'd0;
		Mult_op_0_1<=32'd0;
		Mult_op_0_2<=32'd0;
		Mult_op_1_1<=32'd0;
		Mult_op_1_2<=32'd0;
		Mult_op_2_1<=32'd0;
		Mult_op_2_2<=32'd0;
		Mult_op_3_1<=32'd0;
		Mult_op_3_2<=32'd0;
		OP1_BUF<=0;
		OP2_BUF<=0;
		OP3_BUF<=0;
		OP4_BUF<=0;
		OP5_BUF<=0;
		OP6_BUF<=0;
		OP7_BUF<=0;
		OP8_BUF<=0;
		V_OFFSET_COUNTER<=0;
		U_OFFSET_COUNTER<=0;
		Y_OFFSET_COUNTER<=0;
		RGB_OFFSET_COUNTER<=0;
		odd_even<=0;
		LEADIN_TO_CC_TRANSITION<=0;
		Column_Counter<=0;
		OP1_5BUF<=0;
		OP2_5BUF<=0;
		Lead_Out_Flag<=0;
	end else begin
		 
			case (M1_state)
				
				S_LEADIN_0 : begin
				M1_state<= S_LEADIN_0;
				//odd_even<= ~odd_even;
				// STOP writing the data
				SRAM_we_n<= 1'b1;
				if (M1_Start == 1'b1) begin
				
				//U0U1
				SRAM_we_n <= 1'b1;
				LEADIN_TO_CC_TRANSITION <=1'b1;
				SRAM_address <= U_OFFSET+U_OFFSET_COUNTER;
				U_OFFSET_COUNTER<= U_OFFSET_COUNTER+1'd1;
				M1_state<= S_LEADIN_1;
				end
						// multiplier buffers
				OP1_BUF <= Mult_result_0;
				OP2_BUF <= Mult_result_1;
				OP3_BUF <= Mult_result_2;
				OP4_BUF <= Mult_result_3;
				end 
				
				S_LEADIN_1: begin
				//U2/U3
				SRAM_we_n <= 1'b1;
				SRAM_address <= U_OFFSET+U_OFFSET_COUNTER;
				U_OFFSET_COUNTER<= U_OFFSET_COUNTER+1'd1;
				M1_state<= S_LEADIN_2;
				end
				S_LEADIN_2: begin
				//u4u5
				SRAM_we_n <= 1'b1;
				SRAM_address <= U_OFFSET+U_OFFSET_COUNTER;
				U_OFFSET_COUNTER<= U_OFFSET_COUNTER+1'd1;
				M1_state<= S_LEADIN_3;
				end
				S_LEADIN_3: begin
				//Y0/Y1
				SRAM_we_n <= 1'b1;
				SRAM_address <= Y_OFFSET+Y_OFFSET_COUNTER;
				Y_OFFSET_COUNTER<= Y_OFFSET_COUNTER+1'd1;
				//updates whenver we read Y
				Column_Counter<=Column_Counter+1'd1;				
				//U_buf[0] <= SRAM_read_data;
				U[5]<=U[3];
				U[4]<=U[2];
				U[3]<=U[1];
				U[2]<=U[0];
				U[1]<=SRAM_read_data[15:8];
				U[0]<=SRAM_read_data[7:0];
				//LSB U1 -> POS U3
				
				// multiplier buffers
				OP1_BUF <= 0;
				OP2_BUF <= 0;
				OP3_BUF <= 0;
				OP4_BUF <= 0;
				
				
				M1_state<= S_LEADIN_4;
				
				end
				
				S_LEADIN_4: begin
				
				//READ V0/V1
				SRAM_we_n <= 1'b1;
				SRAM_address <= V_OFFSET+V_OFFSET_COUNTER;
				V_OFFSET_COUNTER<= V_OFFSET_COUNTER+1'd1;
				//U_buf[1] <= SRAM_read_data;
				U[5]<=U[3];
				U[4]<=U[2];
				U[3]<=U[1];
				U[2]<=U[0];
				U[1]<=SRAM_read_data[15:8];
				U[0]<=SRAM_read_data[7:0];
				
				
				//multiplication u[1] IS U0
				Mult_op_0_1<=U[1];
				Mult_op_0_2<= 32'sd21;
				Mult_op_1_1<=U[1];
				Mult_op_1_2<= -32'sd52;
				Mult_op_2_1<=U[1];
				Mult_op_2_2<= 32'sd159;
				Mult_op_3_1<=U[0];
				Mult_op_3_2<= 32'sd159;
				
				
			
				
				// multiplier buffers
				M1_state<= S_LEADIN_5;
				end
				
				S_LEADIN_5: begin
				//read V2/V3
				SRAM_we_n <= 1'b1;
				SRAM_address <= V_OFFSET+V_OFFSET_COUNTER;
				V_OFFSET_COUNTER<= V_OFFSET_COUNTER+1'd1;
				//STORE U4/U5
				U[5]<=U[3];
				U[4]<=U[2];
				U[3]<=U[1];
				U[2]<=U[0];
				U[1]<=SRAM_read_data[15:8];
				U[0]<=SRAM_read_data[7:0];
				
				//multiplication
				Mult_op_0_1<=U[1];
				Mult_op_0_2<= -32'sd52;
				Mult_op_1_1<=U[1];
				Mult_op_1_2<= 32'sd159;
				Mult_op_2_1<=U[0];
				Mult_op_2_2<= 32'sd21;
				Mult_op_3_1<=U[0];
				Mult_op_3_2<= -32'sd52;
				
					// multiplier buffers
				OP1_BUF <= Mult_result_0;
				OP2_BUF <= Mult_result_1;
				OP3_BUF <= Mult_result_2;
				OP4_BUF <= Mult_result_3;
			

				M1_state<= S_LEADIN_6;
				end
				
				
				S_LEADIN_6: begin
				//read V4/V5
				SRAM_we_n <= 1'b1;
				SRAM_address <= V_OFFSET+V_OFFSET_COUNTER;
				V_OFFSET_COUNTER<= V_OFFSET_COUNTER+1'd1;
				
				OP5_BUF <= Mult_result_0;
				OP6_BUF <= Mult_result_1;
				OP7_BUF <= Mult_result_2;
				OP8_BUF <= Mult_result_3;
				//Get U'0, U'1
				U_prime <= ((OP1_BUF + OP2_BUF + OP3_BUF + OP4_BUF + Mult_result_0 + Mult_result_2+ 8'd128)>>8);
				
				//STORE Y0/Y1 INTO BUF
				Y_buf[0] <= SRAM_read_data;
				
				// DO MULTIPLIER FOR RGB BASED ON U'0/U'1
					//multiplication
				
				Mult_op_0_1<=U[1];
				Mult_op_0_2<= 32'sd21;
				Mult_op_1_1<=SRAM_read_data[15:8] - 9'sd16;
				Mult_op_1_2<= 32'sd76284;
				Mult_op_2_1<=SRAM_read_data[7:0]- 9'sd16;
				Mult_op_2_2<= 32'sd76284;
				
				
				M1_state<= S_LEADIN_7;
				end
				
				S_LEADIN_7: begin
				//read Y2/Y3
				SRAM_we_n <= 1'b1;
				SRAM_address <= Y_OFFSET+Y_OFFSET_COUNTER;
				Y_OFFSET_COUNTER<= Y_OFFSET_COUNTER+1'd1;
				Column_Counter<=Column_Counter+1'd1;
				//U'2/3
				U_prime <= ((OP1_BUF+OP2_BUF+OP4_BUF+OP6_BUF+OP8_BUF+Mult_result_0+ 8'd128)>>>8);
				U_prime_buf_odd_U1<=U_prime;
				
				//FILL IN RGB WITH (Y-16)*76284
				R_EVEN<=Mult_result_1;
				G_EVEN<=Mult_result_1;
				B_EVEN<=Mult_result_1;
				R_ODD<=Mult_result_2;
				G_ODD<=Mult_result_2;
				B_ODD<=Mult_result_2;
				
				
				
				V_buf[0]=SRAM_read_data;
				
				
				
				//V reads
				V[5]<=V[3];
				V[4]<=V[2];
				V[3]<=V[1];
				V[2]<=V[0];
				V[1]<=SRAM_read_data[15:8];
				V[0]<=SRAM_read_data[7:0];
				
				
				//U' Multiplications
				
				Mult_op_0_1<=(U_prime - 8'd128);
				Mult_op_0_2<= -32'sd25624;
				Mult_op_1_1<=U[5]-8'd128;
				Mult_op_1_2<= 32'sd132251;
				Mult_op_2_1<=U_prime-8'd128;
				Mult_op_2_2<= 32'sd132251;
				Mult_op_3_1<=U[5]-8'd128;
				Mult_op_3_2<= -32'sd25624;
				
//							// multiplier buffers
//				OP1_BUF <= Mult_result_0;
//				OP2_BUF <= Mult_result_1;
//				OP3_BUF <= Mult_result_2;
//				OP4_BUF <= Mult_result_3;
//			
				
				
				M1_state<= S_LEADIN_8;
				
				
				
				
				
				
				end
				S_LEADIN_8: begin
				
				V_buf[1]=SRAM_read_data;
				//FILL IN V'S
					//V reads
				V[5]<=V[3];
				V[4]<=V[2];
				V[3]<=V[1];
				V[2]<=V[0];
				V[1]<=SRAM_read_data[15:8];
				V[0]<=SRAM_read_data[7:0];
				//fill in RBG U0/U1
				//FILL IN RGB WITH (Y-16)*76284
				R_EVEN<=R_EVEN;
				G_EVEN<=G_EVEN+Mult_result_3;
				B_EVEN<=B_EVEN+Mult_result_1;
				R_ODD<=R_ODD;
				G_ODD<=G_ODD+Mult_result_0;
				B_ODD<=B_ODD+Mult_result_2;
				//fill in U'3 into here
				U_prime_buf_odd_U3<=U_prime;
				//	V MULTIPLICATIONS
				Mult_op_0_1<=V[1];
				Mult_op_0_2<= 32'sd21;
				Mult_op_1_1<=V[1];
				Mult_op_1_2<= -32'sd52;
				Mult_op_2_1<=V[1];
				Mult_op_2_2<= 32'sd159;
				Mult_op_3_1<=V[0];
				Mult_op_3_2<= 32'sd159;
				
				//BEO for 0,1 done since B only needs Y and U next states is where we compute V
				M1_state<= S_LEADIN_9;
				end
				
				
				S_LEADIN_9: begin
								//read Y4/Y5
				SRAM_address <= Y_OFFSET+Y_OFFSET_COUNTER;
				Y_OFFSET_COUNTER<= Y_OFFSET_COUNTER+1'd1;
				Column_Counter<=Column_Counter+1'd1;
				//FILL IN COMPLETED AFTER THIS CYCLE
				//V reads
				V_buf[0]=SRAM_read_data;
				V[5]<=V[3];
				V[4]<=V[2];
				V[3]<=V[1];
				V[2]<=V[0];
				V[1]<=SRAM_read_data[15:8];
				V[0]<=SRAM_read_data[7:0];
				
				//	V MULTIPLICATIONS
				Mult_op_0_1<=V[1];
				Mult_op_0_2<= -32'sd52;
				Mult_op_1_1<=V[1];
				Mult_op_1_2<= 32'sd159;
				Mult_op_2_1<=V[0];
				Mult_op_2_2<= 32'sd21;
				Mult_op_3_1<=V[0];
				Mult_op_3_2<= -32'sd52;
				
				
				U_prime <= OP1_BUF+ OP6_BUF;
				
				// multiplier buffers
				OP1_BUF <= Mult_result_0;
				OP2_BUF <= Mult_result_1;
				OP3_BUF <= Mult_result_2;
				OP4_BUF <= Mult_result_3;
				
				M1_state<= S_LEADIN_10;
				
				
				
			
				
				
				end
				S_LEADIN_10: begin
				//READ U6/U7
				SRAM_address <= U_OFFSET+U_OFFSET_COUNTER;
				U_OFFSET_COUNTER<= U_OFFSET_COUNTER+1'd1;
				// Y2/Y3 into buffer
				Y_buf[0]<=SRAM_read_data;
					// multiplier buffers
				OP5_BUF <= Mult_result_0;
				OP6_BUF <= Mult_result_1;
				OP7_BUF <= Mult_result_2;
				OP8_BUF <= Mult_result_3;
				
				Y_buf[0]<=SRAM_read_data;
				V_prime <= (OP1_BUF + OP2_BUF + OP3_BUF + OP4_BUF + Mult_result_0 + Mult_result_2+ 8'd128)>>>8;
				
				
					//	V MULTIPLICATIONS
				Mult_op_0_1<=V[1];
				Mult_op_0_2<= 32'sd21;
				Mult_op_1_1<=SRAM_read_data[15:8]-8'sd16;
				Mult_op_1_2<= 32'sd76284;
				Mult_op_2_1<=SRAM_read_data[7:0]-8'sd16;
				Mult_op_2_2<= 32'sd76284;
				// only 3 multipliers in this cycle
				
				M1_state<= S_LEADIN_11;
				
				
				
				end
				
				S_LEADIN_11: begin
				//READ V6/V7
				SRAM_address <= V_OFFSET+V_OFFSET_COUNTER;
				V_OFFSET_COUNTER<= V_OFFSET_COUNTER+1'd1;
				
				V_prime <= (OP1_BUF+OP2_BUF+OP4_BUF+OP6_BUF+OP8_BUF+Mult_result_0+ 8'd128)>>>8;
				V_prime_buf_odd_V1<=V_prime;
				//V1' PRIME
				Mult_op_0_1<=V_prime-8'd128;
				Mult_op_0_2<= 32'sd104595;
				Mult_op_1_1<=V[5]-8'd128;
				Mult_op_1_2<= 32'sd104595;
				Mult_op_2_1<=V_prime-8'd128;
				Mult_op_2_2<= -32'sd53281;
				Mult_op_3_1<=V[5]-8'd128;
				Mult_op_3_2<= -32'sd53281;
				
				//FILL IN RGB WITH (Y'2/3-16)*76284
				R_EVEN_2<=Mult_result_1;
				G_EVEN_2<=Mult_result_1;
				B_EVEN_2<=Mult_result_1;
				R_ODD_2<=Mult_result_2;
				G_ODD_2<=Mult_result_2;
				B_ODD_2<=Mult_result_2;
				
				M1_state<= S_LEADIN_12;
				
				end
				S_LEADIN_12: begin
				
				
				
				//DOUBLE CHECK WHAT THIS NEEDS TO EB
				//u2,3' PRIME
				V_prime_buf_odd_V3<= V_prime;
				
				Mult_op_0_1<=U_prime_buf_odd_U3-8'd128;
				Mult_op_0_2<= -32'sd25624;
				Mult_op_1_1<=U[4]-8'd128;
				Mult_op_1_2<= 32'sd132251;
				Mult_op_2_1<=U_prime_buf_odd_U3-8'd128;
				Mult_op_2_2<= 32'sd132251;
				Mult_op_3_1<=U[4]-8'd128;
				Mult_op_3_2<= -32'sd25624;
				
				R_EVEN<=(R_EVEN +Mult_result_1);
				G_EVEN<=(G_EVEN+ Mult_result_3);
				B_EVEN<=(B_EVEN);
				R_ODD<=(R_ODD + Mult_result_0);
				G_ODD<=(G_ODD + Mult_result_2);
				B_ODD<=(B_ODD);
				
				Y_buf[0] = SRAM_read_data;
				M1_state<= S_LEADIN_13;
				
				end
				S_LEADIN_13: begin
				
				SRAM_we_n <=1'b0;
				// DO FIRST WRITE FOR R0G0 PREVIOUS CYCLE ENABLE WE_n
				SRAM_address <= RGB_OFFSET+RGB_OFFSET_COUNTER;
				RGB_OFFSET_COUNTER<= RGB_OFFSET_COUNTER+1'd1;
				//SRAM_write_data <= {R_EVEN[31:16], G_EVEN[31:16][23:16]};


				SRAM_write_data <= {R_EVEN_SEND, G_EVEN_SEND};  //00CC00cf 00CC   /// we get : 00CF , expexted :CCCf
				//CC CF CCCF
				//READ AND STORE U6/7
				U_buf[0]<= SRAM_read_data;
				
				Mult_op_0_1<=V_prime_buf_odd_V3-9'd128;
				Mult_op_0_2<= 32'sd104595;
				Mult_op_1_1<=V[4]-8'd128;
				Mult_op_1_2<= 32'sd104595;
				Mult_op_2_1<=V_prime_buf_odd_V3-9'd128;
				Mult_op_2_2<= -32'sd53281;
				Mult_op_3_1<=V[4]-8'd128;
				Mult_op_3_2<= -32'sd53281;
				
				R_EVEN_2<=R_EVEN_2 ;
				G_EVEN_2<=G_EVEN_2+ Mult_result_3;
				B_EVEN_2<=(B_EVEN_2+Mult_result_1);
				R_ODD_2<=R_ODD_2;
				G_ODD_2<=G_ODD_2 + Mult_result_0;
				B_ODD_2<=(B_ODD_2+Mult_result_2);
				
				M1_state<= S_LEADIN_14;
				end
				S_LEADIN_14: begin
				SRAM_we_n <=1'b0;
				//WRITE B0/R1
				SRAM_address <= RGB_OFFSET+RGB_OFFSET_COUNTER;
				RGB_OFFSET_COUNTER<= RGB_OFFSET_COUNTER+1'd1;
				SRAM_write_data <= {B_EVEN_SEND, R_ODD_SEND};
				
				// READ V6/V7
				V_buf[0]<=SRAM_read_data;
				
				// GET UV4/5 READY FOR NEXT CYCLE CC
				Mult_op_0_1<=V[4];
				Mult_op_0_2<= -32'sd52;
				Mult_op_1_1<=V[2];
				Mult_op_1_2<= 32'sd159;
				Mult_op_2_1<=V[1];
				Mult_op_2_2<= -32'sd52;
				Mult_op_3_1<=V[0];
				Mult_op_3_2<= 32'sd21;
				
				R_EVEN_2<=(R_EVEN_2 + Mult_result_1);
				G_EVEN_2<=(G_EVEN_2 + Mult_result_3);
				B_EVEN_2<=B_EVEN_2;
				R_ODD_2<=(R_ODD_2 + Mult_result_0);
				G_ODD_2<=(G_ODD_2 + Mult_result_2);
				B_ODD_2<=B_ODD_2;
				
				// ALL RGB VALUES FOR 0123 READY
				M1_state<= S_LEADIN_15;
				end
				S_LEADIN_15: begin
				
				SRAM_address <= RGB_OFFSET+RGB_OFFSET_COUNTER;
				RGB_OFFSET_COUNTER<= RGB_OFFSET_COUNTER+1'd1;
				SRAM_write_data <= {G_ODD_SEND, B_ODD_SEND};
				
				//GET V'4/5 READY
				
				V_prime<=(OP1_BUF+ Mult_result_0+OP6_BUF+Mult_result_1+Mult_result_2+Mult_result_3+ 8'd128)>>>8;
				//V_buf[0]<= SRAM_read_data;
				
				// GET UV4/5 READY FOR NEXT CYCLE CC
				Mult_op_0_1<=U[4];
				Mult_op_0_2<= -32'sd52;
				Mult_op_1_1<=U[2];
				Mult_op_1_2<= 32'sd159;
				Mult_op_2_1<=U[1];
				Mult_op_2_2<= -32'sd52;
				Mult_op_3_1<=U[0];
				Mult_op_3_2<= 32'sd21;
				M1_state<= S_LEADIN_16;
				
				
				end
				S_LEADIN_16: begin
				
				//STILL DO THE U6 buffer stuff here
				SRAM_address <= RGB_OFFSET+RGB_OFFSET_COUNTER;
				
				SRAM_write_data <= {R_EVEN_2_SEND, G_EVEN_2_SEND};
				
				RGB_OFFSET_COUNTER<= RGB_OFFSET_COUNTER+1'd1;
				
				//store u'45 here u' = u'5
				
				U_prime <= (U_prime + (Mult_result_0+Mult_result_1+Mult_result_2+Mult_result_3+ 8'd128))>>>8;
				///changed from 15:8 to 7:0 didn't seem to make a diff. 
				U[0]<=U_buf[0][15:8];
				V[0]<=V_buf[0][15:8];
				
				U[5]<=U[4];
				U[4]<=U[3];
				U[3]<=U[2];
				U[2]<=U[1];
				U[1]<=U[0];
				
					
				V[5]<=V[4];
				V[4]<=V[3];
				V[3]<=V[2];
				V[2]<=V[1];
				V[1]<=V[0];
				
				M1_state<= S_LEADIN_17;
				//READ AND STORE v6/7
				
				
				
				end
				S_LEADIN_17: begin
				
				SRAM_address <= RGB_OFFSET+RGB_OFFSET_COUNTER;
				RGB_OFFSET_COUNTER<= RGB_OFFSET_COUNTER+1'd1;
				SRAM_write_data <= {B_EVEN_2_SEND, R_ODD_2_SEND};
				
				//update for U and V shift register with new value
				

				//LEADIN_TO_CC_TRANSITION <=1'b1;
				//Y_OFFSET_COUNTER<= Y_OFFSET_COUNTER-1;
				//V_OFFSET_COUNTER<= V_OFFSET_COUNTER-1;
				M1_state<= CC_0;
				end
				
				
				// start of common cases
				CC_0 : begin
			
//				//set write enable to ?
				SRAM_we_n<= 1'b0;
				// first CC is always even
				odd_even<= ~odd_even;
				//LEADIN_TO_CC_TRANSITION<= 0;
				
				//read y only once	
				if(Column_Counter==16'd156)begin // assuming its correct
				
				Lead_Out_Flag<=1'b1;
				end 
				
			
					//updates whenver we read Y
			//	Column_Counter<=Column_Counter+1'd1;
			
				
				SRAM_address <= RGB_OFFSET+RGB_OFFSET_COUNTER;
				RGB_OFFSET_COUNTER<= RGB_OFFSET_COUNTER+1'd1;
				SRAM_write_data <= {G_ODD_SEND, B_ODD_SEND};
				if (LEADIN_TO_CC_TRANSITION==1'b1) SRAM_write_data <= {G_ODD_2_SEND, B_ODD_2_SEND};
			
				
//				if (Column_Counter== 12'd320) begin
//				Column_Counter<=0;
//				M1_state<= S_LEADIN_0;
//				end
//				
				//buffer past V' and U' into odd buffer
				
				U_prime_buf_odd_U1<= U_prime;
				V_prime_buf_odd_V1<= V_prime;
				//CIRCULAR SHIFT 
	
				//fill in U' V' with 128
				
				U_prime <={23'd0,8'd128};
				V_prime <={23'd0,8'd128};
				//MULTIPLICATIONS
				Mult_op_0_1<=U[5];
				Mult_op_0_2<= 32'sd21;
				Mult_op_1_1<=V[5];
				Mult_op_1_2<= 32'sd21;
				//Y'4
				Mult_op_2_1<=Y_buf[0][15:8]-9'd16;
				Mult_op_2_2<= 32'sd76284;
				//V'4 = V2
				Mult_op_3_1<=V[4]-9'd128;
				Mult_op_3_2<= 32'sd104595;
				
				
				// RESET ALL RBG TO ZERO
				//FILL IN SOME RGB
//				R_EVEN<=32'd0;
//				G_EVEN<=32'd0;
//				B_EVEN<=32'd0;
//				R_ODD<=32'd0;
//				G_ODD<=32'd0;
//				B_ODD<=32'd0;
				M1_state<= CC_1;
				end
				
			
				
				
				CC_1: begin
				
				
				
				//first new read Y8/9 always read Y 
				SRAM_we_n <=1'b1;
				SRAM_address <= Y_OFFSET+Y_OFFSET_COUNTER;
				
				M1_state<= CC_2;
				Y_OFFSET_COUNTER<= Y_OFFSET_COUNTER+1'd1;
				
//				
			//read Y?
				Column_Counter<=Column_Counter+1'd1;
				
			
				
				//fill in U' V' 
				
				U_prime <=U_prime+Mult_result_0;
				V_prime <=V_prime+Mult_result_1;
				
				//MULTIPLICATIONS
				Mult_op_0_1<=U[4];
				Mult_op_0_2<= -32'Sd52;
				Mult_op_1_1<=V[4];
				Mult_op_1_2<= -32'Sd52;
				Mult_op_2_1<=U[4]-9'd128;
				Mult_op_2_2<= -32'sd25624;
				Mult_op_3_1<=V[4]-9'd128;
				Mult_op_3_2<= -32'sd53281;
				
				
				//FILL IN SOME RGB
				R_EVEN<=Mult_result_2+Mult_result_3;
				G_EVEN<=Mult_result_2;
				B_EVEN<=Mult_result_2;
				R_ODD<=0;
				G_ODD<=0;
				B_ODD<=0;
				
				
				end
				
				
				
				
				CC_2: begin
				
				//fill in U and V buffer for first pass it needs to come from a buffer for lead in but after lead in it needs to come from SRAM read_data
				
				LEADIN_TO_CC_TRANSITION <=1'b0;
				SRAM_we_n <=1'b1;
				U_buf[0]<=SRAM_read_data;
				
				
				
				//possibly use odd even logic here
				if (odd_even==1'b1) begin
				U_buf[0] <= U_buf[0];
				
				end
				if (LEADIN_TO_CC_TRANSITION==1'b1) U_buf[0]<=U_buf[0];
				
				
				//fill in U' V' 
				
				U_prime <=U_prime+Mult_result_0;
				V_prime <=V_prime+Mult_result_1;
				
				//MULTIPLICATIONS
				Mult_op_0_1<=U[3];
				Mult_op_0_2<= 32'sd159;
				Mult_op_1_1<=V[3];
				Mult_op_1_2<= 32'sd159;
				Mult_op_2_1<=U[4]-9'sd128;
				Mult_op_2_2<= 32'sd132251;
				//Y'5
				Mult_op_3_1<=Y_buf[0][7:0]-8'sd16;
				Mult_op_3_2<= 32'sd76284;
				
				
				//FILL IN SOME RGB
				R_EVEN<=R_EVEN;
				G_EVEN<=G_EVEN+Mult_result_2+Mult_result_3;
				B_EVEN<=B_EVEN;
				R_ODD<=R_ODD;
				G_ODD<=G_ODD;
				B_ODD<=B_ODD;
				
				
				
				M1_state<= CC_3;
				end
				
				CC_3: begin
				
				SRAM_we_n <=1'b1;
				//first new read v8/9
				
				
				
				
				
				
				if (odd_even ==1) begin
				SRAM_address <= V_OFFSET+V_OFFSET_COUNTER;
				V_OFFSET_COUNTER<= V_OFFSET_COUNTER+1'd1;
				end
				
				if (Lead_Out_Flag == 1) begin
				//dont do anything to the V
				
				SRAM_address <= V_OFFSET;
				V_OFFSET_COUNTER<= V_OFFSET_COUNTER;
				end
	
				
				//fill in U' V' 
				
				U_prime <=U_prime+Mult_result_0;
				V_prime <=V_prime+Mult_result_1;
				
				//MULTIPLICATIONS
				Mult_op_0_1<=U[2];
				Mult_op_0_2<= 32'sd159;
				Mult_op_1_1<=V[2];
				Mult_op_1_2<= 32'sd159;
				Mult_op_2_1<=V_prime_buf_odd_V1-8'd128;
				Mult_op_2_2<= 32'sd104595;
				//U'5
				Mult_op_3_1<=U_prime_buf_odd_U1-8'd128;
				Mult_op_3_2<= -32'sd25624;
				
				
				//FILL IN SOME RGB
				R_EVEN<=R_EVEN;
				G_EVEN<=G_EVEN;
				B_EVEN<=B_EVEN+Mult_result_2;
				R_ODD<=Mult_result_3;
				G_ODD<=Mult_result_3;
				B_ODD<=Mult_result_3;
				
				


	
				M1_state<= CC_4;
				end
				
				CC_4: begin
				
				if (RGB_OFFSET_COUNTER == 32'd115199) begin
				M1_Completed <=1'b1;
				M1_state<=S_LEADIN_0;
				end
				SRAM_we_n<= 1'b0;
				SRAM_address <= RGB_OFFSET+RGB_OFFSET_COUNTER;
				RGB_OFFSET_COUNTER<= RGB_OFFSET_COUNTER+1'd1;
				SRAM_write_data <= {R_EVEN_SEND, G_EVEN_SEND};
				
				Y_buf[0]<= SRAM_read_data;
				
			
				
				//fill in U' V' 
				
				U_prime <=U_prime+Mult_result_0;
				V_prime <=V_prime+Mult_result_1;
				
				//MULTIPLICATIONS
				Mult_op_0_1<=U[1];
				Mult_op_0_2<= -32'sd52;
				Mult_op_1_1<=V[1];
				Mult_op_1_2<= -32'sd52;
				Mult_op_2_1<=V_prime_buf_odd_V1-8'd128;
				Mult_op_2_2<= -32'sd53281;
				//u'5
				Mult_op_3_1<=U_prime_buf_odd_U1-8'd128;
				Mult_op_3_2<= 32'Sd132251;
				
				
				//FILL IN SOME RGB
				R_EVEN<=R_EVEN;
				G_EVEN<=G_EVEN;
				B_EVEN<=B_EVEN;
				R_ODD<=(R_ODD+Mult_result_2);
				G_ODD<=G_ODD+Mult_result_3;
				B_ODD<=B_ODD;
				
					//if(Column_Counter==16'd315)begin
				OP1_BUF<=Mult_result_0;
				OP2_BUF<=Mult_result_1;
				
				
			
				M1_state<= CC_5;
				end
				
				
				CC_5: begin
				//special case in here
				SRAM_we_n<= 1'b0;
				
				if (RGB_OFFSET_COUNTER == 32'd115199) begin
				M1_Completed <=1'b1;
				M1_state<=S_LEADIN_0;
				end
				SRAM_address <= RGB_OFFSET+RGB_OFFSET_COUNTER;
				RGB_OFFSET_COUNTER<= RGB_OFFSET_COUNTER+1'd1;
				SRAM_write_data <= {B_EVEN_SEND, R_ODD_SEND};
				
				
				// if lead_out flag don't shift
				if (Lead_Out_Flag == 1) begin
				U[5]<=U[5];
				U[4]<=U[4];
				U[3]<=U[3];
				U[2]<=U[2];
				U[1]<=U[1];
				U[0]<=U[0];
				
				V[5]<=V[5];
				V[4]<=V[4];
				V[3]<=V[3];
				V[2]<=V[2];
				V[1]<=V[1];
				V[0]<=V[0];
				end
				else begin
					//CIRCULAR SHIFT with new value
				U[5]<=U[4];
				U[4]<=U[3];
				U[3]<=U[2];
				U[2]<=U[1];
				U[1]<=U[0];
				
				// need to fill in LSB and MSB depending on cycle
				if (odd_even ==1'b1) U[0]<=U_buf[0][7:0];
				else U[0]<= U_buf[0][15:8];
				
				
				V[5]<=V[4];
				V[4]<=V[3];
				V[3]<=V[2];
				V[2]<=V[1];
				V[1]<=V[0];
				
				// need to fill in LSB and MSB depending on cycle
				if (odd_even ==1'b1) V[0]<=V_buf[0][7:0];
				else V[0]<= V_buf[0][15:8];
			
				end
				//fill in U' V' 
				
				U_prime <=U_prime+Mult_result_0;
				V_prime <=V_prime+Mult_result_1;
				
				//MULTIPLICATIONS
				Mult_op_0_1<=U[0];
				Mult_op_0_2<= 32'sd21;
				Mult_op_1_1<=V[0];
				Mult_op_1_2<= 32'sd21;
				Mult_op_2_1<=0;
				Mult_op_2_2<= 32'sd1;
				Mult_op_3_1<=0;
				Mult_op_3_2<= 32'sd1;
				
				
				//FILL IN SOME RGB
				R_EVEN<=R_EVEN;
				G_EVEN<=G_EVEN;
				B_EVEN<=B_EVEN;
				R_ODD<=R_ODD;
				G_ODD<=(G_ODD+Mult_result_2);
				B_ODD<=(B_ODD+Mult_result_3);
				
					//// Anthony For Lead Out Special Case
				
				OP3_BUF<=Mult_result_0;
				OP4_BUF<=Mult_result_1;
				
				
			
			
				
				
			
				
				//end
				
				/////// Finish
				
				
				M1_state<= CC_6;
				//M1_Completed <= 1'b1;
				//SRAM_we_n<=1'b0;
				
				
				
				end
				CC_6: begin
				
				OP5_BUF<=Mult_result_0;
				OP6_BUF <= Mult_result_1;
				
				SRAM_we_n<= 1'b1;
				V_buf[0] <= V_buf[0] ;
				
				
				if (odd_even ==1'b1)begin	
				//special case in here
				V_buf[0] <= SRAM_read_data;
				SRAM_address <= U_OFFSET+U_OFFSET_COUNTER;
				U_OFFSET_COUNTER<= U_OFFSET_COUNTER+1'd1;
				end
				
				
				M1_state<= CC_0;
	
				if (Lead_Out_Flag == 1) begin
				//dont do anything to the V
				
				Column_Counter<=0;
				SRAM_address <= U_OFFSET;
				U_OFFSET_COUNTER<= U_OFFSET_COUNTER;
				M1_state <=S_LEADOUT_0; // begin lead out
			
				end
				
				
				

			
				//fill in U' V' READY HERE U'6U'7 
				
				U_prime <=(U_prime+Mult_result_0)>>>8;
				V_prime <=(V_prime+Mult_result_1)>>>8;
				
				
				
			
//				if(Column_Counter==12'd318) begin
//				M1_state<= S_LEADIN_0;
//				Column_Counter<=0;
				//end
				end
				//******************************************************Lead Out Begins//**************************************************************
				S_LEADOUT_0: begin
					// reset the flag
					Lead_Out_Flag<=1'd0;
					SRAM_we_n<= 1'b0;
					
					SRAM_address <= RGB_OFFSET+RGB_OFFSET_COUNTER;
					RGB_OFFSET_COUNTER<= RGB_OFFSET_COUNTER+1'd1;
					SRAM_write_data <= {G_ODD_SEND, B_ODD_SEND};
					
					
					// adding prime to the buffer
					U_prime_buf_odd_U1<=U_prime;
					V_prime_buf_odd_V1<=V_prime;
					
					U_prime<=9'd128;
					V_prime<=9'd128;
					
					//MULTIPLICATIONS
					Mult_op_0_1<=U[4];
					Mult_op_0_2<= 32'sd21;
					Mult_op_1_1<=V[4];
					Mult_op_1_2<= 32'sd21;
					Mult_op_2_1<=Y_buf[0][15:8]-9'd16; // even case ** question for when do you upate y prime
					Mult_op_2_2<= 32'sd76284;
					Mult_op_3_1<=V[3]-8'd128;
					Mult_op_3_2<= 32'sd104595;
					
					
					//reest all RGB BOTH EVEN AND ODD
					R_EVEN<=0;
					G_EVEN<=0;
					B_EVEN<=0;
					R_EVEN_2<=0;
					G_EVEN_2<=0;
					B_EVEN_2<=0;
					R_ODD<=0;
					G_ODD<=0;
					B_ODD<=0;
					R_ODD_2<=0;
					G_ODD_2<=0;
					B_ODD_2<=0;
					M1_state<= S_LEADOUT_1;
					
				end
				
				S_LEADOUT_1: begin
				
				//Y14/15
					SRAM_we_n <= 1'b1;
					SRAM_address <= Y_OFFSET+Y_OFFSET_COUNTER;
					Y_OFFSET_COUNTER<= Y_OFFSET_COUNTER+1'd1;
					Column_Counter<=Column_Counter+1'd1;
				
					// addition
					U_prime<=U_prime+Mult_result_0;
					V_prime<=V_prime+Mult_result_1;
					//multiplication
					Mult_op_0_1<=U[3];
					Mult_op_0_2<= -32'sd52;
					Mult_op_1_1<=V[3];
					Mult_op_1_2<= -32'sd52;
					Mult_op_2_1<=U[3]-8'd128; 
					Mult_op_2_2<= -32'sd25624;
					Mult_op_3_1<=V[3]-8'd128;
					Mult_op_3_2<= -32'sd53281;
					//RGB Values 
					R_EVEN<=(Mult_result_2+Mult_result_3);
					G_EVEN<=Mult_result_2;
					B_EVEN<=Mult_result_2;
					
					M1_state<= S_LEADOUT_2;
				end
				
				S_LEADOUT_2: begin
				// addition
					U_prime<=U_prime+Mult_result_0;
					V_prime<=V_prime+Mult_result_1;
				//multiplication
					Mult_op_0_1<=U[1];
					Mult_op_0_2<= 32'sd159;
					Mult_op_1_1<=V[1];
					Mult_op_1_2<= 32'sd159;
					Mult_op_2_1<=U[3]-8'd128; 
					Mult_op_2_2<= 32'sd132251;
					Mult_op_3_1<=Y_buf[0][7:0]-9'd16; // odd case
					Mult_op_3_2<= 32'sd76284;
					
				//RGB Values 
					//r312 AND g312 READY
					
					G_EVEN<=(G_EVEN+Mult_result_2+Mult_result_3);
					
					M1_state<= S_LEADOUT_3;
				end
				
				S_LEADOUT_3: begin
				// writing the data
					SRAM_we_n<= 1'b0;
					SRAM_address <= RGB_OFFSET+RGB_OFFSET_COUNTER;
					RGB_OFFSET_COUNTER<= RGB_OFFSET_COUNTER+1'd1;
					SRAM_write_data <= {R_EVEN_SEND, G_EVEN_SEND};
				// Buffer
					OP1_BUF<=Mult_result_0;
					OP2_BUF <= Mult_result_1;
				// addition
					U_prime<=U_prime+OP1_BUF+Mult_result_0;
					V_prime<=V_prime+OP2_BUF+Mult_result_1;
				//multiplication
					Mult_op_0_1<=U[0];
					Mult_op_0_2<= -32'sd52;
					Mult_op_1_1<=V[0];
					Mult_op_1_2<= -32'sd52;
					Mult_op_2_1<=V_prime_buf_odd_V1-8'd128; 
					Mult_op_2_2<= 32'sd104595;
					Mult_op_3_1<=U_prime_buf_odd_U1-8'd128;
					Mult_op_3_2<= -32'sd25624;
				//RGB Values 
					
					B_EVEN<=(B_EVEN+Mult_result_2);
					R_ODD<=Mult_result_3;
					G_ODD<=Mult_result_3;
					B_ODD<=Mult_result_3;
					
					M1_state<= S_LEADOUT_4;
				end
				
				S_LEADOUT_4: begin  // M
				//Y16/17
					SRAM_we_n <= 1'b1;
					SRAM_address <= Y_OFFSET+Y_OFFSET_COUNTER;
					Y_OFFSET_COUNTER<= Y_OFFSET_COUNTER+1'd1;
					Column_Counter<=Column_Counter+1'd1;
				
				
				// Buffer
					Y_buf[0]<=SRAM_read_data;
					
					OP7_BUF<=Mult_result_0;
					OP8_BUF <= Mult_result_1;
				// addition
					U_prime<=(U_prime+Mult_result_0+OP5_BUF)>>>8;
					V_prime<=(V_prime+Mult_result_1+OP6_BUF)>>>8;
				//multiplication
					Mult_op_0_1<=U[0];
					Mult_op_0_2<= 32'sd159;
					Mult_op_1_1<=V[0];
					Mult_op_1_2<= 32'sd159;
					Mult_op_2_1<=V_prime_buf_odd_V1-8'd128; 
					Mult_op_2_2<= -32'sd53281;
					Mult_op_3_1<=U_prime_buf_odd_U1-8'd128;
					Mult_op_3_2<= 32'sd132251;
					
				//RGB Values 
					R_ODD<=(R_ODD+Mult_result_2);
					G_ODD<=G_ODD+Mult_result_3;
					
					M1_state<= S_LEADOUT_5;
				
				end
				
				S_LEADOUT_5: begin //N
				
				
				//Y18/19
					SRAM_we_n <= 1'b1;
					SRAM_address <= Y_OFFSET+Y_OFFSET_COUNTER;
					Y_OFFSET_COUNTER<= Y_OFFSET_COUNTER+1'd1;
					Column_Counter<=Column_Counter+1'd1;
					
				// Buffer
					OP1_5BUF<=Mult_result_0;
					OP2_5BUF <= Mult_result_1;
				
				//multiplication
					Mult_op_0_1<=U[3];
					Mult_op_0_2<= 32'sd21;
					Mult_op_1_1<=V[3];
					Mult_op_1_2<= 32'sd21;
					Mult_op_2_1<=Y_buf[0][15:8]-9'd16;// not update properly have to be before ask 
					Mult_op_2_2<= 32'sd76284;
					Mult_op_3_1<=V[2]-8'd128;
					Mult_op_3_2<= 32'sd104595;
					
				//RGB Values 
					G_ODD<=(G_ODD+Mult_result_2);
					B_ODD<=(B_ODD+Mult_result_3);
				
				// adding prime to the buffer
					U_prime_buf_odd_U1<=U_prime;
					V_prime_buf_odd_V1<=V_prime;
					
					U_prime<=9'd128;
					V_prime<=9'd128;
				
					M1_state<= S_LEADOUT_6;
				end
				
				S_LEADOUT_6: begin//O
					// writing the data
					SRAM_we_n<= 1'b0;
					SRAM_address <= RGB_OFFSET+RGB_OFFSET_COUNTER;
					RGB_OFFSET_COUNTER<= RGB_OFFSET_COUNTER+1'd1;
					SRAM_write_data <= {B_EVEN_SEND, R_ODD_SEND};
					// addition
					U_prime<=U_prime+Mult_result_0;
					V_prime<=V_prime+Mult_result_1;
					//multiplication
					Mult_op_0_1<=U[2];
					Mult_op_0_2<= -32'sd52;
					Mult_op_1_1<=V[2];
					Mult_op_1_2<= -32'sd52;
					Mult_op_2_1<=U[2]-8'd128;
					Mult_op_2_2<= -32'sd25624;
					Mult_op_3_1<=V[2]-8'd128;
					Mult_op_3_2<= -32'sd53281;
					
					//RGB Values 
					R_EVEN<=(Mult_result_2+Mult_result_3);
					//this was bug FIX 
					G_EVEN<=Mult_result_2;
					B_EVEN<=Mult_result_2;
				
					
				
					M1_state<= S_LEADOUT_7;
				end
				
				S_LEADOUT_7: begin//P
				// writing the data
					SRAM_we_n<= 1'b0;
					SRAM_address <= RGB_OFFSET+RGB_OFFSET_COUNTER;
					RGB_OFFSET_COUNTER<= RGB_OFFSET_COUNTER+1'd1;
					SRAM_write_data <= {G_ODD_SEND, B_ODD_SEND};
					
				// store 16/17
					Y_buf[0]<=SRAM_read_data;
		
					
				// addition
					U_prime<=(U_prime+Mult_result_0+OP1_5BUF+OP1_BUF+OP7_BUF+OP5_BUF)>>>8;
					V_prime<=(V_prime+Mult_result_1+OP2_5BUF+OP2_BUF+OP8_BUF+OP6_BUF)>>>8;
				//multiplication
					Mult_op_0_1<=U[2]-8'd128;
					Mult_op_0_2<= 32'sd132251;
					Mult_op_1_1<=Y_buf[0][7:0]-9'd16;
					Mult_op_1_2<= 32'sd76284;
					Mult_op_2_1<=V_prime_buf_odd_V1-8'd128;
					Mult_op_2_2<= 32'sd104595;
					Mult_op_3_1<=U_prime_buf_odd_U1-8'd128;
					Mult_op_3_2<= -32'sd25624;
				
				//RGB
					G_EVEN<=(G_EVEN+Mult_result_2+Mult_result_3);
					
					M1_state<= S_LEADOUT_8;
				end
				
				S_LEADOUT_8: begin //Q
				// writing the data
					SRAM_we_n<= 1'b0;
					SRAM_address <= RGB_OFFSET+RGB_OFFSET_COUNTER;
					RGB_OFFSET_COUNTER<= RGB_OFFSET_COUNTER+1'd1;
					SRAM_write_data <= {R_EVEN_SEND, G_EVEN_SEND};
				// Buffer
				//	OP5_BUF<=Mult_result_1;
				//multiplication
					Mult_op_0_1<=V_prime_buf_odd_V1-8'd128;
					Mult_op_0_2<= -32'sd53281;
					Mult_op_1_1<=U_prime_buf_odd_U1-8'd128;
					Mult_op_1_2<= 32'sd132251;
					Mult_op_2_1<=U[2];
					Mult_op_2_2<= 32'sd21;
					Mult_op_3_1<=V[2];
					Mult_op_3_2<= 32'sd21;
					
					// adding prime to the buffer //U316,317
					U_prime_buf_odd_U1<=U_prime;
					V_prime_buf_odd_V1<=V_prime;
					
					U_prime<=9'd128;
					V_prime<=9'd128;
				//YBUF
					Y_buf[1]<=SRAM_read_data;
					
				//RGB
					B_EVEN<=(B_EVEN+Mult_result_0);
					R_ODD<=(Mult_result_1+Mult_result_2);
					G_ODD<=Mult_result_1+Mult_result_3;
					B_ODD<=Mult_result_1;
					
					M1_state<= S_LEADOUT_9;
				end
				
				S_LEADOUT_9: begin //R
				// writing the data
					SRAM_we_n<= 1'b0;
					SRAM_address <= RGB_OFFSET+RGB_OFFSET_COUNTER;
					RGB_OFFSET_COUNTER<= RGB_OFFSET_COUNTER+1'd1;
					SRAM_write_data <= {B_EVEN_SEND, R_ODD_SEND};
				// adding prime to the buffer   Anthony WHY?
					//U_prime_buf_odd_U1<=U_prime;
					//V_prime_buf_odd_V1<=V_prime;
				// addition	
					U_prime<=U_prime+ Mult_result_2;
					V_prime<=V_prime+Mult_result_3;
				//multiplication
					Mult_op_0_1<=Y_buf[0][15:8]-9'd16;
					Mult_op_0_2<= 32'sd76284;
					Mult_op_1_1<=V[1]-8'd128;
					Mult_op_1_2<= 32'sd104595;
					Mult_op_2_1<=U[1]-8'd128;
					Mult_op_2_2<= -32'sd25624;
					Mult_op_3_1<=V[1]-8'd128;
					Mult_op_3_2<= -32'sd53281;
				//RGB
					
					G_ODD<=(G_ODD+Mult_result_0);
					B_ODD<=B_ODD+Mult_result_1;
					
					M1_state<= S_LEADOUT_10;
				end
				
				S_LEADOUT_10: begin //s
				// writing the data
					SRAM_we_n<= 1'b0;
					SRAM_address <= RGB_OFFSET+RGB_OFFSET_COUNTER;
					RGB_OFFSET_COUNTER<= RGB_OFFSET_COUNTER+1'd1;
					SRAM_write_data <= {G_ODD_SEND, B_ODD_SEND};
					
				// addition	
					U_prime<=(U_prime+OP3_BUF+OP1_5BUF+OP1_5BUF+OP5_BUF+OP7_BUF)>>>8;
					V_prime<=(V_prime+OP4_BUF+OP2_5BUF+OP2_5BUF+OP6_BUF+OP8_BUF)>>>8;	
					
				
				//multiplication
					Mult_op_0_1<=U[1]-8'd128;;
					Mult_op_0_2<= 32'sd132251;
					Mult_op_1_1<=Y_buf[0][7:0]-9'd16;
					Mult_op_1_2<= 32'sd76284;
					Mult_op_2_1<=V_prime_buf_odd_V1-8'd128;
					Mult_op_2_2<= 32'sd104595;
					Mult_op_3_1<=U_prime_buf_odd_U1-8'd128;
					Mult_op_3_2<= -32'sd25624;
					
				//RGB
					
					R_EVEN<=(Mult_result_0+Mult_result_1);
					G_EVEN<=(Mult_result_0+Mult_result_2+Mult_result_3);
					B_EVEN<=Mult_result_0;
					
					M1_state<= S_LEADOUT_11;
				
				end
				
				S_LEADOUT_11: begin //t
				
				// writing the data
					SRAM_we_n<= 1'b0;
					SRAM_address <= RGB_OFFSET+RGB_OFFSET_COUNTER;
					RGB_OFFSET_COUNTER<= RGB_OFFSET_COUNTER+1'd1;
					SRAM_write_data <= {R_EVEN_SEND, G_EVEN_SEND};
				
			
				// buffer
					OP5_BUF<=Mult_result_1;
					
				// adding prime to the buffer
					U_prime_buf_odd_U1<=U_prime;
					V_prime_buf_odd_V1<=V_prime;
				// addition	
					U_prime<=9'd128;
					V_prime<=9'd128;
					
				//multiplication use last Y buf
					Mult_op_0_1<=V_prime_buf_odd_V1-8'd128;
					Mult_op_0_2<= -32'sd53281;
					Mult_op_1_1<=U_prime_buf_odd_U1-8'd128;
					Mult_op_1_2<= 32'sd132251;
					Mult_op_2_1<=Y_buf[1][15:8]-9'd16;
					Mult_op_2_2<= 32'sd76284;
					Mult_op_3_1<=V[0]-8'd128;
					Mult_op_3_2<= 32'sd104595;
				//RGB
					
					
					B_EVEN<=(B_EVEN+Mult_result_0);
					R_ODD<=(Mult_result_1+Mult_result_2);
					G_ODD<=Mult_result_1+Mult_result_3;
					
					M1_state<= S_LEADOUT_12;
					
				
				end
				
				S_LEADOUT_12: begin //u
				// writing the data
					SRAM_we_n<= 1'b1;
			
				
				//multiplication uses last y buf
					Mult_op_0_1<=U[0]-8'd128;
					Mult_op_0_2<= -32'sd25624;
					Mult_op_1_1<=V[0]-8'd128;
					Mult_op_1_2<= -32'sd53281;
					Mult_op_2_1<=U[0]-8'd128;
					Mult_op_2_2<= 32'sd132251;
					Mult_op_3_1<=Y_buf[1][7:0]-9'd16;
					Mult_op_3_2<= 32'sd76284;
					
				//RGB
					
					
					R_EVEN<=(Mult_result_2+Mult_result_3);
					G_EVEN<=Mult_result_2;
					G_ODD<=(G_ODD+Mult_result_0);
					B_ODD<=(OP5_BUF+Mult_result_1);
					
					
					M1_state<= S_LEADOUT_13;
					
				
				end
				
				S_LEADOUT_13: begin //v
				
				
				// writing the data
					SRAM_we_n<= 1'b0;
					SRAM_address <= RGB_OFFSET+RGB_OFFSET_COUNTER;
					RGB_OFFSET_COUNTER<= RGB_OFFSET_COUNTER+1'd1;
					SRAM_write_data <= {B_EVEN_SEND, R_ODD_SEND};
					
					
					//RGB BUFF
					G_ODD_2<=G_ODD;
					B_ODD_2<=B_ODD;
					
				
				//multiplication
					Mult_op_0_1<=V_prime_buf_odd_V1-8'd128;
					Mult_op_0_2<= 32'sd104595;
					Mult_op_1_1<=U_prime_buf_odd_U1-8'd128;
					Mult_op_1_2<= -32'sd25624;
					Mult_op_2_1<=V_prime_buf_odd_V1-8'd128;
					Mult_op_2_2<= -32'sd53281;
					Mult_op_3_1<=U_prime_buf_odd_U1-8'd128;
					Mult_op_3_2<= 32'sd132251;
				
				//RGB
					
					
					
					G_EVEN<=(G_EVEN+Mult_result_0+Mult_result_1);
					B_EVEN<=(G_EVEN+Mult_result_2);
					
					R_ODD<=Mult_result_3;
					G_ODD<=Mult_result_3;
					B_ODD<=Mult_result_3;
					
					M1_state<= S_LEADOUT_14;
					
				end
				
				S_LEADOUT_14: begin//w
				// writing the data
					SRAM_we_n<= 1'b0;
					SRAM_address <= RGB_OFFSET+RGB_OFFSET_COUNTER;
					RGB_OFFSET_COUNTER<= RGB_OFFSET_COUNTER+1'd1;
					SRAM_write_data <= {G_ODD_2_SEND,B_ODD_2_SEND};
					
//					
//				// Buffer
//				R_EVEN_2<=R_EVEN;
//				G_EVEN_2<=G_EVEN;
				
					
				//RGB
				
					R_ODD<=(R_ODD+Mult_result_0);
					G_ODD<=(G_ODD+Mult_result_1+Mult_result_2);
					B_ODD<=(B_ODD+Mult_result_3);
				
					M1_state<= S_LEADOUT_15;
				
				end
				
				S_LEADOUT_15: begin //x
				
				// writing the data
					SRAM_we_n<= 1'b0;
					SRAM_address <= RGB_OFFSET+RGB_OFFSET_COUNTER;
					RGB_OFFSET_COUNTER<= RGB_OFFSET_COUNTER+1'd1;
					SRAM_write_data <= {R_EVEN_SEND,G_EVEN_SEND};
					M1_state<= S_LEADOUT_16;
				
				
				end
				
				S_LEADOUT_16: begin //y
				
				
				
				// writing the data
					SRAM_we_n<= 1'b0;
					SRAM_address <= RGB_OFFSET+RGB_OFFSET_COUNTER;
					RGB_OFFSET_COUNTER<= RGB_OFFSET_COUNTER+1'd1;
					SRAM_write_data <= {B_EVEN_SEND, R_ODD_SEND};
					M1_state<= S_LEADOUT_17;
				
				end
				
				S_LEADOUT_17: begin //z
				
				
				// writing the data
					SRAM_we_n<= 1'b0;
					SRAM_address <= RGB_OFFSET+RGB_OFFSET_COUNTER;
					RGB_OFFSET_COUNTER<= RGB_OFFSET_COUNTER+1'd1;
					SRAM_write_data <= {G_ODD_SEND, B_ODD_SEND};
					
					Column_Counter<=1'd0;
					M1_state <= S_LEADIN_0;
					
					if (RGB_OFFSET_COUNTER == 32'd115199) begin
					M1_Completed <=1'b1;
					
					
					end
				
					R_EVEN<=0;
					B_EVEN<=0;
					G_EVEN<=0;
					R_ODD<=0;
					G_ODD<=0;
					B_ODD<=0;
					
					R_EVEN_2<=0;
					B_EVEN_2<=0;
					G_EVEN_2<=0;
					R_ODD_2<=0;
					G_ODD_2<=0;
					B_ODD_2<=0;
					
					//RESET VU
					V_prime<=0;
					U_prime<=0;
					V_prime_buf_odd_V1<=0;
					V_prime_buf_odd_V3<=0;
					U_prime_buf_odd_U1<=0;
					U_prime_buf_odd_U3<=0;
					U_buf[0]<=0;
					V_buf[0] <=0;
					Y_buf[0] <=0;
					Y_buf[1] <=0;
					
					OP1_BUF<=0;
					OP2_BUF<=0;
					OP3_BUF<=0;
					OP4_BUF<=0;
					OP5_BUF<=0;
					OP6_BUF<=0;
					OP7_BUF<=0;
					OP8_BUF<=0;
					U_OFFSET_COUNTER<=U_OFFSET_COUNTER-18'd1;
					V_OFFSET_COUNTER<=V_OFFSET_COUNTER-18'd1;
					

					U[5]<=0;
					U[4]<=0;
					U[3]<=0;
					U[2]<=0;
					U[1]<=0;
					U[0]<=0;
					
					V[5]<=0;
					V[4]<=0;
					V[3]<=0;
					V[2]<=0;
					V[1]<=0;
					V[0]<=0;
					
				end
				
				
				//******************************************************Lead out Ends//**************************************************************
				
			
		default: M1_state <= S_LEADIN_0;
		endcase
		end
end




assign Mult_result_long_0 = Mult_op_0_1 * Mult_op_0_2;
assign Mult_result_0 = Mult_result_long_0[31:0];

assign Mult_result_long_1 = Mult_op_1_1 * Mult_op_1_2;
assign Mult_result_1 = Mult_result_long_1[31:0];

assign Mult_result_long_2 = Mult_op_2_1 * Mult_op_2_2;
assign Mult_result_2 = Mult_result_long_2[31:0];

assign Mult_result_long_3 = Mult_op_3_1 * Mult_op_3_2;
assign Mult_result_3 = Mult_result_long_3[31:0];

always_comb begin
// if all MSB are 1
    R_EVEN_SEND =R_EVEN[23:16];
    if (|R_EVEN[30:24]) R_EVEN_SEND = 8'hFF;
    if (R_EVEN[31]) R_EVEN_SEND = 8'h00;

end 


always_comb begin
// if all MSB are 1
    G_EVEN_SEND=G_EVEN[23:16];
    if (|G_EVEN[30:24]) G_EVEN_SEND = 8'hFF;
    if (G_EVEN[31]) G_EVEN_SEND = 8'h00;

end 
always_comb begin
// if all MSB are 1
    B_EVEN_SEND=B_EVEN[23:16];
    if (|B_EVEN[30:24]) B_EVEN_SEND = 8'hFF;
    if (B_EVEN[31]) B_EVEN_SEND = 8'h00;

end 

always_comb begin
// if all MSB are 1
    R_ODD_SEND=R_ODD[23:16];
    if (|R_ODD[30:24]) R_ODD_SEND = 8'hFF;
    if (R_ODD[31]) R_ODD_SEND = 8'h00;

end 

always_comb begin
// if all MSB are 1
    G_ODD_SEND=G_ODD[23:16];
    if (|G_ODD[30:24]) G_ODD_SEND = 8'hFF;
    if (G_ODD[31]) G_ODD_SEND = 8'h00;

end 
always_comb begin
// if all MSB are 1
    B_ODD_SEND=B_ODD[23:16];
    if (|B_ODD[30:24]) B_ODD_SEND = 8'hFF;
    if (B_ODD[31]) B_ODD_SEND = 8'h00;

end 
//////2//////

always_comb begin
// if all MSB are 1
    R_EVEN_2_SEND =R_EVEN_2[23:16];
    if (|R_EVEN_2[30:24]) R_EVEN_2_SEND = 8'hFF;
    if (R_EVEN_2[31]) R_EVEN_2_SEND = 8'h00;

end 


always_comb begin
// if all MSB are 1
    G_EVEN_2_SEND=G_EVEN_2[23:16];
    if (|G_EVEN_2[30:24]) G_EVEN_2_SEND = 8'hFF;
    if (G_EVEN_2[31]) G_EVEN_2_SEND = 8'h00;

end 
always_comb begin
// if all MSB are 1
    B_EVEN_2_SEND=B_EVEN_2[23:16];
    if (|B_EVEN_2[30:24]) B_EVEN_2_SEND = 8'hFF;
    if (B_EVEN_2[31]) B_EVEN_2_SEND = 8'h00;

end 

always_comb begin
// if all MSB are 1
    R_ODD_2_SEND=R_ODD_2[23:16];
    if (|R_ODD_2[30:24]) R_ODD_2_SEND = 8'hFF;
    if (R_ODD_2[31]) R_ODD_2_SEND = 8'h00;

end 

always_comb begin
// if all MSB are 1
    G_ODD_2_SEND=G_ODD_2[23:16];
    if (|G_ODD_2[30:24]) G_ODD_2_SEND = 8'hFF;
    if (G_ODD_2[31]) G_ODD_2_SEND = 8'h00;

end 
always_comb begin
// if all MSB are 1
    B_ODD_2_SEND=B_ODD_2[23:16];
    if (|B_ODD_2[30:24]) B_ODD_2_SEND = 8'hFF;
    if (B_ODD_2[31]) B_ODD_2_SEND = 8'h00;

end

///test




endmodule 