`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
/*by srmk*/
//////////////////////////////////////////////////////////////////////////////////

`include "defines_cpu.vh"
module data_tran(
    clk,
    stall_pre_mem,
    flush_pre_mem,
    resetn_pre_mem,
    mem_r_data,
    mem_r_data_mempt2
    );
    input wire clk;
    input wire[`stall_module_bus] stall_pre_mem;
    input wire flush_pre_mem;
    input wire resetn_pre_mem;
    input wire[`inst_bus] mem_r_data;
    output wire[`inst_bus] mem_r_data_mempt2;
    //-----------------------------------------------------------------------------------
    reg[`inst_bus] data_pre;//storage inst of pre cycle
    always @(posedge clk) begin
        data_pre <= mem_r_data_mempt2;
    end

    assign mem_r_data_mempt2     =  (resetn_pre_mem==`rstn_enable||flush_pre_mem==`true_v)?`zero_32: 
                                    (stall_pre_mem[1]==`true_v&&stall_pre_mem[0]==`false_v)?`zero_32: 
                                    (stall_pre_mem[1]==`true_v&&stall_pre_mem[0]==`true_v)?data_pre: 
                                    mem_r_data;


endmodule
