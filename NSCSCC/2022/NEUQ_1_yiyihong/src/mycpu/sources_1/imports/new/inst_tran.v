`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
/*by srmk*/
//////////////////////////////////////////////////////////////////////////////////

`include "defines_cpu.vh"
module inst_tran(
    clk,
    stall_fe_dept1_pre,
    flush_pre,
    resetn_pre,
    inst,
    branch_en,
    inst_dept1,
    resetn_fe,
    flush_fe,
    save,
    fetch_available,
    resetn,
    flush
    );
    input wire clk;
    input wire[`stall_module_bus] stall_fe_dept1_pre;
    input wire flush_pre;
    input wire resetn_pre;
    input wire[`inst_bus] inst;
    input wire branch_en;
    input wire resetn_fe;
    input wire save;
    input wire flush_fe;
    output wire[`inst_bus]  inst_dept1;
    input  wire             fetch_available;
    input  wire             flush;
    input  wire             resetn;
    //-----------------------------------------------
    reg[`inst_bus] inst_pre;//storage inst of pre cycle
    always @(posedge clk) begin
        inst_pre <= inst_dept1;
    end

    reg             branch_pre;

    always @(posedge clk) begin
        branch_pre <= branch_en;
    end

    reg fetch_available_pre;

    always @(posedge clk) begin
        fetch_available_pre <= fetch_available;
    end


    reg flush_done;

    always @(posedge clk) begin
        if (resetn==`rstn_enable) begin
            flush_done <= 1'b1;
        end else if (flush) begin
            flush_done <= 1'b0;
        end else if (fetch_available_pre) begin
            flush_done <= 1'b1;
        end
    end


    assign inst_dept1 =     (resetn_pre==`rstn_enable||resetn_fe==`rstn_enable)?`zero_32: 
                            (!flush_done)?`zero_32:
                            (stall_fe_dept1_pre[1]==`true_v&&stall_fe_dept1_pre[0]==`false_v)?`zero_32: 
                            (stall_fe_dept1_pre[1]==`true_v&&stall_fe_dept1_pre[0]==`true_v)?inst_pre: 
                            (branch_pre==`true_v)?`zero_32:                         
                            inst;



endmodule
