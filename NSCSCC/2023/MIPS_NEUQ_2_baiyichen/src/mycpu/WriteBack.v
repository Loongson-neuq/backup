`include "lib/Defines.vh"
module WriteBack(
    input                       clk,                //from mycpu_core
    input                       rst,

    input                       flush,              //from CTRL
    input[5:0]                  stall,

    input[37:0]                 m_cp0_bus,          //from Memory
    input[`M_W_Wid-1:0]         M_W_bus,


    output[`W_RF_Wid-1:0]       W_RF_bus,           //forward Decode

    output[37:0]                w_cp0_bus,          //forward Execute,Memory,Cp0

    output[31:0]                debug_wb_pc,        //forward mycpu_core
    output[3:0]                 debug_wb_rf_wen,
    output[4:0]                 debug_wb_rf_wnum,
    output[31:0]                debug_wb_rf_wdata 
);
/*******************************************Accept data from the Memory phase*******************************************************/
    reg[`M_W_Wid-1:0] M_W_bus_r;
    reg[37:0]         cp0_bus_r; 

    always @ (posedge clk) begin
        if (rst|flush) begin
            M_W_bus_r <= `M_W_Wid'b0;
            cp0_bus_r <= 38'b0;
        end else if (stall[3] & ~stall[4]) begin
            M_W_bus_r <= `M_W_Wid'b0;
            cp0_bus_r <= 38'b0;
        end else if (~stall[3]) begin
            M_W_bus_r <= M_W_bus;
            cp0_bus_r <= m_cp0_bus;
        end
    end

/*******************************************************Assign************************************************************************/
    assign w_cp0_bus = cp0_bus_r;

    wire[`HILO_Wid-1:0] hilo_bus;
    wire [31:0] w_pc;

    wire       rf_we;
    wire[4:0]  rf_waddr;
    wire[31:0] rf_wdata;

    assign {
        hilo_bus,
        w_pc,
        rf_we,
        rf_waddr,
        rf_wdata
    } = M_W_bus_r;

    
    assign W_RF_bus = {
        hilo_bus,
        rf_we,
        rf_waddr,
        rf_wdata
    };

    assign debug_wb_pc       = w_pc;
    assign debug_wb_rf_wen   = {4{rf_we}};
    assign debug_wb_rf_wnum  = rf_waddr;
    assign debug_wb_rf_wdata = rf_wdata;

endmodule