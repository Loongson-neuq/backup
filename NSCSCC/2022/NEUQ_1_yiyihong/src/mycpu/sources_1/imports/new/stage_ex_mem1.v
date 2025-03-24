`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
/*by srmk*/
//////////////////////////////////////////////////////////////////////////////////

`include "defines_cpu.vh"
module stage_ex_mem1(
    clk,
    resetn,
    flush,
    
    stall_expt1_mempt1,

    info_data_ex,
    info_hilo_ex,
    info_cp0_ex,

    info_data_mem_1,
    info_hilo_mem_1,
    info_cp0_mem_1,

    info_exe,
    info_exe_mem,

    except_type_mem,
    except_type_ex_mem,

    pc_expt1,
    pc_mempt1
    );
    input wire                          resetn;
    input wire                          clk;
    input wire                          flush;
    input wire[`stall_module_bus]       stall_expt1_mempt1;

    input wire[`info_data_bus]          info_data_ex;
    input wire[`info_hilo_bus]          info_hilo_ex;
    input wire[`info_data_bus]          info_cp0_ex;

    output  wire[`info_data_bus]        info_data_mem_1;
    output  wire[`info_data_bus]        info_cp0_mem_1;
    output  wire[`info_hilo_bus]        info_hilo_mem_1;

    input wire[`info_exe_bus]           info_exe;
    output wire[`info_exe_bus]          info_exe_mem;

    input wire[`except_bus]             except_type_mem;
    output wire[`except_bus]            except_type_ex_mem;

    input wire[`addr_bus]               pc_expt1;
    output wire[`addr_bus]              pc_mempt1;
    //--------------------------------------------------------------
    //regs
    reg[`info_data_bus]                 info_data_reg;
    reg[`info_hilo_bus]                 info_hilo_reg;
    reg[`info_data_bus]                 info_cp0_reg;
    reg[`info_exe_bus]                  info_exe_reg;
    reg[`except_bus]                    except_type_reg;
    reg[`addr_bus]                      pc_reg;

    assign  info_data_mem_1     =       info_data_reg;
    assign  info_cp0_mem_1      =       info_cp0_reg;
    assign  info_hilo_mem_1     =       info_hilo_reg;
    assign  info_exe_mem        =       info_exe_reg;
    assign  except_type_ex_mem  =       except_type_reg;
    assign  pc_mempt1           =       pc_reg;

    //update
    always @(posedge clk) begin
        if (resetn == `rstn_enable||flush==`true_v) begin
            info_data_reg               <=      39'b0;
            info_cp0_reg                <=      39'b0;
            info_hilo_reg               <=      68'b0;
            info_exe_reg                <=      77'b0;
            except_type_reg             <=      `exc_non;
            pc_reg                      <=      `zero_32;
        end else if (stall_expt1_mempt1[1]==`true_v&&stall_expt1_mempt1[0]==`false_v) begin
            info_data_reg               <=      39'b0;
            info_cp0_reg                <=      39'b0;
            info_hilo_reg               <=      68'b0;
            info_exe_reg                <=      77'b0;
            except_type_reg             <=      `exc_non;
            pc_reg                      <=      `zero_32;
        end else if (stall_expt1_mempt1[1]==`false_v) begin
            info_data_reg               <=      info_data_ex;
            info_cp0_reg                <=      info_cp0_ex;
            info_hilo_reg               <=      info_hilo_ex;
            info_exe_reg                <=      info_exe;
            except_type_reg             <=      except_type_mem;
            pc_reg                      <=      pc_expt1;
        end
    end
    
endmodule
