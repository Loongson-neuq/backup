`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
/*by srmk*/
//////////////////////////////////////////////////////////////////////////////////

`include "defines_cpu.vh"
module hilo_check(
    info_hilo_ex,
    info_hilo_mem_1,
    info_hilo_mem_2,

    r_en_hi,
    r_en_lo,

    r_data_hi,
    r_data_lo,

    ope_data_hi,
    ope_data_lo,
    hi_data_valid,
    lo_data_valid
    );

    
    input wire[`info_hilo_bus]      info_hilo_ex;
    input wire[`info_hilo_bus]      info_hilo_mem_1;
    input wire[`info_hilo_bus]      info_hilo_mem_2;

    input wire                      r_en_hi;
    input wire                      r_en_lo;

    input wire[`data_bus]           r_data_hi;
    input wire[`data_bus]           r_data_lo;

    output wire[`data_bus]          ope_data_hi;
    output wire[`data_bus]          ope_data_lo;
    output wire                     hi_data_valid;
    output wire                     lo_data_valid;
    //-----------------------------------------------------------

    wire[2:0]                       w_en_hi;
    wire[2:0]                       w_en_lo;
    wire[`data_bus]                 data_hi[2:0];
    wire[`data_bus]                 data_lo[2:0];
    wire[2:0]                       hi_valid;
    wire[2:0]                       lo_valid;

    assign {w_en_hi[2],w_en_lo[2],data_hi[2],data_lo[2],hi_valid[2],lo_valid[2]}        =       info_hilo_ex;
    assign {w_en_hi[1],w_en_lo[1],data_hi[1],data_lo[1],hi_valid[1],lo_valid[1]}        =       info_hilo_mem_1;
    assign {w_en_hi[0],w_en_lo[0],data_hi[0],data_lo[0],hi_valid[0],lo_valid[0]}        =       info_hilo_mem_2;


    //----------------------------------------------------------
    assign  ope_data_hi     =       r_en_hi?(w_en_hi[2]?data_hi[2]:
                                             w_en_hi[1]?data_hi[1]:
                                             w_en_hi[0]?data_hi[0]:
                                             r_data_hi): 
                                            `zero_32;

    assign  ope_data_lo     =       r_en_lo?(w_en_lo[2]?data_lo[2]:
                                             w_en_lo[1]?data_lo[1]:
                                             w_en_lo[0]?data_lo[0]:
                                             r_data_lo): 
                                            `zero_32;

    assign  hi_data_valid   =       r_en_hi?(w_en_hi[2]?hi_valid[2]:
                                             w_en_hi[1]?hi_valid[1]:
                                             w_en_hi[0]?hi_valid[0]:
                                             `true_v): 
                                            `true_v;

    assign  lo_data_valid   =       r_en_lo?(w_en_lo[2]?lo_valid[2]:
                                             w_en_lo[1]?lo_valid[1]:
                                             w_en_lo[0]?lo_valid[0]:
                                             `true_v): 
                                            `true_v;                                        

endmodule
