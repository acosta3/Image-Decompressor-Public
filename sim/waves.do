# activate waveform simulation

view wave

# format signal names in waveform

configure wave -signalnamewidth 1
configure wave -timeline 0
configure wave -timelineunits us

# add signals to waveform

add wave -divider -height 20 {Top-level signals}
add wave -bin UUT/CLOCK_50_I
add wave -bin UUT/resetn
add wave UUT/top_state

add wave -divider -height 10 {VGA signals}


#add wave -bin UUT/VGA_unit/VGA_HSYNC_O
#add wave -bin UUT/VGA_unit/VGA_VSYNC_O
#add wave -uns UUT/VGA_unit/pixel_X_pos
#add wave -uns UUT/VGA_unit/pixel_Y_pos
#add wave -hex UUT/VGA_unit/VGA_red
#add wave -hex UUT/VGA_unit/VGA_green
#add wave -hex UUT/VGA_unit/VGA_blue
#add wave -bin UUT/VGA_unit/VGA_SRAM_state





add wave -uns UUT/UART_timer

#add wave -divider -height 10 {Address Counters}
#add wave -dec  UUT/M1_Unit/Y_OFFSET_COUNTER
#add wave -dec  UUT/M1_Unit/U_OFFSET_COUNTER
#add wave -dec  UUT/M1_Unit/V_OFFSET_COUNTER
#add wave -dec  UUT/M1_Unit/RGB_OFFSET_COUNTER
#add wave -dec  UUT/M1_Unit/Column_Counter
#add wave -dec  UUT/M1_Unit/Lead_Out_Flag

add wave -divider -height 10 {SRAM signals}
add wave -uns UUT/SRAM_address
add wave -hex UUT/SRAM_write_data
add wave -bin UUT/SRAM_we_n
add wave -bin UUT/SRAM_read_data
add wave -hex UUT/SRAM_read_data
add wave -divider -height 10 {M3 Signals}
add wave -uns UUT/M3_Unit/M3_state
add wave -uns UUT/M3_Unit/SRAM_read_counter
add wave -bin UUT/M3_Unit/mic_data
add wave -uns UUT/M3_Unit/sample_counter
add wave -uns UUT/M3_Unit/block_counter
add wave -bin UUT/M3_Unit/pre_dequant
add wave -uns UUT/M3_Unit/shift_counter
add wave -uns UUT/M3_Unit/shift_code
add wave -uns UUT/M3_Unit/element_counter
add wave -uns UUT/M3_Unit/ZZC
add wave -uns UUT/M3_Unit/read_counter


add wave -divider -height 10 {M3 Signals_COMBINATIONAL}
add wave -uns UUT/M3_Unit/row_index_4bits
add wave -uns UUT/M3_Unit/col_index_4bits
add wave -dec UUT/M3_Unit/s_prime
add wave -uns UUT/M3_Unit/two_bit_code
add wave -uns UUT/M3_Unit/three_bit_code
add wave -uns UUT/M3_Unit/K_writes_110
add wave -uns UUT/M3_Unit/K_writes_100_101
add wave -uns UUT/M3_Unit/K_writes_111
add wave -uns UUT/M3_Unit/K_writes_00X
add wave -uns UUT/M3_Unit/K_writes_01X
add wave -uns UUT/M3_Unit/s_dequantized
add wave -uns UUT/M3_Unit/s_dequantized
add wave -uns UUT/M3_Unit/new_read
add wave -divider -height 10 {M3 Signals_COMBINATIONAL_NEW}
add wave -bin UUT/M3_Unit/mic_data_comb
add wave -uns UUT/M3_Unit/pre_dequant_comb
add wave -bin UUT/M3_Unit/pre_dequant_comb
add wave -uns UUT/M3_Unit/position_counter
add wave -uns UUT/M3_Unit/pre_dequant_comb
add wave -uns UUT/M3_Unit/shift_sum
add wave -uns UUT/M3_Unit/position_counter
add wave -uns UUT/M3_Unit/shift_counter
add wave -uns UUT/M3_Unit/read_ready_timer
add wave -uns UUT/M3_Unit/insertion_index
add wave -uns UUT/M3_Unit/read_EN



