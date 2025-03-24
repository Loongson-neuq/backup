`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
/*by srmk*/ 
//////////////////////////////////////////////////////////////////////////////////

`include "defines_cpu.vh"
module flush_ctrl(
    except_type_cp0,
    cp0_epc,

    flush,
    new_pc
    );
    input wire[`except_bus]                 except_type_cp0;
    input wire[`data_bus]                   cp0_epc;

    output wire                             flush;
    output wire[`addr_bus]                  new_pc;

    assign flush        =       |except_type_cp0;

    assign new_pc       =       (except_type_cp0 == `exc_eret)?cp0_epc: 
                                                               32'hbfc00380;

endmodule
