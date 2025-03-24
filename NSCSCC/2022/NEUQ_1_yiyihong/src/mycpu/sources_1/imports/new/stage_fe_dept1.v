`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
/*by srmk*/
//////////////////////////////////////////////////////////////////////////////////

`include "defines_cpu.vh"
module stage_fe_dept1(
    resetn,
    clk,
    flush,
    pc,
    stall_fe_dept1,
    pc_dept1,
    //to inst_tran
    resetn_pre,
    stall_fe_dept1_pre,
    flush_pre,
    resetn_fe,
    resetn_fe_in,
    flush_fe_in,
    flush_fe
    );
    input wire                                  resetn;
    input wire                                  clk;
    input wire                                  flush;
    input wire[`addr_bus]                       pc;
    input wire[`stall_module_bus]               stall_fe_dept1;
    input wire                                  resetn_fe_in;
    input wire                                  flush_fe_in;
    output wire[`addr_bus]                      pc_dept1;
    //to inst_tran
    output wire                                 resetn_pre;
    output wire[`stall_module_bus]              stall_fe_dept1_pre;
    output wire                                 flush_pre;
    output wire                                 resetn_fe;
    output wire                                 flush_fe;
    //-----------------------------------------------------
    //regs
    reg                                         resetn_reg;
    reg                                         resetn_fe_reg;
    reg                                         flush_reg;
    reg                                         flush_fe_reg;
    reg[`addr_bus]                              pc_reg;//decode stall do not change
    reg[`stall_module_bus]                      stall_fe_dept1_reg;

    assign resetn_pre               =           resetn_reg;
    assign flush_pre                =           flush_reg;
    assign pc_dept1                 =           pc_reg;
    assign stall_fe_dept1_pre       =           stall_fe_dept1_reg;
    assign resetn_fe                =           resetn_fe_reg;
    assign flush_fe                 =           flush_fe_reg;
    //update
    always @(posedge clk) begin
        stall_fe_dept1_reg  <=  stall_fe_dept1;
        resetn_reg          <=  resetn;
        flush_reg           <=  flush;
        resetn_fe_reg       <=  resetn_fe_in;
        flush_fe_reg        <=  flush_fe_in;       
        if (resetn == `rstn_enable||flush==`true_v) begin
            pc_reg          <= `zero_32;
        end else if (stall_fe_dept1[1]==`true_v&&stall_fe_dept1[0]==`false_v) begin
            pc_reg          <= `zero_32;//fetch stall but decode not stall
        end else if (stall_fe_dept1[1]==`false_v) begin
            pc_reg          <= pc;//fetch not stall
        end
    end

endmodule
