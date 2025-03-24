`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
/*by srmk*/
//////////////////////////////////////////////////////////////////////////////////

`include "defines_cpu.vh"
module stage_write_back(
    clk,
    resetn,
    flush,
    stall_mempt2_wb,

    info_data_mem_2,
    info_hilo_mem_2,
    info_cp0_mem_2,

    pc_mempt2,

    w_addr,
    w_en,
    w_data,

    w_en_hi,
    data_hi,
    w_en_lo,
    data_lo,

    cp0_w_en,
    cp0_w_addr,
    cp0_w_data,

    pc_wb

    );
    input wire                          resetn;
    input wire                          clk;
    input wire                          flush;
    input wire[`stall_module_bus]       stall_mempt2_wb;

    input wire[`info_data_bus]          info_data_mem_2;
    input wire[`info_hilo_bus]          info_hilo_mem_2;
    input wire[`info_data_bus]          info_cp0_mem_2;

    input wire[`addr_bus]               pc_mempt2;

    output wire[`reg_addr_bus]          w_addr;
    output wire                         w_en;
    output wire[`data_bus]              w_data;

    output wire                         w_en_hi;
    output wire                         w_en_lo;
    output wire[`data_bus]              data_hi;
    output wire[`data_bus]              data_lo;

    output wire                         cp0_w_en;
    output wire[`reg_addr_bus]          cp0_w_addr;
    output wire[`data_bus]              cp0_w_data;

    output wire[`addr_bus]              pc_wb;
    //---------------------------------------------------------------------------
    reg[`info_data_bus]                 info_data_reg;
    reg[`info_hilo_bus]                 info_hilo_reg;
    reg[`info_data_bus]                 info_cp0_reg;
    reg[`addr_bus]                      pc_reg;

    assign {w_data,w_addr,w_en}                     =       info_data_reg[38:1];
    assign {w_en_hi,w_en_lo,data_hi,data_lo}        =       info_hilo_reg[67:2];
    assign {cp0_w_data,cp0_w_addr,cp0_w_en}         =       info_cp0_reg[38:1];
    assign pc_wb                                    =       pc_reg;


    always @(posedge clk) begin
        if (resetn == `rstn_enable||flush==`true_v) begin
            info_data_reg               <=      39'b0;
            info_cp0_reg                <=      39'b0;
            info_hilo_reg               <=      68'b0;
            pc_reg                      <=      `zero_32;
        end else if (stall_mempt2_wb[1]==`true_v&&stall_mempt2_wb[0]==`false_v) begin
            info_data_reg               <=      39'b0;
            info_cp0_reg                <=      39'b0;
            info_hilo_reg               <=      68'b0;
            pc_reg                      <=      `zero_32;
        end else if (stall_mempt2_wb[1]==`false_v) begin
            info_data_reg               <=      info_data_mem_2;
            info_cp0_reg                <=      info_cp0_mem_2;
            info_hilo_reg               <=      info_hilo_mem_2;
            pc_reg                      <=      pc_mempt2;
        end
    end


endmodule
