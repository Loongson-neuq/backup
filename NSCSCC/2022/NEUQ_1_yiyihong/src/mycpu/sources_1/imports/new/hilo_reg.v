`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
/*by srmk*/
//////////////////////////////////////////////////////////////////////////////////

`include "defines_cpu.vh"
module hilo_reg(
    w_en_hi,
    data_hi,
    w_en_lo,
    data_lo,
    clk,
    resetn,

    r_en_hi,
    r_en_lo,
    r_data_hi,
    r_data_lo
    );
    input wire                          w_en_hi;
    input wire[`data_bus]               data_hi;
    input wire                          w_en_lo;
    input wire[`data_bus]               data_lo;
    input wire                          clk;
    input wire                          resetn;


    input wire                          r_en_hi;
    input wire                          r_en_lo;

    output wire[`data_bus]              r_data_hi;
    output wire[`data_bus]              r_data_lo;
    //---------------------------------------------------------------------------

    reg[`data_bus]                                 data_hi_reg;
    reg[`data_bus]                                 data_lo_reg;

    always @(posedge clk) begin
       if (resetn == `rstn_enable) begin
           data_hi_reg      <=      `zero_32;
       end else if (w_en_hi) begin
           data_hi_reg      <=      data_hi;
       end
    end

    assign r_data_hi        =       r_en_hi?(w_en_hi?data_hi: 
                                                     data_hi_reg): 
                                            `zero_32;

    always @(posedge clk) begin
       if (resetn == `rstn_enable) begin
           data_lo_reg      <=      `zero_32;
       end else if (w_en_lo) begin
           data_lo_reg      <=      data_lo;
       end
    end

    assign r_data_lo        =       r_en_lo?(w_en_lo?data_lo: 
                                                     data_lo_reg): 
                                            `zero_32;                                            

endmodule
