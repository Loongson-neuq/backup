`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
/*by srmk*/
//////////////////////////////////////////////////////////////////////////////////

`include "defines_cpu.vh"
module stage_mempt1_mempt2(
    clk,
    resetn,
    flush,
    info_exe_mem,
    except_type_ex_mem,
    info_data_mem_1,
    info_hilo_mem_1,
    info_cp0_mem_1,
    stall_mem_pt1_pt2,

    info_mempt1_mempt2,
    except_type_cp0,
    info_data_mem_2i,
    info_hilo_mem_2i,
    info_cp0_mem_2,

    stall_pre_mem,
    resetn_pre_mem,
    flush_pre_mem,

    pc_mempt1,
    pc_mempt2
    );
    input wire                          resetn;
    input wire                          clk;
    input wire                          flush;
    input wire[`stall_module_bus]       stall_mem_pt1_pt2;

    input wire[`info_exe_bus]           info_exe_mem;
    input wire[`except_bus]             except_type_ex_mem;

    input wire[`info_data_bus]          info_data_mem_1;
    input wire[`info_hilo_bus]          info_hilo_mem_1;
    input wire[`info_data_bus]          info_cp0_mem_1;

    input wire[`addr_bus]               pc_mempt1;

    output wire[`addr_bus]              pc_mempt2;

    output wire[`info_exe_bus]          info_mempt1_mempt2;
    output wire[`except_bus]            except_type_cp0;

    output  wire[`info_data_bus]        info_data_mem_2i;
    output  wire[`info_data_bus]        info_cp0_mem_2;
    output  wire[`info_hilo_bus]        info_hilo_mem_2i;

    output wire                                 resetn_pre_mem;
    output wire[`stall_module_bus]              stall_pre_mem;
    output wire                                 flush_pre_mem;
    //---------------------------------------------------------------
    //regs
    reg[`info_data_bus]                 info_data_reg;
    reg[`info_hilo_bus]                 info_hilo_reg;
    reg[`info_data_bus]                 info_cp0_reg;
    reg[`info_exe_bus]                  info_exe_reg;
    reg[`except_bus]                    except_type_reg;
    reg[`addr_bus]                      pc_reg;

    assign  info_data_mem_2i    =       info_data_reg;
    assign  info_cp0_mem_2      =       info_cp0_reg;
    assign  info_hilo_mem_2i    =       info_hilo_reg;
    assign  info_mempt1_mempt2  =       info_exe_reg;
    assign  except_type_cp0     =       except_type_reg;
    assign  pc_mempt2           =       pc_reg;

    reg                                         resetn_reg;
    reg                                         flush_reg;
    reg[`stall_module_bus]                      stall_reg;

    assign resetn_pre_mem       =           resetn_reg;
    assign flush_pre_mem        =           flush_reg;
    assign stall_pre_mem        =           stall_reg;

    always @(posedge clk) begin
        stall_reg           <= stall_mem_pt1_pt2;
        resetn_reg          <= resetn;
        flush_reg           <= flush;
        if (resetn == `rstn_enable||flush==`true_v) begin
            info_data_reg               <=      39'b0;
            info_cp0_reg                <=      39'b0;
            info_hilo_reg               <=      68'b0;
            info_exe_reg                <=      77'b0;
            except_type_reg             <=      `exc_non;
            pc_reg                      <=      `zero_32;
        end else if (stall_mem_pt1_pt2[1]==`true_v&&stall_mem_pt1_pt2[0]==`false_v) begin
            info_data_reg               <=      39'b0;
            info_cp0_reg                <=      39'b0;
            info_hilo_reg               <=      68'b0;
            info_exe_reg                <=      77'b0;
            except_type_reg             <=      `exc_non;
            pc_reg                      <=      `zero_32;
        end else if (stall_mem_pt1_pt2[1]==`false_v) begin
            info_data_reg               <=      info_data_mem_1;
            info_cp0_reg                <=      info_cp0_mem_1;
            info_hilo_reg               <=      info_hilo_mem_1;
            info_exe_reg                <=      info_exe_mem;
            except_type_reg             <=      except_type_ex_mem;
            pc_reg                      <=      pc_mempt1;
        end
    end

endmodule
