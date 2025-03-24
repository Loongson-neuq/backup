`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
/*by srmk*/ 
//////////////////////////////////////////////////////////////////////////////////

`include "defines_cpu.vh"
module decode_pt1(
    inst_dept1,
    pc_dept1,
    info_decode_pt1,
    except_type,
    pc_de_pt1_pt2,
    inst_save
    );
    input   wire[`inst_bus]             inst_dept1;
    input   wire[`addr_bus]             pc_dept1;
    output  wire[`info_decode_pt1_i]    info_decode_pt1;
    output  wire[`except_bus]           except_type;//{int,wr_pc,wr_addr,overflow,syscall,break,eret}
    output  wire[`addr_bus]             pc_de_pt1_pt2;
    output  wire                        inst_save;
    //-------------------------------------------------------------------------------
    //cut
    wire[`op_bus]       op   =    inst_dept1[`op_index];
    wire[`reg_addr_bus] rs   =    inst_dept1[`rs_index];
    wire[`reg_addr_bus] rt   =    inst_dept1[`rt_index];
    wire[`reg_addr_bus] rd   =    inst_dept1[`rd_index];
    wire[`reg_addr_bus] sa   =    inst_dept1[`sa_index];
    wire[`ed_bus]       ed   =    inst_dept1[`ed_index];

    //------------------------------------------------------------------------------
    wire choi_i_or_j;
    wire choi_r;
    wire choi_sp;
    wire choi_exc;

    assign pc_de_pt1_pt2    =      pc_dept1; 

    assign choi_i_or_j      =     (op  == `ex_addi||
                                   op  == `ex_addiu||
                                   op  == `ex_slti||
                                   op  == `ex_sltiu||
                                   op  == `ex_andi||
                                   op  == `ex_addiu||
                                   op  == `ex_andi||
                                   op  == `ex_lui||
                                   op  == `ex_ori||
                                   op  == `ex_xori||
                                   op == `ex_lb||
                                   op == `ex_lbu||
                                   op == `ex_lh||
                                   op == `ex_lhu||
                                   op == `ex_lw||
                                   op == `ex_lwl||
                                   op == `ex_lwr||
                                   op == `ex_sb||
                                   op == `ex_sh||
                                   op == `ex_sw||
                                   op == `ex_swl||
                                   op == `ex_swr||
                                   op == `ex_beq||
                                   op == `ex_bne||
                                   (op == `ex_bgez&&rt == `rt_bgez)||
                                   (op == `ex_bgtz&&rt == `rt_bgtz)||
                                   (op == `ex_blez&&rt == `rt_blez)||
                                   (op == `ex_bltz&&rt == `rt_bltz)||
                                   (op == `ex_bgezal&&rt == `rt_bgezal)||
                                   (op == `ex_bltzal&&rt == `rt_bltzal)||
                                   op == `ex_j||
                                   op == `ex_jal)?`true_v: 
                                                  `false_v;


    assign choi_r           =   ((ed == `ex_add&&sa == 5'b0||
                                 ed == `ex_addu&&sa == 5'b0||
                                 ed == `ex_sub&&sa == 5'b0||
                                 ed == `ex_subu&&sa == 5'b0||
                                 ed == `ex_slt&&sa == 5'b0||
                                 ed == `ex_sltu&&sa == 5'b0||
                                 ed == `ex_and&&sa == 5'b0||
                                 ed == `ex_nor&&sa == 5'b0||
                                 ed == `ex_or&&sa == 5'b0||
                                 ed == `ex_xor&&sa == 5'b0||
                                 ed == `ex_sllv&&sa == 5'b0||
                                 ed == `ex_srav&&sa == 5'b0||
                                 ed == `ex_srlv&&sa == 5'b0||
                                 ed == `ex_sll&&rs == 5'b0||
                                 ed == `ex_sra&&rs == 5'b0||
                                 ed == `ex_srl&&rs == 5'b0||
                                 ed == `ex_div&&{rd,sa}==10'b0||
                                 ed == `ex_divu&&{rd,sa}==10'b0||
                                 ed == `ex_mult&&{rd,sa}==10'b0||
                                 ed == `ex_multu&&{rd,sa}==10'b0||
                                 ed == `ex_mfhi&&{rs,rt,sa}==15'b0||
                                 ed == `ex_mflo&&{rs,rt,sa}==15'b0||
                                 ed == `ex_mthi&&{rt,rd,sa}==15'b0|| 
                                 ed == `ex_mtlo&&{rt,rd,sa}==15'b0||
                                 ed == `ex_jr&&{rt,rd,sa}==15'b0||
                                 ed == `ex_jalr&&{rt,sa}==10'b0)&&
                                                op == `special_op_1)|| (op==6'b011100&&sa==5'b0&&ed==6'b000010)?`true_v:
                                                                     `false_v;

    assign choi_sp          =   ((ed == `ex_eret||
                                 rs == `rs_mfc0||
                                 rs == `rs_mtc0)&&(op == `special_op_2))?`true_v: 
                                                                         `false_v;                                                                
    assign choi_exc         =   ((ed == `ex_break|| 
                                  ed == `ex_syscall)&&op == `special_op_1)?`true_v: 
                                                                           `false_v;


    wire[`alu_op_bus]   alu_op_exc  = {2'b0,ed};
    wire[`alu_sel_bus]  alu_sel_exc = `exe_trap;

    wire[`info_decode_pt1_i]    info_decode_pt1_i;
    wire[`info_decode_pt1_i]    info_decode_pt1_r;
    wire[`info_decode_pt1_i]    info_decode_pt1_sp;
    wire[`info_decode_pt1_i]    info_decode_pt1_exc = {`false_v,`false_v,`zero_reg_addr,`zero_reg_addr,
                                                        alu_op_exc,alu_sel_exc,32'b0,`zero_reg_addr};//{r_en_1,r_en_2,r_addr_1,r_addr_2,alu_op,alu_sel,imme,w_addr}


    wire wr_pc          =       ~(pc_dept1[1:0] == 2'b00);
    wire valid          =       (choi_i_or_j||choi_r||choi_sp||choi_exc) || wr_pc;
    wire break_point    =       ed == `ex_break && op == `special_op_1 && !wr_pc;
    wire syscall        =       ed == `ex_syscall && op == `special_op_1 && !wr_pc;
    wire eret           =       ed == `ex_eret && op == `special_op_2 && !wr_pc;

    assign except_type = {!valid,2'b0,wr_pc,1'b0,1'b0,syscall,break_point,eret};


    assign info_decode_pt1  =   wr_pc?          61'b0:
                                choi_i_or_j?    info_decode_pt1_i: 
                                choi_r?         info_decode_pt1_r:
                                choi_sp?        info_decode_pt1_sp:
                                choi_exc?       info_decode_pt1_exc: 
                                61'b0;

    
    wire[`inst_bus] inst_de = inst_dept1;

    decode_pt1_i inst_decode_pt1_i (.pc_dept1(pc_dept1),.inst_de(inst_de), .info_decode_pt1_i(info_decode_pt1_i));

    decode_pt1_special inst_decode_pt1_special (.inst_de(inst_de), .info_decode_pt1_sp(info_decode_pt1_sp));

    decode_pt1_r inst_decode_pt1_r (.inst_de(inst_de), .info_decode_pt1_r(info_decode_pt1_r));

    assign inst_save        =       info_decode_pt1[4:1]    ==      `exe_branch;





endmodule
