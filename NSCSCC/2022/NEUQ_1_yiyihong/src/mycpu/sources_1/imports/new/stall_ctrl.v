`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
/*by srmk*/
//////////////////////////////////////////////////////////////////////////////////

`include "defines_cpu.vh"
module stall_ctrl(
    stall_req_fetch,
    stall_req_dept2,
    stall_req_ex,
    stall_req_mempt1,
    stall
    );
    input wire                          stall_req_fetch;
    input wire                          stall_req_dept2;
    input wire                          stall_req_ex; 
    input wire                          stall_req_mempt1;

    output wire[`stall_bus]             stall;

    assign  stall       =           stall_req_mempt1?7'b1111110:
                                    stall_req_ex?7'b1111000: 
                                    stall_req_fetch?7'b1111000: 
                                    stall_req_dept2?7'b1110000:                              
                                    7'b0000000;


    
endmodule
