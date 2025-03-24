`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
/*by srmk*/ 
//////////////////////////////////////////////////////////////////////////////////

`include "defines_cpu.vh"
module decode_pt1_i(
    pc_dept1,
    inst_de,
    info_decode_pt1_i
    );
    input   wire[`addr_bus]             pc_dept1;
    input   wire[`inst_bus]             inst_de;
    output  wire[`info_decode_pt1_i]    info_decode_pt1_i;
    //------------------------------------------------------------------
    //cut
    wire[`op_bus]       op   =    inst_de[`op_index];
    wire[`reg_addr_bus] rs   =    inst_de[`rs_index];
    wire[`reg_addr_bus] rt   =    inst_de[`rt_index];
    wire[`imme_bus]     imme =    inst_de[`imme_index];
    //info
    wire                r_en_1;
    wire                r_en_2;
    wire[`reg_addr_bus] r_addr_1;
    wire[`reg_addr_bus] r_addr_2;
    wire[`alu_op_bus]   alu_op;
    wire[`alu_sel_bus]  alu_sel;
    wire[`reg_addr_bus] w_addr;

    wire[`data_bus]   immediate_32; 

    wire[`addr_bus]   imme_offset   =   {{14{imme[15]}},imme,2'b00};

    wire[`addr_bus]   imme_offset_j      =   {3'b0,inst_de[25:0],2'b00};

    assign info_decode_pt1_i = {r_en_1,r_en_2,r_addr_1,r_addr_2,
                                alu_op,alu_sel,immediate_32,w_addr};//connect

    //decode: no valid check


    wire pt1        = (op == `ex_lb||
                       op == `ex_lbu||
                       op == `ex_lh||
                       op == `ex_addi||
                       op == `ex_addiu||
                       op == `ex_slti||
                       op == `ex_sltiu||
                       op == `ex_andi||
                       op == `ex_lui||
                       op == `ex_ori||
                       op == `ex_xori);

    wire pt2        = (op == `ex_sb||
                       op == `ex_sh||
                       op == `ex_sw||
                       op == `ex_swl||
                       op == `ex_swr||

                       op == `ex_lhu||
                       op == `ex_lw||
                       op == `ex_lwl||
                       op == `ex_lwr);


    wire pt3        = (op == `ex_bgez&&rt == `rt_bgez)||
                      (op == `ex_bgtz&&rt == `rt_bgtz)||
                      (op == `ex_blez&&rt == `rt_blez)||
                      (op == `ex_bltz&&rt == `rt_bltz)||
                      (op == `ex_bgezal&&rt == `rt_bgezal)||
                      (op == `ex_bltzal&&rt == `rt_bltzal);

    assign r_en_1   = (op == `ex_j||
                       op == `ex_jal)?`false_v:
                                      `true_v;

    assign r_addr_1 = (op == `ex_lui||     
                       op == `ex_j||
                       op == `ex_jal)?`zero_reg_addr: 
                                    rs;

    assign r_en_2   = (op == `ex_beq||
                       op == `ex_bne||
                       pt2)?`true_v: 
                                      `false_v; 

    assign r_addr_2 = (op == `ex_beq||
                       op == `ex_bne||
                       pt2)?rt: 
                                      `zero_reg_addr;

    assign w_addr   = (pt1||pt2)?rt: 
                      ((op == `ex_bgezal&&rt == `rt_bgezal)||
                       (op == `ex_bltzal&&rt == `rt_bltzal)||
                       op == `ex_j||
                       op == `ex_jal)?5'b11111: 
                      `zero_reg_addr;

    assign alu_op   = (op == `ex_bgez&&rt == `rt_bgez)?`ex_bgez_op: 
                      (op == `ex_bgtz&&rt == `rt_bgtz)?`ex_bgtz_op:
                      (op == `ex_blez&&rt == `rt_blez)?`ex_blez_op:
                      (op == `ex_bltz&&rt == `rt_bltz)?`ex_bltz_op:
                      (op == `ex_bgezal&&rt == `rt_bgezal)?`ex_bgezal_op:
                      (op == `ex_bltzal&&rt == `rt_bltzal)?`ex_bltzal_op:
                      (op == `ex_lui || op == `ex_ori)?`ex_or_op:
                      (op == `ex_andi)?`ex_and_op: 
                      (op == `ex_xori)?`ex_xor_op: 
                      (op == `ex_slti)?`ex_slt_op: 
                      (op == `ex_sltiu)?`ex_sltu_op:
                      {2'b00,op};

    assign alu_sel = (pt2||
                      op == `ex_lb||
                      op == `ex_lbu||
                      op == `ex_lh)?`exe_memory: 
                     (op == `ex_addi||
                      op == `ex_addiu||
                      op == `ex_slti||
                      op == `ex_sltiu)?`exe_arthmetic: 
                     (op == `ex_andi||
                      op == `ex_lui||
                      op == `ex_ori||
                      op == `ex_xori)?`exe_logic: 
                     (op == `ex_beq||
                      op == `ex_bne||
                      op == `ex_j||
                      op == `ex_jal||pt3)?`exe_branch:
                     `exe_nop;

    assign immediate_32   =   (op == `ex_addi||
                               op == `ex_addiu||
                               op == `ex_slti||
                               op == `ex_sltiu||
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
                               op == `ex_swr)?{{16{imme[15]}},imme}:
                              (op == `ex_andi||
                               op == `ex_ori||
                               op == `ex_xori)?{16'b0,imme}: 
                              (op == `ex_lui)?{imme,16'b0}: 
                              (op == `ex_beq||
                               op == `ex_bne||
                               pt3)?imme_offset: 
                              (op == `ex_j||
                               op == `ex_jal)?imme_offset_j: 
                              `zero_32;




endmodule
