`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
/*by srmk*/
//////////////////////////////////////////////////////////////////////////////////

`include "defines_cpu.vh"
module stage_decode_pt1_pt2(
    stall_de_pt1_pt2,
    resetn,
    flush,
    clk,
    pc_de_pt1_pt2,
    info_decode_pt1,
    inst_dept1,
    except_type,
    inst_dept2,
    info_decode_pt1_pt2,
    except_type_decode_pt1_pt2,
    pc_dept2
    );
    input wire[`stall_module_bus]   stall_de_pt1_pt2;
    input wire                      resetn;
    input wire                      flush;
    input wire                      clk;
    input wire[`info_decode_pt1_i]  info_decode_pt1;
    input wire[`inst_bus]           inst_dept1;
    input wire[`except_bus]         except_type;
    input wire[`addr_bus]           pc_de_pt1_pt2;

    output wire[`inst_bus]          inst_dept2;
    output wire[`info_decode_pt1_i] info_decode_pt1_pt2;
    output wire[`except_bus]        except_type_decode_pt1_pt2;
    output wire[`addr_bus]          pc_dept2;

    reg[`info_decode_pt1_i]         info_reg;
    reg[`inst_bus]                  inst_reg; 
    reg[`except_bus]                except_type_reg; 
    reg[`addr_bus]                  pc_reg;

    assign inst_dept2                       =       inst_reg; 
    assign info_decode_pt1_pt2              =       info_reg;
    assign except_type_decode_pt1_pt2       =       except_type_reg;
    assign pc_dept2                         =       pc_reg;

    //update
    always @(posedge clk) begin
        if (resetn == `rstn_enable||flush==`true_v) begin
            inst_reg        <=      `zero_32;
            info_reg        <=      61'b0;
            except_type_reg <=      `exc_non;
            pc_reg          <=      `zero_32;
        end else if (stall_de_pt1_pt2[1]==`true_v&&stall_de_pt1_pt2[0]==`false_v) begin
            inst_reg        <=      `zero_32;
            info_reg        <=      61'b0;
            except_type_reg <=      `exc_non;
            pc_reg          <=      `zero_32;
        end else if (stall_de_pt1_pt2[1]==`false_v) begin
            inst_reg        <=      inst_dept1;
            info_reg        <=      info_decode_pt1;
            except_type_reg <=      except_type;
            pc_reg          <=      pc_de_pt1_pt2;
        end
    end
endmodule
