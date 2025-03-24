`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
/*by srmk*/
//////////////////////////////////////////////////////////////////////////////////

`include "defines_cpu.vh"
module fetch(
    clk,
    resetn,
    resetn_fe_in,
    flush_fe_in,
    //except
    flush,
    new_pc,
    //branch
    branch_en,
    branch_pc,
    //fetch
    pc,
    fetch_en,
    //stall 
    stall_fetch,
    stall_req_fetch,
    //outside
    fetch_available
    );
    input wire clk;
    input wire resetn;
    output wire resetn_fe_in;
    output wire flush_fe_in;
    //flush
    input wire flush;
    input wire[`addr_bus] new_pc;
    //branch
    input wire branch_en;
    input wire[`addr_bus] branch_pc;
    //fetch
    output wire[`addr_bus] pc;
    output wire fetch_en;
    //stall
    input wire stall_fetch;
    output wire stall_req_fetch;
    //outside
    input wire fetch_available;
    //------------------------------------------------------------------------

    reg[`addr_bus] pc_reg;
    reg fetch_en_reg;
    reg resetn_reg;
    reg flush_reg;

    assign pc = pc_reg;
    assign fetch_en = fetch_en_reg;
    assign resetn_fe_in = resetn_reg;
    assign flush_fe_in  = flush_reg;
    //next pc flush stall branch
    reg flush_done;

    always @(posedge clk) begin
        if (resetn==`rstn_enable) begin
            flush_done <= 1'b1;
        end else if (flush) begin
            flush_done <= 1'b0;
        end else if (fetch_available) begin
            flush_done <= 1'b1;
        end
    end


    wire[`addr_bus] next_pc;

    wire[`addr_bus] added_pc = pc_reg + 4;//change to adder?

    assign next_pc = (flush==`true_v)?new_pc://flush stall branch
                     (stall_fetch||!flush_done)?pc_reg:                     
                     (branch_en==`true_v)?branch_pc: 
                     added_pc;


    

    always @(posedge clk) begin
        resetn_reg  <= resetn;
        flush_reg   <= flush;
        if (resetn==`rstn_enable) begin
            pc_reg <= `ini_pc;
            fetch_en_reg <= `false_v;
        end else begin
            pc_reg <= next_pc;
            fetch_en_reg <= `true_v;
        end
    end
    //stall_req
    assign stall_req_fetch = ~fetch_available;//when port not ready


endmodule
