`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
/*by srmk*/ 
//////////////////////////////////////////////////////////////////////////////////

`include "defines_cpu.vh"
module decode_pt1_r(
    inst_de,
    info_decode_pt1_r
    );
    input   wire[`inst_bus]             inst_de;
    output  wire[`info_decode_pt1_i]    info_decode_pt1_r;
    //------------------------------------------------------------------
    //cut
    wire[`op_bus]       op   =    inst_de[`op_index];
    wire[`ed_bus]       ed   =    inst_de[`ed_index];
    wire[`reg_addr_bus] rs   =    inst_de[`rs_index];
    wire[`reg_addr_bus] rt   =    inst_de[`rt_index];
    wire[`reg_addr_bus] rd   =    inst_de[`rd_index];
    wire[`reg_addr_bus] sa   =    inst_de[`sa_index];
    wire[`imme_bus]     imme;

    wire    mul = (op==6'b011100&&sa==5'b0&&ed==6'b000010);
    //info
    wire                r_en_1;
    wire                r_en_2;
    wire[`reg_addr_bus] r_addr_1;
    wire[`reg_addr_bus] r_addr_2;
    wire[`alu_op_bus]   alu_op;
    wire[`alu_sel_bus]  alu_sel;
    wire[`reg_addr_bus] w_addr;

    assign info_decode_pt1_r = {r_en_1,r_en_2,r_addr_1,r_addr_2,
                                alu_op,alu_sel,16'b0,imme,w_addr};//connect
    //decode
    wire pt1 = (ed == `ex_add||
                ed == `ex_addu||
                ed == `ex_sub||
                ed == `ex_subu||
                ed == `ex_slt||
                ed == `ex_sltu||
                ed == `ex_and||
                ed == `ex_nor||
                ed == `ex_or||
                ed == `ex_xor||
                ed == `ex_sllv||
                ed == `ex_srav||
                ed == `ex_srlv||
                mul);

    wire pt2 = (ed == `ex_sll||
                ed == `ex_sra||
                ed == `ex_srl);

    wire pt3 = (ed == `ex_div||
                ed == `ex_divu||
                ed == `ex_mult||
                ed == `ex_multu);

    wire pt4 = (ed == `ex_mfhi||
                ed == `ex_mflo);

    wire pt5 = (ed == `ex_mthi|| 
                ed == `ex_mtlo||
                ed == `ex_jr);

    wire pt6 = ed == `ex_jalr;

    assign imme[4:0]     =       pt2?sa: 
                                     5'b0;
    assign imme[15:5]    =      11'b0;

    assign r_en_1 = ~(pt4||pt2);

    assign r_addr_1 = (pt1||pt3||pt5||pt6)?rs: 
                                    `zero_reg_addr;

    assign r_en_2 = ~(pt4||pt5||pt6);

    assign r_addr_2 = (pt1||pt2||pt3)?rt: 
                                      `zero_reg_addr;

    assign w_addr = (pt1||pt2||pt4||pt6)?rd: 
                                         `zero_reg_addr;

    assign alu_op = (ed == `ex_sllv || ed == `ex_sll)?`ex_sll_op: 
                    (ed == `ex_srav || ed == `ex_sra)?`ex_sra_op: 
                    mul                             ? {8{mul}}:
                    (ed == `ex_srlv || ed == `ex_srl)?`ex_srl_op: {2'b00,ed};

    assign alu_sel = (ed == `ex_add||
                      ed == `ex_addu||
                      ed == `ex_sub||
                      ed == `ex_subu||
                      ed == `ex_slt||
                      ed == `ex_sltu||
                      ed == `ex_div||
                      ed == `ex_divu||
                      ed == `ex_mult||
                      ed == `ex_multu||mul)?`exe_arthmetic: 
                     (ed == `ex_and||
                      ed == `ex_nor||
                      ed == `ex_or  ||ed == `ex_xor)?`exe_logic: 
                     (ed == `ex_sllv||
                      ed == `ex_srav||
                      ed == `ex_srlv||
                      ed == `ex_sll||
                      ed == `ex_sra||ed == `ex_srl)?`exe_shift: 
                     (ed == `ex_mult||
                      ed == `ex_multu||
                      ed == `ex_mfhi||
                      ed == `ex_mflo||
                      ed == `ex_mthi||ed == `ex_mtlo)?`exe_move: 
                     (ed == `ex_jr  ||ed == `ex_jalr)?`exe_branch: 
                     `exe_nop;


endmodule
