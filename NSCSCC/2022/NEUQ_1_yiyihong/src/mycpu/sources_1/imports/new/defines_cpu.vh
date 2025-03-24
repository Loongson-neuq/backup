//////////////////////////////////////////////////////////////////////////////////
/*by srmk*/
//////////////////////////////////////////////////////////////////////////////////

`define rstn_enable 		1'b0 
`define rstn_disable 		1'b1
`define true_v 				1'b1
`define false_v 			1'b0
`define zero_32 			32'b0
`define addr_bus 			31:0 
`define data_bus 			31:0 
`define inst_bus 			31:0 
`define reg_addr_bus		4:0 
`define zero_reg_addr		5'b00000
`define except_bus			8:0 	//{invalid,wr_addr_st,int,wr_pc,wr_addr_ld,of,syscall,break,eret}

`define exc_non 			9'b000000000
`define exc_invalid			9'b100000000
`define exc_wraddr_st		9'b010000000
`define exc_int 			9'b001000000 
`define exc_wrpc			9'b000100000
`define exc_wraddr_ld		9'b000010000 
`define exc_ovfl			9'b000001000 
`define exc_sys				9'b000000100
`define exc_break 			9'b000000010 
`define exc_eret			9'b000000001 			

//fetch 
`define ini_pc 				32'hbfc00000 

//stall
`define stall_bus 			6:0 
`define stall_module_bus 	1:0

//decode_pt1
`define info_decode_pt1_i 	60:0 	//{r_en_1,r_en_2,r_addr_1,r_addr_2,alu_op,alu_sel,immediate_32,w_addr}
`define alu_op_bus			7:0 
`define alu_sel_bus			3:0 

//decode pt2
`define info_data_bus		38:0 	//{w_data,w_addr,w_en,finish}
`define info_cp0_bus		38:0 	//{cp0_w_data,cp0_w_addr,cp0_w_en,cp0_finish}
`define info_hilo_bus		67:0 	//{w_en_hi,w_en_lo,data_hi,data_lo,hi_valid,lo_valid}
`define info_decode_pt2_bus 81:0 	//{w_addr,ope_data_1,ope_data_2,alu_op,alu_sel,delay_slot}

//exe
`define info_exe_bus		76:0   	//{alu_op,alu_sel,delay_slot,mem_data,mem_addr}

//memory
`define sel_bus 			3:0

//inst
`define op_bus 				5:0 
`define ed_bus 				5:0
`define reg_addr_bus		4:0 
`define imme_bus 			15:0  
`define op_index			31:26 
`define rs_index			25:21 
`define rt_index			20:16
`define rd_index			15:11
`define sa_index			10:6 
`define ed_index	        5:0 
`define imme_index			15:0 

`define ex_nop 				6'b000000 
`define ex_nop_op			8'b00000000

