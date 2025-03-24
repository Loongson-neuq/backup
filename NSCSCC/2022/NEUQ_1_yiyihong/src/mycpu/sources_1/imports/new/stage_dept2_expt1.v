`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
/*by srmk*/
//////////////////////////////////////////////////////////////////////////////////

`include "defines_cpu.vh"
module stage_dept2_expt1(
    resetn,
    clk,
    flush,
    stall_dept2_expt1,
    pc_dept2_ex,
    info_decode_pt2,
    delay_slot,
    except_type_pt2,
    pc_expt1,
    info_dept2_expt1,
    next_in_delay,
    except_type_expt1,
    additional_data,
    additional_data_ex
    );
    input wire                          resetn;
    input wire                          clk;
    input wire                          flush;
    input wire[`stall_module_bus]       stall_dept2_expt1;
    input wire[`addr_bus]               pc_dept2_ex;
    input wire[`info_decode_pt2_bus]    info_decode_pt2;
    input wire                          delay_slot;
    input wire[`except_bus]             except_type_pt2;
    input wire[`data_bus]               additional_data;

    output wire[`addr_bus]              pc_expt1;
    output wire[`info_decode_pt2_bus]   info_dept2_expt1;
    output wire                         next_in_delay;
    output wire[`except_bus]            except_type_expt1;
    output wire[`data_bus]              additional_data_ex;

    //regs
    reg[`addr_bus]                      pc_reg;
    reg[`info_decode_pt2_bus]           info_reg;
    reg                                 delay_reg;
    reg[`except_bus]                    except_type_reg;
    reg[`data_bus]                      additional_data_reg;

    assign  pc_expt1            =           pc_reg;
    assign  info_dept2_expt1    =           {info_reg[81:1],delay_reg};
    assign  next_in_delay       =           info_reg[0];
    assign  except_type_expt1   =           except_type_reg;
    assign  additional_data_ex  =           additional_data_reg;

    //update
    always @(posedge clk) begin
        if (resetn == `rstn_enable||flush==`true_v) begin
            delay_reg           <=      `false_v;
            info_reg            <=      82'b0;
            except_type_reg     <=      `exc_non;
            pc_reg              <=      `zero_32;
            additional_data_reg <=      `zero_32;
        end else if (stall_dept2_expt1[1]==`true_v&&stall_dept2_expt1[0]==`false_v) begin
            delay_reg           <=      `false_v;
            info_reg            <=      82'b0;
            except_type_reg     <=      `exc_non;
            pc_reg              <=      `zero_32;
            additional_data_reg <=      `zero_32;
        end else if (stall_dept2_expt1[1]==`false_v) begin
            delay_reg           <=      delay_slot;
            info_reg            <=      info_decode_pt2;
            except_type_reg     <=      except_type_pt2;
            pc_reg              <=      pc_dept2_ex;
            additional_data_reg <=      additional_data;
        end
    end

endmodule
