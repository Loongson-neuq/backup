`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
/*by srmk*/
//////////////////////////////////////////////////////////////////////////////////

`include "defines_cpu.vh"
module memory_pt2(
    info_data_mem_2i,
    info_hilo_mem_2i,
    info_mempt1_mempt2,
    mem_r_data_mempt2,

    info_data_mem_2,
    info_hilo_mem_2,
    mem_addr_ex,
    delay_slot_cp0
    );
    input wire[`info_data_bus]          info_data_mem_2i;
    input wire[`info_hilo_bus]          info_hilo_mem_2i;
    input wire[`info_exe_bus]           info_mempt1_mempt2;
    input wire[`data_bus]               mem_r_data_mempt2;

    output wire[`info_data_bus]         info_data_mem_2;
    output wire[`info_hilo_bus]         info_hilo_mem_2;
    output wire[`addr_bus]              mem_addr_ex;
    output wire                         delay_slot_cp0;
    //mlti
    assign info_hilo_mem_2 = info_hilo_mem_2i;
    //-----------------------------------------------------------
    wire[`alu_op_bus]                               alu_op;
    wire[`alu_sel_bus]                              alu_sel;
    wire                                            delay_slot;

    wire[`data_bus]                                 mem_data_ex;

    assign  {alu_op,alu_sel,delay_slot,mem_data_ex,mem_addr_ex}         =       info_mempt1_mempt2;

    wire[`data_bus]                                 w_data_mem          =       (alu_op == `ex_lb_op)?((mem_addr_ex[1:0]==2'b11)?{{24{mem_r_data_mempt2[31]}},mem_r_data_mempt2[31:24]}: 
                                                                                                       (mem_addr_ex[1:0]==2'b10)?{{24{mem_r_data_mempt2[23]}},mem_r_data_mempt2[23:16]}: 
                                                                                                       (mem_addr_ex[1:0]==2'b01)?{{24{mem_r_data_mempt2[15]}},mem_r_data_mempt2[15:8]}: 
                                                                                                       (mem_addr_ex[1:0]==2'b00)?{{24{mem_r_data_mempt2[7]}},mem_r_data_mempt2[7:0]}: 
                                                                                                       `zero_32): 
                                                                                (alu_op == `ex_lbu_op)?((mem_addr_ex[1:0]==2'b11)?{24'b0,mem_r_data_mempt2[31:24]}: 
                                                                                                        (mem_addr_ex[1:0]==2'b10)?{24'b0,mem_r_data_mempt2[23:16]}: 
                                                                                                        (mem_addr_ex[1:0]==2'b01)?{24'b0,mem_r_data_mempt2[15:8]}: 
                                                                                                        (mem_addr_ex[1:0]==2'b00)?{24'b0,mem_r_data_mempt2[7:0]}: 
                                                                                                        `zero_32): 
                                                                                (alu_op == `ex_lh_op)?((mem_addr_ex[1:0]==2'b10)?{{16{mem_r_data_mempt2[31]}},mem_r_data_mempt2[31:16]}: 
                                                                                                       (mem_addr_ex[1:0]==2'b00)?{{16{mem_r_data_mempt2[15]}},mem_r_data_mempt2[15:0]}: 
                                                                                                       `zero_32): 
                                                                                (alu_op == `ex_lhu_op)?((mem_addr_ex[1:0]==2'b10)?{16'b0,mem_r_data_mempt2[31:16]}: 
                                                                                                        (mem_addr_ex[1:0]==2'b00)?{16'b0,mem_r_data_mempt2[15:0]}: 
                                                                                                        `zero_32): 
                                                                                (alu_op == `ex_lw_op)?mem_r_data_mempt2: 
                                                                                (alu_op == `ex_lwl_op)?((mem_addr_ex[1:0]==2'b11)?mem_r_data_mempt2[31:0]: 
                                                                                                        (mem_addr_ex[1:0]==2'b10)?{mem_r_data_mempt2[23:0],mem_data_ex[7:0]}: 
                                                                                                        (mem_addr_ex[1:0]==2'b01)?{mem_r_data_mempt2[15:0],mem_data_ex[15:0]}: 
                                                                                                        (mem_addr_ex[1:0]==2'b00)?{mem_r_data_mempt2[7:0],mem_data_ex[23:0]}: 
                                                                                                        `zero_32): 
                                                                                (alu_op == `ex_lwr_op)?((mem_addr_ex[1:0]==2'b11)?{mem_data_ex[31:8],mem_r_data_mempt2[31:24]}: 
                                                                                                        (mem_addr_ex[1:0]==2'b10)?{mem_data_ex[31:16],mem_r_data_mempt2[31:16]}: 
                                                                                                        (mem_addr_ex[1:0]==2'b01)?{mem_data_ex[31:24],mem_r_data_mempt2[31:8]}: 
                                                                                                        (mem_addr_ex[1:0]==2'b00)?mem_r_data_mempt2: 
                                                                                                        `zero_32): 
                                                                                `zero_32;   
    assign                                          info_data_mem_2[38:7]   =   (alu_sel == `exe_memory)?w_data_mem: 
                                                                                                        info_data_mem_2i[38:7];   
    assign                                          info_data_mem_2[6:1]    =   info_data_mem_2i[6:1];
    assign                                          info_data_mem_2[0]      =   (alu_sel == `exe_memory)?`true_v: 
                                                                                                        info_data_mem_2i[0];

    assign                                          delay_slot_cp0          =   delay_slot;

endmodule
