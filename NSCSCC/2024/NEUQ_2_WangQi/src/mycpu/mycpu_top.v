`include "Defines.vh"
module mycpu_top(
    input  wire [7:0]  ext_int ,
    input  wire        aclk    ,
    input  wire        aresetn ,

    output wire [3 :0] arid   ,
    output wire [31:0] araddr ,
    output wire [7 :0] arlen  ,
    output wire [2 :0] arsize ,
    output wire [1 :0] arburst,
    output wire [1 :0] arlock ,
    output wire [3 :0] arcache,
    output wire [2 :0] arprot ,
    output wire        arvalid,
    input  wire        arready,

    input  wire [3 :0] rid    ,
    input  wire [31:0] rdata  ,
    input  wire [1 :0] rresp  ,
    input  wire        rlast  ,
    input  wire        rvalid ,
    output wire        rready ,

    output wire [3 :0] awid   ,
    output wire [31:0] awaddr ,
    output wire [7 :0] awlen  ,
    output wire [2 :0] awsize ,
    output wire [1 :0] awburst,
    output wire [1 :0] awlock ,
    output wire [3 :0] awcache,
    output wire [2 :0] awprot ,
    output wire        awvalid,
    input  wire        awready,

    output wire [3 :0] wid    ,
    output wire [31:0] wdata  ,
    output wire [3 :0] wstrb  ,
    output wire        wlast  ,
    output wire        wvalid ,
    input  wire        wready ,

    input  wire [3 :0] bid    ,
    input  wire [1 :0] bresp  ,
    input  wire        bvalid ,
    output wire        bready ,
    // trace debug interface
    output wire [31:0] debug_wb_pc,
    output wire [ 3:0] debug_wb_rf_we,
    output wire [ 4:0] debug_wb_rf_wnum,
    output wire [31:0] debug_wb_rf_wdata
);

wire                            FpD_valid;
wire [`FpD_BUS_Wid-1:0]         FpD_BUS;
wire                            pDD_valid;
wire [`pDD_BUS_Wid-1:0]         pDD_BUS;
wire                            DE_valid;
wire [`DE_BUS_Wid-1:0]          DE_BUS;
wire [`predict_BUS_Wid-1:0]     predict_BUS;
wire [`Branch_BUS_Wid-1:0]      Branch_BUS;
wire                            EM_valid;
wire [`EM_BUS_Wid-1:0]          EM_BUS;
wire                            MW_valid;
wire [`MW_BUS_Wid-1:0]          MW_BUS;
wire [`ED_for_BUS_Wid-1:0]      ED_for_BUS;
wire [13:0]                     csr_raddr_forward;
wire [31:0]                     csr_rdata_forward;
wire [`MD_for_BUS_Wid-1:0]      MD_for_BUS;
wire [`Wrf_BUS_Wid-1:0]         Wrf_BUS;
wire [`Wcsr_BUS_Wid-1:0]        Wcsr_BUS;
wire [`PB_BUS_Wid-1:0]          PB_BUS;

wire                            D_allowin;
wire                            E_allowin;
wire                            M_allowin;
wire                            W_allowin;

wire                            ex_D;
wire                            ex_E;
wire                            ex_en;
wire [31:0]                     ex_entryPC;
wire                            ertn_flush;
wire [31:0]                     new_pc;

wire                            predict_error;
wire [ 7:0]                     hardware_interrupt;
assign hardware_interrupt = ext_int;
//assign hardware_interrupt = 8'b0;

wire                            inst_sram_req;
wire [ 3:0]                     inst_sram_wstrb;
wire [31:0]                     inst_sram_addr;
wire [31:0]                     inst_sram_wdata;
wire [31:0]                     inst_sram_rdata;
wire [ 1:0]                     inst_sram_size;
wire                            inst_sram_addr_ok;
wire                            inst_sram_data_ok;
wire                            inst_sram_wr;

wire                            data_sram_req;
wire [ 3:0]                     data_sram_wstrb;
wire [31:0]                     data_sram_addr;
wire [31:0]                     data_sram_wdata;
wire [31:0]                     data_sram_rdata;
wire [ 1:0]                     data_sram_size;
wire                            data_sram_addr_ok;
wire                            data_sram_data_ok;
wire                            data_sram_wr;

cpu_axi_interface u_cpu_axi_interface(
    .clk          (aclk              ),
    .resetn       (aresetn           ),

    .inst_req     (inst_sram_req     ),
    .inst_wr      (inst_sram_wr      ),
    .inst_size    (inst_sram_size    ),
    .inst_addr    (inst_sram_addr    ),
    .inst_wdata   (inst_sram_wdata   ),
    .inst_rdata   (inst_sram_rdata   ),
    .inst_addr_ok (inst_sram_addr_ok ),
    .inst_data_ok (inst_sram_data_ok ),

    .data_req     (data_sram_req     ),
    .data_wr      (data_sram_wr      ),
    .data_size    (data_sram_size    ),
    .data_addr    (data_sram_addr    ),
    .data_wdata   (data_sram_wdata   ),
    .data_rdata   (data_sram_rdata   ),
    .data_addr_ok (data_sram_addr_ok ),
    .data_data_ok (data_sram_data_ok ),

    .arid         (arid          ),
    .araddr       (araddr        ),
    .arlen        (arlen         ),
    .arsize       (arsize        ),
    .arburst      (arburst       ),
    .arlock       (arlock        ),
    .arcache      (arcache       ),
    .arprot       (arprot        ),
    .arvalid      (arvalid       ),
    .arready      (arready       ),

    .rid          (rid           ),
    .rdata        (rdata         ),
    .rresp        (rresp         ),
    .rlast        (rlast         ),
    .rvalid       (rvalid        ),
    .rready       (rready        ),

    .awid         (awid          ),
    .awaddr       (awaddr        ),
    .awlen        (awlen         ),
    .awsize       (awsize        ),
    .awburst      (awburst       ),
    .awlock       (awlock        ),
    .awcache      (awcache       ),
    .awprot       (awprot        ),
    .awvalid      (awvalid       ),
    .awready      (awready       ),

    .wid          (wid           ),
    .wdata        (wdata         ),
    .wstrb        (wstrb         ),
    .wlast        (wlast         ),
    .wvalid       (wvalid        ),
    .wready       (wready        ),
    .bid          (bid           ),
    .bresp        (bresp         ),
    .bvalid       (bvalid        ),
    .bready       (bready        )
);


Fetch u_Fetch(
    .clk             (aclk             ),
    .rstn            (aresetn          ),
    .predict_BUS     (predict_BUS     ),
    .Branch_BUS      (Branch_BUS      ),
    .predict_error   (predict_error   ),
    .ex_D            (ex_D            ),
    .ex_E            (ex_E            ),
    .ex_en_i         (ex_en           ),
    .ex_entryPC      (ex_entryPC      ),
    .ertn_flush_i    (ertn_flush      ),
    .new_pc          (new_pc          ),
    .pD_allowin      (pD_allowin      ),
    .FpD_valid       (FpD_valid       ),
    .FpD_BUS         (FpD_BUS         ),
    .inst_sram_req     (inst_sram_req    ),
    .inst_sram_wstrb   (inst_sram_wstrb  ),
    .inst_sram_addr    (inst_sram_addr   ),
    .inst_sram_wdata   (inst_sram_wdata  ),
    .inst_sram_size    (inst_sram_size   ),
    .inst_sram_addr_ok (inst_sram_addr_ok),
    .inst_sram_data_ok (inst_sram_data_ok),
    .inst_sram_wr      (inst_sram_wr     ),
    .inst_sram_rdata   (inst_sram_rdata  )
);

preDecode u_preDecode(
    .clk             (aclk            ),
    .rstn            (aresetn         ),
    .FpD_valid       (FpD_valid       ),
    .FpD_BUS         (FpD_BUS         ),
    .pDD_valid       (pDD_valid       ),
    .pDD_BUS         (pDD_BUS         ),
    .D_allowin       (D_allowin       ),
    .pD_allowin      (pD_allowin      ),
    .predict_BUS     (predict_BUS     ),
    .PB_BUS          (PB_BUS          ),
    .predict_error   (predict_error   ),
    .ertn_flush      (ertn_flush      ),
    .ex_D            (ex_D            ),
    .ex_E            (ex_E            ),
    .ex_en           (ex_en           )
);

Decode u_Decode(
    .clk                (aclk               ),
    .rstn               (aresetn            ),
    .pDD_valid          (pDD_valid          ),
    .pDD_BUS            (pDD_BUS            ),
    .hardware_interrupt (hardware_interrupt ),
    .E_allowin          (E_allowin          ),
    .D_allowin          (D_allowin          ),
    .ED_for_BUS         (ED_for_BUS         ),
    .MD_for_BUS         (MD_for_BUS         ),
    .Wrf_BUS            (Wrf_BUS            ),
    .Wcsr_BUS           (Wcsr_BUS           ),
    .DE_valid           (DE_valid           ),
    .DE_BUS             (DE_BUS             ),
    .csr_raddr_forward  (csr_raddr_forward  ),
    .csr_rdata_forward  (csr_rdata_forward  ),
    .predict_error      (predict_error      ),
    .ex_D               (ex_D               ),
    .ex_en              (ex_en              ),
    .ex_entryPC         (ex_entryPC         ),
    .ertn_flush         (ertn_flush         ),
    .new_pc             (new_pc             )
);

Excute u_Excute(
    .clk             (aclk            ),
    .rstn            (aresetn         ),
    .M_allowin       (M_allowin       ),
    .E_allowin       (E_allowin       ),
    .DE_valid        (DE_valid        ),
    .DE_BUS          (DE_BUS          ),
    .EM_valid        (EM_valid        ),
    .EM_BUS          (EM_BUS          ),
    .ED_for_BUS      (ED_for_BUS      ),
    .csr_raddr_forward(csr_raddr_forward),
    .csr_rdata_forward(csr_rdata_forward),
    .ex_E            (ex_E            ),
    .ex_en           (ex_en           ),
    .predict_error   (predict_error   ),
    .Branch_BUS      (Branch_BUS      ),
    .data_sram_req    (data_sram_req    ),
    .data_sram_wr     (data_sram_wr     ),
    .data_sram_size   (data_sram_size   ),
    .data_sram_wstrb  (data_sram_wstrb  ),
    .data_sram_addr   (data_sram_addr   ),
    .data_sram_wdata  (data_sram_wdata  ),
    .data_sram_rdata  (data_sram_rdata  ),
    .data_sram_addr_ok(data_sram_addr_ok),
    .data_sram_data_ok(data_sram_data_ok)
);

Memory u_Memory(
    .clk             (aclk            ),
    .rstn            (aresetn         ),
    .W_allowin       (W_allowin       ),
    .M_allowin       (M_allowin       ),
    .EM_valid        (EM_valid        ),
    .EM_BUS          (EM_BUS          ),
    .MD_for_BUS      (MD_for_BUS      ),
    .ex_en           (ex_en           ),
    .MW_valid        (MW_valid        ),
    .MW_BUS          (MW_BUS          )
);
    
Writeback u_Writeback(
    .clk               (aclk              ),
    .rstn              (aresetn           ),
    .W_allowin         (W_allowin         ),
    .MW_valid          (MW_valid          ),
    .MW_BUS            (MW_BUS            ),
    .Wrf_BUS           (Wrf_BUS           ),
    .Wcsr_BUS          (Wcsr_BUS          ),
    .PB_BUS            (PB_BUS            ),
    .ex_en             (ex_en             ),
    .debug_wb_pc       (debug_wb_pc       ),
    .debug_wb_rf_we    (debug_wb_rf_we    ),
    .debug_wb_rf_wnum  (debug_wb_rf_wnum  ),
    .debug_wb_rf_wdata (debug_wb_rf_wdata )
);



endmodule