#add wave -uns  UUT/M2_Unit/row_index_POST_IDCT
#add wave -uns  UUT/M2_Unit/col_index_POST_IDCT
#add wave -divider -height 10 {Flags}
#add wave -bin  UUT/M1_Unit/LEADIN_TO_CC_TRANSITION
#add wave -hex  UUT/M1_Unit/M1_Completed
#add wave -hex  UUT/M1_Unit/LEADIN_TO_CC_TRANSITION
#add wave -hex  UUT/M1_Unit/odd_even
#add wave -hex  UUT/M2_Unit/write_s_twos_counter
#add wave -hex  UUT/M2_Unit/row_dp_ram_s
#add wave -uns  UUT/M2_Unit/DPRAM_0
#add wave -uns  UUT/M2_Unit/DPRAM_1
#add wave -dec  UUT/M2_Unit/row_block
#add wave -dec  UUT/M2_Unit/column_block
#add wave -dec  UUT/M2_Unit/column_block_POST_IDCT
#add wave -dec  UUT/M2_Unit/row_block_POST_IDCT
#add wave -dec  UUT/M2_Unit/blocks_written
#add wave -dec  UUT/M2_Unit/blocks_read
#add wave -dec  UUT/M2_Unit/write_column_block
#add wave -dec  UUT/M2_Unit/write_row_block
#add wave -divider -height 10 {write S to DP RAM}
#add wave -hex  UUT/M2_Unit/write_s_twos_counter
#add wave -hex  UUT/M2_Unit/row_dp_ram_s

#add wave -divider -height 10 {M1 Signals}
#add wave UUT/M1_Unit/M1_state
#add wave -hex  UUT/M1_Unit/Mult_op_0_1
#add wave -hex  UUT/M1_Unit/Mult_result_long_0
#add wave -hex  UUT/M1_Unit/Mult_result_0
#add wave -dec  UUT/M1_Unit/SRAM_read_data

#add wave -dec  UUT/M1_Unit/Y_buf
#add wave -hex  UUT/M1_Unit/U_buf
#add wave -hex  UUT/M1_Unit/V_buf

#add wave -uns  UUT/M1_Unit/U
#add wave -uns  UUT/M1_Unit/V
#add wave -uns  UUT/M1_Unit/U_prime
#add wave -uns  UUT/M1_Unit/U_prime_buf_odd_U3
#add wave -uns  UUT/M1_Unit/U_prime_buf_odd_U1
#add wave -uns  UUT/M1_Unit/V_prime
#add wave -uns  UUT/M1_Unit/V_prime_buf_odd_V3
#add wave -uns  UUT/M1_Unit/V_prime_buf_odd_V1

#add wave -dec  UUT/M1_Unit/Mult_result_0
#add wave -dec  UUT/M1_Unit/Mult_result_1
#add wave -dec  UUT/M1_Unit/Mult_result_2
#add wave -dec  UUT/M1_Unit/Mult_result_3
#add wave -dec  UUT/M1_Unit/Mult_op_0_1
#add wave -dec  UUT/M1_Unit/Mult_op_0_2
#add wave -dec  UUT/M1_Unit/Mult_op_1_1
#add wave -dec  UUT/M1_Unit/Mult_op_1_2
#add wave -dec  UUT/M1_Unit/Mult_op_2_1
#add wave -dec  UUT/M1_Unit/Mult_op_2_2
#add wave -dec  UUT/M1_Unit/Mult_op_3_1
#add wave -dec  UUT/M1_Unit/Mult_op_3_2
#add wave -dec  UUT/M1_Unit/Mult_op_0_1_converted
#add wave -dec  UUT/M1_Unit/Mult_op_1_1_converted
#add wave -dec  UUT/M1_Unit/Mult_op_2_1_converted
#add wave -dec  UUT/M1_Unit/Mult_op_3_1_converted
#add wave -dec  UUT/M1_Unit/OP3_BUF
#add wave -dec  UUT/M1_Unit/OP1_5BUF
#add wave -dec  UUT/M1_Unit/OP5_BUF
#add wave -dec  UUT/M1_Unit/OP7_BUF

#add wave -hex  UUT/M1_Unit/OP1_BUF
#add wave -divider -height 10 {RGB Variables}
#add wave -uns  UUT/M1_Unit/R_EVEN
#add wave -hex  UUT/M1_Unit/R_EVEN
#add wave -uns  UUT/M1_Unit/G_EVEN
#add wave -hex  UUT/M1_Unit/G_EVEN
#add wave -uns  UUT/M1_Unit/B_EVEN
#add wave -hex  UUT/M1_Unit/B_EVEN
#add wave -uns  UUT/M1_Unit/R_ODD
#add wave -hex  UUT/M1_Unit/R_ODD
#add wave -uns  UUT/M1_Unit/G_ODD
#add wave -hex  UUT/M1_Unit/G_ODD
#add wave -uns  UUT/M1_Unit/B_ODD
#add wave -hex  UUT/M1_Unit/B_ODD