`define special_op_1 		6'b000000
	//i
		//pt1: r w imme
		`define ex_addi 	6'b001000
		`define ex_addiu 	6'b001001 
		`define ex_slti		6'b001010 
		`define ex_sltiu 	6'b001011 
		`define ex_andi		6'b001100 
		`define ex_lui 		6'b001111 
		`define ex_ori		6'b001101 
		`define ex_xori		6'b001110 

		`define ex_lb		6'b100000 
		`define ex_lbu		6'b100100
		`define ex_lh		6'b100001 
		`define ex_lhu		6'b100101 
		`define ex_lw 		6'b100011 
		`define ex_lwl		6'b100010 
		`define ex_lwr		6'b100110 
		`define ex_sb 		6'b101000 
		`define ex_sh		6'b101001 
		`define ex_sw		6'b101011 
		`define ex_swl		6'b101010 
		`define ex_swr		6'b101110 
		//pt2: r r imme
		`define ex_beq		6'b000100 
		`define ex_bne		6'b000101 
		//pt3: r non imme, decode require rt 
		`define ex_bgez		6'b000001
			`define rt_bgez		5'b00001 
		`define ex_bgtz		6'b000111 
			`define rt_bgtz		5'b00000
		`define ex_blez		6'b000110
			`define rt_blez		5'b00000
		`define ex_bltz		6'b000001	
			`define rt_bltz		5'b00000
		`define ex_bgezal	6'b000001//w_addr 31
			`define rt_bgezal	5'b10001
		`define ex_bltzal	6'b000001//w_addr 31 
			`define rt_bltzal	5'b10000 
		//j
		`define ex_j 		6'b000010
		`define ex_jal 		6'b000011 
		//alu op
		`define ex_addi_op 		8'b00001000 
		`define ex_addiu_op 	8'b00001001 
		`define ex_slti_op		8'b00001010 
		`define ex_sltiu_op 	8'b00001011 
		`define ex_andi_op		8'b00001100 
		//`define ex_lui_op 		8'b00001111 to ori
		`define ex_ori_op		8'b00001101 
		`define ex_xori_op		8'b00001110  

		`define ex_lb_op		8'b00100000 
		`define ex_lbu_op		8'b00100100
		`define ex_lh_op		8'b00100001 
		`define ex_lhu_op		8'b00100101 
		`define ex_lw_op 		8'b00100011 
		`define ex_lwl_op		8'b00100010 
		`define ex_lwr_op		8'b00100110 
		`define ex_sb_op 		8'b00101000 
		`define ex_sh_op		8'b00101001 
		`define ex_sw_op		8'b00101011 
		`define ex_swl_op		8'b00101010 
		`define ex_swr_op		8'b00101110 
		//pt2: r r imme
		`define ex_beq_op		8'b00000100 
		`define ex_bne_op		8'b00000101 
		//pt3: r non imme, decode require rt 
		`define ex_bgez_op		8'b00000001
		`define ex_bltz_op		8'b01000001	
		`define ex_bgezal_op	8'b10000001//w_addr 31
		`define ex_bltzal_op	8'b11000001//w_addr 31 
		//above special
		`define ex_bgtz_op		8'b00000111 
		`define ex_blez_op		8'b00000110

		`define ex_j_op			8'b00000010
		`define ex_jal_op 		8'b00000011 
	//r
		//pt1 r1: rs  r2: rt  w: rd
		`define ex_add 		6'b100000 
		`define ex_addu  	6'b100001 
		`define ex_sub		6'b100010 
		`define ex_subu		6'b100011 
		`define ex_slt 		6'b101010 
		`define ex_sltu 	6'b101011 

		`define ex_and 		6'b100100 
		`define ex_nor		6'b100111 
		`define ex_or 		6'b100101 
		`define ex_xor 		6'b100110 

		`define ex_sllv		6'b000100 
		`define ex_srav		6'b000111 
		`define ex_srlv 	6'b000110 
		//pt2 r1: sa  r2: rt  w: rd
		`define ex_sll 		6'b000000 
		`define ex_sra 		6'b000011 
		`define ex_srl 		6'b000010 
		//pt3 r1: rs  r2: rt  w: non
		`define ex_div 		6'b011010 
		`define ex_divu 	6'b011011 
		`define ex_mult 	6'b011000 
		`define ex_multu 	6'b011001
		//pt4 r1: non  r2: non  w: rd
		`define ex_mfhi 	6'b010000 
		`define ex_mflo		6'b010010 
		//pt5 r1: rs  r2: non  w: non
		`define ex_mthi		6'b010001 
		`define ex_mtlo 	6'b010011
		`define ex_jr		6'b001000  
		//pt6 r1: rs  r2: non  w: rd
		`define ex_jalr	    6'b001001
		//except
		`define ex_break	6'b001101
		`define ex_syscall  6'b001100 

		`define ex_break_op 	8'b00001101
		`define ex_syscall_op	8'b00001100

		//alu op
		//pt1 r1: rs  r2: rt  w: rd
		`define ex_add_op 		8'b00100000 
		`define ex_addu_op  	8'b00100001 
		`define ex_sub_op		8'b00100010 
		`define ex_subu_op		8'b00100011 
		`define ex_slt_op 		8'b00101010 
		`define ex_sltu_op 		8'b00101011 

		`define ex_and_op 		8'b00100100 
		`define ex_nor_op		8'b00100111 
		`define ex_or_op 		8'b00100101 
		`define ex_xor_op 		8'b00100110 

		`define ex_sllv_op		8'b00000100 
		`define ex_srav_op		8'b00000111 
		`define ex_srlv_op 		8'b00000110 
		//pt2 r1: sa  r2: rt  w: rd
		`define ex_sll_op 		8'b00000000 
		`define ex_sra_op 		8'b00000011 
		`define ex_srl_op 		8'b00000010 
		//pt3 r1: rs  r2: rt  w: non
		`define ex_div_op 		8'b00011010 
		`define ex_divu_op 		8'b00011011 
		`define ex_mult_op 		8'b00011000 
		`define ex_multu_op 	8'b00011001
		//pt4 r1: non  r2: non  w: rd
		`define ex_mfhi_op 		8'b00010000 
		`define ex_mflo_op		8'b00010010 
		//pt5 r1: rs  r2: non  w: non
		`define ex_mthi_op		8'b00010001 
		`define ex_mtlo_op 		8'b00010011
		`define ex_jr_op		8'b00001000  
		//pt6 r1: rs  r2: non  w: rd
		`define ex_jalr_op	    8'b00001001
		//sprcial
		`define special_op_2	6'b010000 
		`define ex_eret 		6'b011000 
		`define rs_mfc0			5'b00000 
		`define rs_mtc0			5'b00100 

		`define ex_eret_op		8'b00011000
		`define ex_mfc0_op		8'b00000000 
		`define ex_mtc0_op		8'b00000100

		`define ex_mul_op  		8'b11111111
//alu sel
`define exe_nop 		4'b0000 
`define exe_arthmetic	4'b0001 
`define exe_logic		4'b0010
`define exe_shift		4'b0011 
`define exe_branch		4'b0100
`define exe_move		4'b0101 
`define exe_memory		4'b0110 
`define exe_trap		4'b0111 
`define exe_special		4'b1000 

//div
`define DivFree 2'b00
`define DivByZero 2'b01
`define DivOn 2'b10
`define DivEnd 2'b11
`define DivResultReady 1'b1
`define DivResultNotReady 1'b0
`define DivStart 1'b1
`define DivStop 1'b0

//cp0
`define CPO_BADADDR      	5'b01000 
`define CP0_REG_COUNT    	5'b01001        
`define CP0_REG_COMPARE    	5'b01011     
`define CP0_REG_STATUS    	5'b01100       
`define CP0_REG_CAUSE    	5'b01101        
`define CP0_REG_EPC    		5'b01110          
`define CP0_REG_PrId    	5'b01111         
`define CP0_REG_CONFIG    	5'b10000    