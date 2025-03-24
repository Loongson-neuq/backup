`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
/*by srmk*/
//////////////////////////////////////////////////////////////////////////////////
`define addr_bus 31:0 
`define trans_enable 1'b1 
`define trans_disable 1'b0 

`define addr_head_bus 2:0 
`define addr_head_index 31:29 
`define addr_body_bus 28:0 
`define addr_body_index 28:0 


`include "defines_cpu.vh"
module addr_trans(
    addr_in,
    addr_out
    );
    input wire[`addr_bus] addr_in;
    output wire[`addr_bus] addr_out;

    wire[`addr_head_bus] addr_head_in = addr_in[`addr_head_index];
    wire[`addr_body_bus] addr_body_in = addr_in[`addr_body_index];
    wire[`addr_head_bus] addr_head_out = (addr_head_in==3'b100||addr_head_in==3'b101)?3'b000:
                                                                                      addr_head_in;
    wire[`addr_body_bus] addr_body_out = addr_in[`addr_body_index];

    assign addr_out = {addr_head_out,addr_body_out};
endmodule