#add wave -divider -height 10 {M2 VARIABLES}
#add wave -hex  UUT/M2_Unit/M2_state
#add wave -hex  UUT/M2_Unit/col_index
#add wave -hex  UUT/M2_Unit/row_index
#add wave -hex  UUT/M2_Unit/read_address_PRE_IDCT
#add wave -hex  UUT/M2_Unit/Sample_counter
#add wave -hex  UUT/M2_Unit/address_s_prime_0
#add wave -dec  UUT/M2_Unit/WE_s_prime_0
#add wave -dec  UUT/M2_Unit/write_s_prime_0
#add wave -dec  UUT/M2_Unit/dram_address_counter_s_prime
#add wave -uns  UUT/M2_Unit/DPRAM_S_READ_COUNTER
#add wave -uns  UUT/M2_Unit/Write_Sample_counter
#add wave -divider -height 10 {DP T VARIABLES}
#add wave -dec  UUT/M2_Unit/address_T_0
#add wave -dec  UUT/M2_Unit/address_T_1
#add wave -dec  UUT/M2_Unit/write_T_0
#add wave -dec  UUT/M2_Unit/write_T_1
#add wave -dec  UUT/M2_Unit/WE_T_0
#add wave -dec  UUT/M2_Unit/WE_T_1
#add wave -dec  UUT/M2_Unit/dram_address_counter_T
#add wave -dec  UUT/M2_Unit/read_data_s_prime_0
#add wave -dec  UUT/M2_Unit/read_data_s_prime_1
#add wave -hex  UUT/M2_Unit/row_index_DPRAM_S_Prime
#add wave -hex  UUT/M2_Unit/col_index_DPRAM_S_Prime
#add wave -hex  UUT/M2_Unit/blocks_written
#add wave -hex  UUT/M2_Unit/blocks_read

#add wave -divider -height 10 {DP S VARIABLES}
#add wave -uns  UUT/M2_Unit/address_S_0
#add wave -uns  UUT/M2_Unit/address_S_1
#add wave -dec  UUT/M2_Unit/write_S_0
#add wave -dec  UUT/M2_Unit/write_S_1
#add wave -dec  UUT/M2_Unit/WE_S_0 
#add wave -dec  UUT/M2_Unit/WE_S_1 
#add wave -dec  UUT/M2_Unit/dram_address_counter_T
#add wave -dec  UUT/M2_Unit/read_data_s_prime_0
#add wave -dec  UUT/M2_Unit/read_data_s_prime_1
#add wave -dec  UUT/M2_Unit/read_data_S_0 
#add wave -dec  UUT/M2_Unit/read_data_S_1
#add wave -dec  UUT/M2_Unit/MSB
#add wave -dec  UUT/M2_Unit/LSB


#add wave -dec  UUT/M2_Unit/DS_DP_S0
#add wave -dec  UUT/M2_Unit/DS_DP_S1
#add wave -dec  UUT/M2_Unit/DS_DP_S2
#add wave -dec  UUT/M2_Unit/DS_DP_S3




#add wave -dec  UUT/M2_Unit/S_counter

#add wave -divider -height 10 {FLAGS}
#add wave -dec  UUT/M2_Unit/flag_increment_row
#add wave -dec  UUT/M2_Unit/C_multiplier_row
#add wave -dec  UUT/M2_Unit/C_multiplier_column

#add wave -uns  UUT/M2_Unit/c_index_0
#add wave -uns  UUT/M2_Unit/c_index_1
#add wave -uns  UUT/M2_Unit/c_index_2
#add wave -uns  UUT/M2_Unit/c_index_3
#add wave -dec  UUT/M2_Unit/read_address_compute_S

#add wave -dec  UUT/M2_Unit/ROW_ADDRESS_T
#add wave -dec  UUT/M2_Unit/COL_ADDRESS_T 


