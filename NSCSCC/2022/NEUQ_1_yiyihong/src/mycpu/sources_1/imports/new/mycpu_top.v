`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
/*by srmk*/
//////////////////////////////////////////////////////////////////////////////////

`include "defines_cpu.vh"
module mycpu_top_sram(
    clk              ,
    resetn           ,  //low active
    ext_int          ,  //interrupt,high active

    inst_sram_en     ,
    inst_sram_wen    ,
    inst_sram_addr   ,
    inst_sram_wdata  ,
    inst_sram_rdata  ,
    
    data_sram_en    ,
    data_sram_wen    ,
    data_sram_addr   ,
    data_sram_wdata  ,
    data_sram_rdata  ,

    //debug
    debug_wb_pc      ,
    debug_wb_rf_wen  ,
    debug_wb_rf_wnum ,
    debug_wb_rf_wdata,

    fetch_available,
    mem_available,
    sel_cpu
    );
    input wire fetch_available;
    input wire mem_available;
    output wire[3:0] sel_cpu;

    input wire clk;
    input wire resetn;
    input wire[5:0] ext_int;

    output wire [31:0] debug_wb_pc;
    output wire [3 :0] debug_wb_rf_wen;
    output wire [4 :0] debug_wb_rf_wnum;
    output wire [31:0] debug_wb_rf_wdata;

    output wire        inst_sram_en;
    output wire [3 :0] inst_sram_wen;
    output wire [31:0] inst_sram_addr;
    output wire [31:0] inst_sram_wdata;
    input wire [31:0] inst_sram_rdata;

    output wire        data_sram_en;
    output wire [3 :0] data_sram_wen;
    output wire [31:0] data_sram_addr;
    output wire [31:0] data_sram_wdata;
    input wire [31:0] data_sram_rdata;

    wire[31:0]                      pc;

    wire[31:0]                      mem_addr;
    wire[31:0]                      mem_w_data;
    wire                            mem_r_en;
    wire[3:0]                       mem_sel;
    wire                            mem_w_en;
    wire[31:0]                      mem_r_data;


    wire                            w_en_wb;

    assign sel_cpu      =       mem_sel;
    //rdata-------------------------------------------------------------------------
    reg[3:0] sel_pre;
    always @(posedge clk) begin
        sel_pre <= mem_sel;
    end

    assign mem_r_data   =   {(data_sram_rdata[31:24]&{8{sel_pre[3]}}),
                            (data_sram_rdata[23:16]&{8{sel_pre[2]}}),
                            (data_sram_rdata[15:8]&{8{sel_pre[1]}}),
                            (data_sram_rdata[7:0]&{8{sel_pre[0]}})};
    //------------------------------------------------------------------------------
    assign data_sram_wdata  =   {(mem_w_data[31:24]&{8{mem_sel[3]}}),
                                (mem_w_data[23:16]&{8{mem_sel[2]}}),
                                (mem_w_data[15:8]&{8{mem_sel[1]}}),
                                (mem_w_data[7:0]&{8{mem_sel[0]}})};

    //-------------------------------------------------------------------------------
    assign data_sram_wen = {mem_w_en,mem_w_en,mem_w_en,mem_w_en}&mem_sel;
    assign data_sram_en  = mem_w_en||mem_r_en;
    //-------------------------------------------------------------------------------
    assign debug_wb_rf_wen = {w_en_wb,w_en_wb,w_en_wb,w_en_wb};
    //-------------------------------------------------------------------------------
    assign inst_sram_wen = 4'b0;
    assign inst_sram_wdata = 32'b0;
    //-------------------------------------------------------------------------------
    cpu inst_cpu
        (
            .clk            (clk),
            .resetn         (resetn),
            .inst           (inst_sram_rdata),
            .fetch_available (fetch_available),
            .pc             (pc),
            .fetch_en       (inst_sram_en),
            .mem_w_en       (mem_w_en),
            .mem_addr       (mem_addr),
            .mem_r_en       (mem_r_en),
            .mem_w_data     (mem_w_data),
            .mem_sel        (mem_sel),
            .mem_r_data     (mem_r_data),
            .pc_wb          (debug_wb_pc),
            .w_addr_wb      (debug_wb_rf_wnum),
            .w_data_wb      (debug_wb_rf_wdata),
            .w_en_wb        (w_en_wb),
            .mem_available   (mem_available),
            .ext_int    (ext_int)
        );
    addr_trans rom_trans(
            .addr_in(pc),
            .addr_out(inst_sram_addr)
        );

    addr_trans ram_trans(
            .addr_in(mem_addr),
            .addr_out(data_sram_addr)
        );

endmodule
