`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
/*by srmk*/ 
//////////////////////////////////////////////////////////////////////////////////
`define     reg_number      32
`include "defines_cpu.vh"
module reg_file(
    clk,
    w_addr,
    w_data,
    w_en,
    r_addr_1,
    r_en_1,
    r_addr_2,
    r_en_2,
    r_data_1,
    r_data_2
    );
    input wire clk;
    input wire[`reg_addr_bus] w_addr;
    input wire[`data_bus] w_data;
    input wire w_en;
    input wire[`reg_addr_bus] r_addr_1;
    input wire r_en_1;
    input wire[`reg_addr_bus] r_addr_2;
    input wire r_en_2;
    output wire[`data_bus] r_data_1;
    output wire[`data_bus] r_data_2;
    reg[`data_bus] regs[`reg_number-1:0];
    //write
    always @(posedge clk) begin
        if (w_en) begin
            regs[w_addr] <= w_data; 
        end 
    end
    //read
    assign r_data_1 = (r_en_1)?((r_addr_1 == 5'b0)?32'b0:(w_en&&w_addr==r_addr_1)?w_data:regs[r_addr_1]):32'b0;
    assign r_data_2 = (r_en_2)?((r_addr_2 == 5'b0)?32'b0:(w_en&&w_addr==r_addr_2)?w_data:regs[r_addr_2]):32'b0;
    
endmodule
