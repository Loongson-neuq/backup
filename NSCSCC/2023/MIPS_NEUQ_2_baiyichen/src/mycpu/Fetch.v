`include "lib/Defines.vh"
module Fetch(
    input                   clk,            //from mycpu_core
    input                   rst,
    input                   fetch_available,

    input                   flush,          //from CTRL
    input[31:0]             new_pc,
    input[5:0]              stall,

    input[`Bran_Wid-1:0]    bran_bus,       //from Decode
    input                   delayslot_judge_i,


    output[`F_D_Wid-1:0]    F_D_bus,       //forword Fetch

    output                  stallreq_for_fetch,
    output                  inst_sram_en,   //forword mycpu_core
    output[3:0]             inst_sram_wen,
    output[31:0]            inst_sram_addr,
    output[31:0]            inst_sram_wdata
);
    
    reg[31:0]   pc_reg;//地址
    reg         ce_reg;//使能

    wire        bran_en;
    wire[31:0]  bran_addr;
    assign {bran_en, bran_addr} = bran_bus;

    wire[31:0] next_pc = flush   ? new_pc    :
                         stall[0]? pc_reg    : 
                         bran_en ? bran_addr : (pc_reg + 4);


    always@(posedge clk)begin
        if(rst)begin
            pc_reg <= 32'hbfc0_0000;
            ce_reg <= 1'b0;
        end
        else begin
            pc_reg <= next_pc;
            ce_reg <= 1'b1;
        end
    end

    wire   F_adel = (pc_reg[1:0]!=2'b00);

    assign F_D_bus = {F_adel,delayslot_judge_i,ce_reg, pc_reg};

    assign inst_sram_en    = ce_reg;   //ce_reg&~F_adel;
    assign inst_sram_addr  = pc_reg;
    assign inst_sram_wen   = 4'h0;
    assign inst_sram_wdata = 32'h0;

    assign stallreq_for_fetch = !fetch_available ;

endmodule

