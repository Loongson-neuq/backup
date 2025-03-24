`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
/*by srmk*/
//////////////////////////////////////////////////////////////////////////////////

`include "defines_cpu.vh"
module data_check(
    info_data_ex,
    info_data_mem_1,
    info_data_mem_2,
    r_data,
    r_addr,
    r_en,
    immediate_32,

    ope_data_reg,
    data_valid
    );
    input   wire[`info_data_bus]    info_data_ex;
    input   wire[`info_data_bus]    info_data_mem_1;
    input   wire[`info_data_bus]    info_data_mem_2;

    input   wire[`data_bus]         r_data;
    input   wire[`reg_addr_bus]     r_addr;
    input   wire[`data_bus]         immediate_32;
    input   wire                    r_en;

    output  wire[`data_bus]         ope_data_reg;
    output  wire                    data_valid;

    //--------------------------------------------------------------------------

    wire[`data_bus]                 w_data[2:0];
    wire[`reg_addr_bus]             w_addr[2:0];
    wire[2:0]                       w_en;
    wire[2:0]                       finish;

    assign {w_data[2],w_addr[2],w_en[2],finish[2]}      =       info_data_ex;
    assign {w_data[1],w_addr[1],w_en[1],finish[1]}      =       info_data_mem_1;
    assign {w_data[0],w_addr[0],w_en[0],finish[0]}      =       info_data_mem_2;

    //hit

    wire[2:0]   hit;

    for (genvar i = 0; i <= 2 ; i = i + 1) begin
        assign hit[i]       =       w_en[i]&&(w_addr[i] == r_addr)&&(|r_addr);
    end

    //ope data

    assign ope_data_reg     =       r_en?(hit[2]?w_data[2]:
                                          hit[1]?w_data[1]: 
                                          hit[0]?w_data[0]: 
                                          r_data): 
                                         immediate_32;
                                    


    assign data_valid       =       r_en?(hit[2]?finish[2]:
                                          hit[1]?finish[1]: 
                                          hit[0]?finish[0]: 
                                          `true_v): 
                                          `true_v;  



    
endmodule
