`include "Defines.vh"
module CTRL(
    input  rst,

    input  stallreq_for_ex,
    input  stallreq_for_load,
    input  stallreq_for_fetch,
    input  stallreq_for_memory,

    input[3:0]  except_info_i,
    input[31:0] cp0_epc_i,

    output       flush,
    output[31:0] new_pc,
    output[5:0]  stall
);  

    assign stall =  stallreq_for_memory  ? 6'b001111 : 
                    stallreq_for_ex      ? 6'b000111 :
                   (stallreq_for_load)   ? 6'b000011 : 
                    stallreq_for_fetch   ? 6'b000011 : 6'b000000;
    assign flush = (except_info_i==4'b0) ? 1'b0 : 1'b1;
    assign new_pc = (except_info_i==4'he)     ? cp0_epc_i :
                    (except_info_i!=4'b0)     ? 32'hBFC0_0380 : `Zero_Word;

endmodule