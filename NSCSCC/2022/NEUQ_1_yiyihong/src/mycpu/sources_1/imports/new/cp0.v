`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
/*by srmk*/
//////////////////////////////////////////////////////////////////////////////////

`define init_status             32'b00010000000000000000000000000000
`define init_config             32'b00000000000000001000000000000000
`define init_prid               32'b00000000010011000000000100000010

   

`include "defines_cpu.vh"
module cp0(
    resetn,
    clk,
    except_type_cp0,
    delay_slot_cp0,
    pc_mempt2,

    cp0_r_addr,
    cp0_r_en,
    cp0_r_data,

    cp0_w_en,
    cp0_w_addr,
    cp0_w_data,

    cp0_cause,
    cp0_status,
    cp0_epc,

    mem_addr_ex,

    flush,
    new_pc,

    ext_int
    );

    input wire                      resetn;
    input wire                      clk;
    input wire[`except_bus]         except_type_cp0;
    input wire[`addr_bus]           pc_mempt2;
    input wire                      delay_slot_cp0;

    input wire[`reg_addr_bus]       cp0_r_addr;
    input wire                      cp0_r_en;
    output wire[`data_bus]          cp0_r_data;

    input wire                      cp0_w_en;
    input wire[`reg_addr_bus]       cp0_w_addr;
    input wire[`data_bus]          cp0_w_data;

    output wire[`data_bus]          cp0_status;
    output wire[`data_bus]          cp0_cause;
    output wire[`data_bus]          cp0_epc;

    input wire[`addr_bus]           mem_addr_ex;

    output wire                     flush;
    output wire[`addr_bus]          new_pc;

    input  wire[5:0]                ext_int;

    reg                       count_state;
    //write
    always @(posedge clk) begin
        if(resetn == `rstn_enable)    count_state         <= 1'b0;
        else        count_state <= ~count_state;
    end


    reg[`data_bus]                  count_reg;
    reg[`data_bus]                  compare_reg;
    reg[`data_bus]                  status_reg;
    reg[`data_bus]                  cause_reg;
    reg[`data_bus]                  epc_reg;
    reg[`data_bus]                  config_reg;
    reg[`data_bus]                  prid_reg;

    reg[`data_bus]                  bad_addr_reg;

    wire[`data_bus]                 next_count      =       count_reg + 1;


    always @(posedge clk) begin
        if (resetn == `rstn_enable) begin
            count_reg   <=      `zero_32;
            compare_reg <=      `zero_32;
            status_reg  <=      `init_status;
            cause_reg   <=      `zero_32;
            epc_reg     <=      `zero_32;
            config_reg  <=      `init_config;
            prid_reg    <=      `init_prid;
            bad_addr_reg<=      `zero_32;
        end else begin
            if(count_state) begin count_reg   <=      next_count; end

            cause_reg[14:10] <= ext_int[4:0];
            if ((|compare_reg)&&count_reg == compare_reg) begin
                cause_reg[15] <= 1'b1;
            end else begin
                cause_reg[15] <= ext_int[5];
            end    
            if (cp0_w_en) begin
                case (cp0_w_addr)
                    `CP0_REG_COUNT:     begin
                        count_reg       <= cp0_w_data;
                    end
                    `CP0_REG_COMPARE:   begin
                        compare_reg     <= cp0_w_data;
                        //count_o <= `ZeroWord;
                        //timer_int       <= `false_v;
                    end
                    `CP0_REG_STATUS:    begin
                        status_reg      <= cp0_w_data;
                    end
                    `CP0_REG_EPC:   begin
                        epc_reg         <= cp0_w_data;
                    end
                    `CP0_REG_CAUSE: begin
                        cause_reg[9:8]  <= cp0_w_data[9:8];
                        cause_reg[23]   <= cp0_w_data[23];
                        cause_reg[22]   <= cp0_w_data[22];
                    end                 
                endcase
            end

            case (except_type_cp0)
                `exc_int:       begin
                    if(delay_slot_cp0) begin
                        epc_reg <= pc_mempt2 - 4 ;
                        cause_reg[31] <= 1'b1;
                    end else begin
                        epc_reg <= pc_mempt2;
                        cause_reg[31] <= 1'b0;
                    end
                    status_reg[1] <= 1'b1;
                    cause_reg[6:2] <= 5'b00000;
                end
                `exc_break:     begin
                    if(delay_slot_cp0) begin
                        epc_reg <= pc_mempt2 - 4 ;
                        cause_reg[31] <= 1'b1;
                    end else begin
                        epc_reg <= pc_mempt2;
                        cause_reg[31] <= 1'b0;
                    end
                    status_reg[1] <= 1'b1;
                    cause_reg[6:2] <= 5'b01001;
                end
                `exc_wraddr_ld:    begin 
                    if(delay_slot_cp0) begin
                        epc_reg <= pc_mempt2 - 4 ;
                        cause_reg[31] <= 1'b1;
                    end else begin
                        epc_reg <= pc_mempt2;
                        cause_reg[31] <= 1'b0;
                    end
                    status_reg[1] <= 1'b1;
                    cause_reg[6:2] <= 5'b00100;
                    bad_addr_reg <= mem_addr_ex;
                end  
                `exc_wraddr_st:      begin 
                    if(delay_slot_cp0) begin
                        epc_reg <= pc_mempt2 - 4 ;
                        cause_reg[31] <= 1'b1;
                    end else begin
                        epc_reg <= pc_mempt2;
                        cause_reg[31] <= 1'b0;
                    end
                    status_reg[1] <= 1'b1;
                    cause_reg[6:2] <= 5'b00101;
                    bad_addr_reg <= mem_addr_ex;
                end
                `exc_wrpc:      begin 
                    if(delay_slot_cp0) begin
                        epc_reg <= pc_mempt2 - 4 ;
                        cause_reg[31] <= 1'b1;
                    end else begin
                        epc_reg <= pc_mempt2;
                        cause_reg[31] <= 1'b0;
                    end
                    status_reg[1] <= 1'b1;
                    cause_reg[6:2] <= 5'b00100;
                    bad_addr_reg <= pc_mempt2;
                end 
                `exc_sys:      begin 
                    if(!status_reg[1]) begin
                        if(delay_slot_cp0) begin
                            epc_reg <= pc_mempt2 - 4 ;
                            cause_reg[31] <= 1'b1;
                        end else begin
                        epc_reg <= pc_mempt2;
                        cause_reg[31] <= 1'b0;
                        end
                    end
                    status_reg[1] <= 1'b1;
                    cause_reg[6:2] <= 5'b01000;
                end             
                `exc_invalid:      begin 
                    if(!status_reg[1]) begin
                        if(delay_slot_cp0) begin
                            epc_reg <= pc_mempt2 - 4 ;
                            cause_reg[31] <= 1'b1;
                        end else begin
                        epc_reg <= pc_mempt2;
                        cause_reg[31] <= 1'b0;
                        end
                    end
                    status_reg[1] <= 1'b1;
                    cause_reg[6:2] <= 5'b01010;
                end   
                `exc_ovfl:      begin 
                    if(!status_reg[1]) begin
                        if(delay_slot_cp0) begin
                            epc_reg <= pc_mempt2 - 4 ;
                            cause_reg[31] <= 1'b1;
                        end else begin
                        epc_reg <= pc_mempt2;
                        cause_reg[31] <= 1'b0;
                        end
                    end
                    status_reg[1] <= 1'b1;
                    cause_reg[6:2] <= 5'b01100;
                end   
                `exc_eret:      begin 
                    status_reg[1] <= 1'b0;
                end           
                default : begin
                 
                end
            endcase
            
        end
    end

    assign cp0_r_data       =       (cp0_r_en)?((cp0_r_addr == cp0_w_addr && cp0_w_en)?cp0_w_data:
                                                (cp0_r_addr == `CP0_REG_COUNT)?count_reg: 
                                                (cp0_r_addr == `CP0_REG_COMPARE)?compare_reg:
                                                (cp0_r_addr == `CP0_REG_STATUS)?status_reg:
                                                (cp0_r_addr == `CP0_REG_CAUSE)?cause_reg:
                                                (cp0_r_addr == `CP0_REG_EPC)?epc_reg:
                                                (cp0_r_addr == `CP0_REG_PrId)?prid_reg:
                                                (cp0_r_addr == `CP0_REG_CONFIG)?config_reg:
                                                (cp0_r_addr == `CPO_BADADDR)?bad_addr_reg:
                                                `zero_32): 
                                                `zero_32;

    assign cp0_status       =       (cp0_w_en&&cp0_w_addr==`CP0_REG_STATUS)?cp0_w_data:status_reg;
    assign cp0_cause        =       (cp0_w_en&&cp0_w_addr==`CP0_REG_CAUSE)?cp0_w_data:cause_reg;
    assign cp0_epc          =       (cp0_w_en&&cp0_w_addr==`CP0_REG_CAUSE)?cp0_w_data:epc_reg;


    flush_ctrl inst_flush_ctrl
        (
            .except_type_cp0 (except_type_cp0),
            .cp0_epc         (cp0_epc),
            .flush           (flush),
            .new_pc          (new_pc)
        );

endmodule
