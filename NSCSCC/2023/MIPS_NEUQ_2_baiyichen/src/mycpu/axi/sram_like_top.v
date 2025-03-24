`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
/*by srmk*/
//////////////////////////////////////////////////////////////////////////////////


module cpu_sram_like(
    input           clk,
    input           resetn,
    input[5:0]      ext_int,

    //debug
    output[31:0]    debug_wb_pc,
    output[3 :0]    debug_wb_rf_wen,
    output[4 :0]    debug_wb_rf_wnum,
    output[31:0]    debug_wb_rf_wdata,

    //inst sram-like 
    output          inst_req     ,
    output          inst_wr      ,
    output[1:0]     inst_size    ,
    output[31:0]    inst_addr    ,
    output[31:0]    inst_wdata   ,
    input[31:0]     inst_rdata   ,
    input           inst_addr_ok ,
    input           inst_data_ok ,

    //data sram-like 
    output          data_req     ,
    output          data_wr      ,
    output[1 :0]    data_size    ,
    output[31:0]    data_addr    ,
    output[31:0]    data_wdata   ,
    input[31:0]     data_rdata   ,
    input           data_addr_ok ,
    input           data_data_ok 
    );


    wire        inst_sram_en;
    wire [3 :0] inst_sram_wen;
    wire [31:0] inst_sram_addr;
    wire [31:0] inst_sram_wdata;
    wire [31:0] inst_sram_rdata;

    wire        data_sram_en;
    wire [3 :0] data_sram_wen;
    wire [31:0] data_sram_addr;
    wire [31:0] data_sram_wdata;
    wire [31:0] data_sram_rdata;

    wire fetch_available;
    wire memory_available;
    wire flush;

    wire[3:0]   sel_cpu;
    sram_top mycpu_top_sram
        (
            .clk               (clk),
            .resetn            (resetn),
            .ext_int           (ext_int),

            .inst_sram_en      (inst_sram_en),
            .inst_sram_wen     (inst_sram_wen),
            .inst_sram_addr    (inst_sram_addr),
            .inst_sram_wdata   (inst_sram_wdata),
            .inst_sram_rdata   (inst_sram_rdata),
            .data_sram_en      (data_sram_en),
            .data_sram_wen     (data_sram_wen),
            .data_sram_addr    (data_sram_addr),
            .data_sram_wdata   (data_sram_wdata),
            .data_sram_rdata   (data_sram_rdata),

            .debug_wb_pc       (debug_wb_pc),
            .debug_wb_rf_wen   (debug_wb_rf_wen),
            .debug_wb_rf_wnum  (debug_wb_rf_wnum),
            .debug_wb_rf_wdata (debug_wb_rf_wdata),
            .fetch_available   (fetch_available),
            .memory_available  (memory_available),
            .data_sram_sel     (sel_cpu),
            .flush             (flush)
        );

    //fetch    

    sram_like inst_sram_like
        (
            .clk         (clk),
            .resetn      (resetn),
            .req         (inst_req),
            .wr          (inst_wr),
            .size        (inst_size),
            .addr        (inst_addr),
            .wdata       (inst_wdata),
            .addr_ok     (inst_addr_ok),
            .data_ok     (inst_data_ok),
            .rdata       (inst_rdata),
            .w_data_cpu  (32'b0),
            .r_data_cpu  (inst_sram_rdata),
            .r_en_cpu    (inst_sram_en),
            .w_en_cpu    (1'b0),
            .sel_cpu     (4'b1111),
            .addr_cpu    (inst_sram_addr),
            .trans_valid (fetch_available),
            .flush       (flush)
        );

    //mem
    wire r_en_cpu   =   data_sram_en&&(!(|data_sram_wen));
    wire w_en_cpu   =   data_sram_en&&(|data_sram_wen);

    sram_like data_sram_like
        (
            .clk         (clk),
            .resetn      (resetn),
            .req         (data_req),
            .wr          (data_wr),
            .size        (data_size),
            .addr        (data_addr),
            .wdata       (data_wdata),
            .addr_ok     (data_addr_ok),
            .data_ok     (data_data_ok),
            .rdata       (data_rdata),
            .w_data_cpu  (data_sram_wdata),
            .r_data_cpu  (data_sram_rdata),
            .r_en_cpu    (r_en_cpu),
            .w_en_cpu    (w_en_cpu),
            .sel_cpu     (sel_cpu),
            .addr_cpu    (data_sram_addr),
            .trans_valid (memory_available),
            .flush       (flush)
        );



endmodule
