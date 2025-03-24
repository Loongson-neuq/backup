`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
/*by: srmk*/
//////////////////////////////////////////////////////////////////////////////////

`include "defines_cpu.vh"
module memory_pt1(
    info_exe_mem,
    except_type_ex_mem,

    mem_w_en,
    mem_addr,
    mem_r_en,
    mem_w_data,
    mem_sel,

    flush,

    mem_available,
    stall_req_mempt1
    );
    input wire[`info_exe_bus]                   info_exe_mem;
    input wire[`except_bus]                     except_type_ex_mem;

    output wire                                 mem_w_en;
    output wire[`addr_bus]                      mem_addr;
    output wire                                 mem_r_en;
    output wire[`data_bus]                      mem_w_data;
    output wire[`sel_bus]                       mem_sel;

    input wire                                  flush;

    input wire                                  mem_available;
    output wire                                 stall_req_mempt1;

    //-------------------------------------------------------------------------------------
    
    wire[`alu_op_bus]                               alu_op;
    wire[`alu_sel_bus]                              alu_sel;
    wire                                            delay_slot;
    wire[`addr_bus]                                 mem_addr_ex;
    wire[`data_bus]                                 mem_data_ex;

    assign  {alu_op,alu_sel,delay_slot,mem_data_ex,mem_addr_ex}         =       info_exe_mem;

    

    //--------------------------------------------------------------------------------------

    wire                                           exc_en               =       |except_type_ex_mem;

    assign                                          stall_req_mempt1    =       (alu_sel == `exe_memory && !mem_available &&!flush &&!exc_en);

    assign  mem_w_en                                                    =       ((!flush)&&(!exc_en)&&alu_sel == `exe_memory)?((alu_op == `ex_sb_op|| 
                                                                                                                        alu_op == `ex_sh_op||
                                                                                                                        alu_op == `ex_sw_op||
                                                                                                                        alu_op == `ex_swl_op||
                                                                                                                        alu_op == `ex_swr_op)?`true_v: 
                                                                                                                                              `false_v):
                                                                                                                       `false_v;
    assign  mem_addr                                                    =       (alu_op == `ex_lb_op||
                                                                                 alu_op == `ex_lbu_op||
                                                                                 alu_op == `ex_lh_op||
                                                                                 alu_op == `ex_lhu_op||
                                                                                 alu_op == `ex_lw_op||
                                                                                 alu_op == `ex_sb_op||
                                                                                 alu_op == `ex_sh_op||
                                                                                 alu_op == `ex_sw_op)?mem_addr_ex: 
                                                                                (alu_op == `ex_lwl_op||
                                                                                 alu_op == `ex_lwr_op||
                                                                                 alu_op == `ex_swl_op||
                                                                                 alu_op == `ex_swr_op)?{mem_addr_ex[31:2],2'b00}: 
                                                                                `zero_32;                                                                                                                   

    assign  mem_r_en                                                    =       (!exc_en&&alu_sel == `exe_memory)?((alu_op == `ex_lb_op||
                                                                                                                        alu_op == `ex_lbu_op||
                                                                                                                        alu_op == `ex_lh_op||
                                                                                                                        alu_op == `ex_lhu_op||
                                                                                                                        alu_op == `ex_lw_op||
                                                                                                                        alu_op == `ex_lwl_op||
                                                                                                                        alu_op == `ex_lwr_op)?`true_v: 
                                                                                                                                              `false_v): 
                                                                                                                      `false_v;
    assign  mem_w_data                                                  =       (alu_op == `ex_sb_op)?{{4{mem_data_ex[7:0]}}}:
                                                                                (alu_op == `ex_sh_op)?{{2{mem_data_ex[15:0]}}}: 
                                                                                (alu_op == `ex_sw_op)?mem_data_ex: 
                                                                                (alu_op == `ex_swl_op)?((mem_addr_ex[1:0]==2'b11)?mem_data_ex: 
                                                                                                        (mem_addr_ex[1:0]==2'b10)?{8'b0,mem_data_ex[31:8]}: 
                                                                                                        (mem_addr_ex[1:0]==2'b01)?{16'b0,mem_data_ex[31:16]}: 
                                                                                                        (mem_addr_ex[1:0]==2'b00)?{24'b0,mem_data_ex[31:24]}: 
                                                                                                        `zero_32):
                                                                                (alu_op == `ex_swr_op)?((mem_addr_ex[1:0]==2'b11)?{mem_data_ex[7:0],24'b0}: 
                                                                                                        (mem_addr_ex[1:0]==2'b10)?{mem_data_ex[15:0],16'b0}: 
                                                                                                        (mem_addr_ex[1:0]==2'b01)?{mem_data_ex[23:0],8'b0}: 
                                                                                                        (mem_addr_ex[1:0]==2'b00)?mem_data_ex: 
                                                                                                        `zero_32):
                                                                                `zero_32;

    assign  mem_sel                                                     =       (alu_op == `ex_lb_op||
                                                                                 alu_op == `ex_lbu_op||
                                                                                 alu_op == `ex_sb_op)?((mem_addr_ex[1:0]==2'b11)?4'b1000: 
                                                                                                       (mem_addr_ex[1:0]==2'b10)?4'b0100: 
                                                                                                       (mem_addr_ex[1:0]==2'b01)?4'b0010: 
                                                                                                       (mem_addr_ex[1:0]==2'b00)?4'b0001: 
                                                                                                        4'b0000): 
                                                                                (alu_op == `ex_lh_op||
                                                                                 alu_op == `ex_lhu_op||
                                                                                 alu_op == `ex_sh_op)?((mem_addr_ex[1:0]==2'b10)?4'b1100:
                                                                                                       (mem_addr_ex[1:0]==2'b00)?4'b0011: 
                                                                                                       4'b0000): 
                                                                                (alu_op == `ex_lw_op||
                                                                                 alu_op == `ex_lwl_op||
                                                                                 alu_op == `ex_lwr_op||
                                                                                 alu_op == `ex_sw_op)?4'b1111: 
                                                                                (alu_op == `ex_swl_op)?((mem_addr_ex[1:0]==2'b11)?4'b1111: 
                                                                                                        (mem_addr_ex[1:0]==2'b10)?4'b0111: 
                                                                                                        (mem_addr_ex[1:0]==2'b01)?4'b0011: 
                                                                                                        (mem_addr_ex[1:0]==2'b00)?4'b0001: 
                                                                                                        4'b0000):
                                                                                (alu_op == `ex_swr_op)?((mem_addr_ex[1:0]==2'b11)?4'b1000: 
                                                                                                        (mem_addr_ex[1:0]==2'b10)?4'b1100: 
                                                                                                        (mem_addr_ex[1:0]==2'b01)?4'b1110: 
                                                                                                        (mem_addr_ex[1:0]==2'b00)?4'b1111: 
                                                                                                        4'b0000): 
                                                                                4'b0000;

endmodule