#add wave -divider -height 10 {S BUFFER VARIABLES}
#add wave -dec  UUT/M2_Unit/S_0
#add wave -dec  UUT/M2_Unit/S_1
#add wave -dec  UUT/M2_Unit/S_2
#add wave -dec  UUT/M2_Unit/S_3
#add wave -dec  UUT/M2_Unit/S_2_BUF
#add wave -dec  UUT/M2_Unit/S_3_BUF
#add wave -dec  UUT/M2_Unit/Y_flag_read
#add wave -dec  UUT/M2_Unit/U_flag_read
#add wave -dec  UUT/M2_Unit/Y_flag_write
#add wave -dec  UUT/M2_Unit/U_flag_write
#add wave -divider -height 10 {BUFFER VARIABLES}
#add wave -dec  UUT/M2_Unit/T_0
#add wave -dec  UUT/M2_Unit/T_1
#add wave -dec  UUT/M2_Unit/T_2
#add wave -dec  UUT/M2_Unit/T_3

#add wave -divider -height 10 {DP T VARIABLES MULTIPLIERS}
#add wave -dec  UUT/M2_Unit/Mult_M2_op_0_1
#add wave -dec  UUT/M2_Unit/Mult_M2_op_0_2
#add wave -dec  UUT/M2_Unit/Mult_M2_op_1_1
#add wave -dec  UUT/M2_Unit/Mult_M2_op_1_2
#add wave -dec  UUT/M2_Unit/Mult_M2_op_2_1
#add wave -dec  UUT/M2_Unit/Mult_M2_op_2_2
#add wave -dec  UUT/M2_Unit/Mult_M2_op_3_1
#add wave -dec  UUT/M2_Unit/Mult_M2_op_3_2
#add wave -dec  UUT/M2_Unit/Mult_M2_result_0
#add wave -dec  UUT/M2_Unit/Mult_M2_result_1
#add wave -dec  UUT/M2_Unit/Mult_M2_result_2
#add wave -dec  UUT/M2_Unit/Mult_M2_result_3

#add wave -dec  UUT/M1_Unit/Mult_result_0
#add wave -dec  UUT/M1_Unit/Mult_result_1
#add wave -dec  UUT/M1_Unit/Mult_result_2
#add wave -dec  UUT/M1_Unit/Mult_result_3
#add wave -dec  UUT/M1_Unit/Mult_op_0_1
#add wave -dec  UUT/M1_Unit/Mult_op_0_2
#add wave -dec  UUT/M1_Unit/Mult_op_1_1
#add wave -dec  UUT/M1_Unit/Mult_op_1_2
#add wave -dec  UUT/M1_Unit/Mult_op_2_1
#add wave -dec  UUT/M1_Unit/Mult_op_2_2
#add wave -dec  UUT/M1_Unit/Mult_op_3_1
#add wave -dec  UUT/M1_Unit/Mult_op_3_2
#add wave -dec  UUT/M1_Unit/Mult_op_0_1_converted
#add wave -dec  UUT/M1_Unit/Mult_op_1_1_converted
#add wave -dec  UUT/M1_Unit/Mult_op_2_1_converted
#add wave -dec  UUT/M1_Unit/Mult_op_3_1_converted
#add wave -dec  UUT/M1_Unit/OP3_BUF
#add wave -dec  UUT/M1_Unit/OP1_5BUF
#add wave -dec  UUT/M1_Unit/OP5_BUF
#add wave -dec  UUT/M1_Unit/OP7_BUF

#add wave -hex  UUT/M1_Unit/OP1_BUF
#add wave -divider -height 10 {RGB Variables}
#add wave -uns  UUT/M1_Unit/R_EVEN
#add wave -hex  UUT/M1_Unit/R_EVEN
#add wave -uns  UUT/M1_Unit/G_EVEN
#add wave -hex  UUT/M1_Unit/G_EVEN
#add wave -uns  UUT/M1_Unit/B_EVEN
#add wave -hex  UUT/M1_Unit/B_EVEN
#add wave -uns  UUT/M1_Unit/R_ODD
#add wave -hex  UUT/M1_Unit/R_ODD
#add wave -uns  UUT/M1_Unit/G_ODD
#add wave -hex  UUT/M1_Unit/G_ODD
#add wave -uns  UUT/M1_Unit/B_ODD
#add wave -hex  UUT/M1_Unit/B_ODD
#add wave -uns  UUT/M1_Unit/B_EVEN_2
#add wave -uns  UUT/M1_Unit/R_ODD_2
#add wave -uns  UUT/M1_Unit/B_EVEN_2_SEND
#add wave -uns  UUT/M1_Unit/R_ODD_2_SEND
