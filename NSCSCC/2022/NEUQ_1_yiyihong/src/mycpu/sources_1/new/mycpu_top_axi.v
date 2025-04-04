`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
/*by srmk*/
//////////////////////////////////////////////////////////////////////////////////


module mycpu_top(
    input         aclk,
    input         aresetn, 
    input wire[5:0] ext_int,

    //debug
    output wire [31:0] debug_wb_pc,
    output wire [3 :0] debug_wb_rf_wen,
    output wire [4 :0] debug_wb_rf_wnum,
    output wire [31:0] debug_wb_rf_wdata,
    //axi
    //ar
    output [3 :0] arid         ,
    output [31:0] araddr       ,
    output [7 :0] arlen        ,
    output [2 :0] arsize       ,
    output [1 :0] arburst      ,
    output [1 :0] arlock        ,
    output [3 :0] arcache      ,
    output [2 :0] arprot       ,
    output        arvalid      ,
    input         arready      ,
    //r           
    input  [3 :0] rid          ,
    input  [31:0] rdata        ,
    input  [1 :0] rresp        ,
    input         rlast        ,
    input         rvalid       ,
    output        rready       ,
    //aw          
    output [3 :0] awid         ,
    output [31:0] awaddr       ,
    output [7 :0] awlen        ,
    output [2 :0] awsize       ,
    output [1 :0] awburst      ,
    output [1 :0] awlock       ,
    output [3 :0] awcache      ,
    output [2 :0] awprot       ,
    output        awvalid      ,
    input         awready      ,
    //w          
    output [3 :0] wid          ,
    output [31:0] wdata        ,
    output [3 :0] wstrb        ,
    output        wlast        ,
    output        wvalid       ,
    input         wready       ,
    //b           
    input  [3 :0] bid          ,
    input  [1 :0] bresp        ,
    input         bvalid       ,
    output        bready       
    );
    
    //inst sram-like 
    wire         inst_req       ;
    wire         inst_wr        ;
    wire  [1 :0] inst_size      ;
    wire  [31:0] inst_addr      ;
    wire  [31:0] inst_wdata     ;
    wire  [31:0] inst_rdata     ;
    wire         inst_addr_ok   ;
    wire         inst_data_ok   ;
    
    //data sram-like 
    wire         data_req     ;
    wire         data_wr      ;
    wire  [1 :0] data_size    ;
    wire  [31:0] data_addr    ;
    wire  [31:0] data_wdata   ;
    wire  [31:0] data_rdata   ;
    wire         data_addr_ok ;
    wire         data_data_ok ;


    cpu_axi_interface inst_cpu_axi_interface
        (
            .clk          (aclk),
            .resetn       (aresetn),
            .inst_req     (inst_req),
            .inst_wr      (inst_wr),
            .inst_size    (inst_size),
            .inst_addr    (inst_addr),
            .inst_wdata   (inst_wdata),
            .inst_rdata   (inst_rdata),
            .inst_addr_ok (inst_addr_ok),
            .inst_data_ok (inst_data_ok),
            .data_req     (data_req),
            .data_wr      (data_wr),
            .data_size    (data_size),
            .data_addr    (data_addr),
            .data_wdata   (data_wdata),
            .data_rdata   (data_rdata),
            .data_addr_ok (data_addr_ok),
            .data_data_ok (data_data_ok),
            .arid         (arid),
            .araddr       (araddr),
            .arlen        (arlen),
            .arsize       (arsize),
            .arburst      (arburst),
            .arlock       (arlock),
            .arcache      (arcache),
            .arprot       (arprot),
            .arvalid      (arvalid),
            .arready      (arready),
            .rid          (rid),
            .rdata        (rdata),
            .rresp        (rresp),
            .rlast        (rlast),
            .rvalid       (rvalid),
            .rready       (rready),
            .awid         (awid),
            .awaddr       (awaddr),
            .awlen        (awlen),
            .awsize       (awsize),
            .awburst      (awburst),
            .awlock       (awlock),
            .awcache      (awcache),
            .awprot       (awprot),
            .awvalid      (awvalid),
            .awready      (awready),
            .wid          (wid),
            .wdata        (wdata),
            .wstrb        (wstrb),
            .wlast        (wlast),
            .wvalid       (wvalid),
            .wready       (wready),
            .bid          (bid),
            .bresp        (bresp),
            .bvalid       (bvalid),
            .bready       (bready)
        );



    cpu_sram_like inst_cpu_sram_like
        (
            .clk               (aclk),
            .resetn            (aresetn),
            .debug_wb_pc       (debug_wb_pc),
            .debug_wb_rf_wen   (debug_wb_rf_wen),
            .debug_wb_rf_wnum  (debug_wb_rf_wnum),
            .debug_wb_rf_wdata (debug_wb_rf_wdata),
            .inst_req          (inst_req),
            .inst_wr           (inst_wr),
            .inst_size         (inst_size),
            .inst_addr         (inst_addr),
            .inst_wdata        (inst_wdata),
            .inst_rdata        (inst_rdata),
            .inst_addr_ok      (inst_addr_ok),
            .inst_data_ok      (inst_data_ok),
            .data_req          (data_req),
            .data_wr           (data_wr),
            .data_size         (data_size),
            .data_addr         (data_addr),
            .data_wdata        (data_wdata),
            .data_rdata        (data_rdata),
            .data_addr_ok      (data_addr_ok),
            .data_data_ok      (data_data_ok),
            .ext_int(ext_int)
        );


endmodule
