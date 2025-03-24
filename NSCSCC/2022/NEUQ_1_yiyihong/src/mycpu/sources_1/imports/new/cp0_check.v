`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
/*by srmk*/
//////////////////////////////////////////////////////////////////////////////////

`include "defines_cpu.vh"
module cp0_check(

    info_cp0_ex,
    info_cp0_mem_1,
    info_cp0_mem_2,
    cp0_r_data,
    cp0_r_addr,
    cp0_r_en,

    ope_data_cp0,
    data_valid_cp0
    );

    input   wire[`info_data_bus]    info_cp0_ex;
    input   wire[`info_data_bus]    info_cp0_mem_1;
    input   wire[`info_data_bus]    info_cp0_mem_2;

    input   wire[`data_bus]         cp0_r_data;
    input   wire[`reg_addr_bus]     cp0_r_addr;
    input   wire                    cp0_r_en;

    output  wire[`data_bus]         ope_data_cp0;
    output  wire                    data_valid_cp0;
    //-------------------------------------------------
    wire[`data_bus]                 cp0_w_data[2:0];
    wire[`reg_addr_bus]             cp0_w_addr[2:0];
    wire[2:0]                       cp0_w_en;
    wire[2:0]                       cp0_finish;

    assign {cp0_w_data[2],cp0_w_addr[2],cp0_w_en[2],cp0_finish[2]}      =       info_cp0_ex;
    assign {cp0_w_data[1],cp0_w_addr[1],cp0_w_en[1],cp0_finish[1]}      =       info_cp0_mem_1;
    assign {cp0_w_data[0],cp0_w_addr[0],cp0_w_en[0],cp0_finish[0]}      =       info_cp0_mem_2;


    wire hit[2:0];

    for (genvar i = 0; i <= 2; i = i + 1) begin
        assign  hit[i]  =   cp0_w_en[i]&&(cp0_w_addr[i] == cp0_r_addr);
    end


    //ope data

    assign ope_data_cp0     =       cp0_r_en?(hit[2]?cp0_w_data[2]:
                                              hit[1]?cp0_w_data[1]: 
                                              hit[0]?cp0_w_data[0]: 
                                              cp0_r_data): 
                                              `zero_32;
                                    


    assign data_valid_cp0       =   cp0_r_en?(hit[2]?cp0_finish[2]:
                                              hit[1]?cp0_finish[1]: 
                                              hit[0]?cp0_finish[0]: 
                                             `true_v): 
                                             `true_v;  

endmodule
