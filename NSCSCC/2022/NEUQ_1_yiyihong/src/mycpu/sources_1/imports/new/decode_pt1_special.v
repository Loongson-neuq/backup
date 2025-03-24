`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
/*by srmk*/ 
//////////////////////////////////////////////////////////////////////////////////

`include "defines_cpu.vh"
module decode_pt1_special(
    inst_de,
    info_decode_pt1_sp
    );
    input   wire[`inst_bus]             inst_de;
    output  wire[`info_decode_pt1_i]    info_decode_pt1_sp;

    //cut
    wire[`op_bus]       op   =    inst_de[`op_index];
    wire[`reg_addr_bus] rs   =    inst_de[`rs_index];
    wire[`reg_addr_bus] rt   =    inst_de[`rt_index];
    wire[`reg_addr_bus] rd   =    inst_de[`rd_index];
    wire[`ed_bus]       ed   =    inst_de[`ed_index];
    //info
    wire                r_en_1;
    wire                r_en_2;
    wire[`reg_addr_bus] r_addr_1;
    wire[`reg_addr_bus] r_addr_2;
    wire[`alu_op_bus]   alu_op;
    wire[`alu_sel_bus]  alu_sel;
    wire[`reg_addr_bus] w_addr;

    wire[`imme_bus] imme = 16'b0;

    assign info_decode_pt1_sp = {r_en_1,r_en_2,r_addr_1,r_addr_2,
                                 alu_op,alu_sel,imme,16'b0,w_addr};//connect

    assign r_en_1   =   (rs == `rs_mfc0||
                         rs == `rs_mtc0)?`true_v: 
                                         `false_v;
    assign r_addr_1 =   (rs == `rs_mfc0)?rd: 
                        (rs == `rs_mtc0)?rt: 
                        `zero_reg_addr;
    assign r_en_2   =   `false_v;
    assign r_addr_2 =   `zero_reg_addr;

    assign w_addr   =   (rs == `rs_mfc0)?rt: 
                        (rs == `rs_mtc0)?rd: 
                        `zero_reg_addr;
    assign alu_op   =   (ed == `ex_eret)?`ex_eret_op: 
                        (rs == `rs_mfc0)?`ex_mfc0_op:
                        (rs == `rs_mtc0)?`ex_mtc0_op:
                        `ex_nop;
    assign alu_sel  =   `exe_special;

endmodule
