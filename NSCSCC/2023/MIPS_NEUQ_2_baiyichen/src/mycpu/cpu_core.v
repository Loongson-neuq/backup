`include "lib/Defines.vh"
module sram_top(
    input            clk,
    input            resetn,
    input[5:0]       ext_int,

    input            fetch_available,
    input            memory_available,

    input[31:0]      inst_sram_rdata,
    input[31:0]      data_sram_rdata,


    output           inst_sram_en,
    output[3:0]      inst_sram_wen,
    output[31:0]     inst_sram_addr,
    output[31:0]     inst_sram_wdata,

    output          data_sram_en,
    output[3:0]     data_sram_wen,
    output[31:0]    data_sram_addr,
    output[31:0]    data_sram_wdata,
    output[3:0]     data_sram_sel,

    output          flush,

    output[31:0]    debug_wb_pc,
    output[3:0]     debug_wb_rf_wen,
    output[4:0]     debug_wb_rf_wnum,
    output[31:0]    debug_wb_rf_wdata
);
    wire [`F_D_Wid-1:0 ]    F_D_bus    ;
    wire [`Bran_Wid-1:0]    bran_bus   ;
    wire [`D_E_Wid-1:0 ]    D_E_bus    ;
    wire [`E_M_Wid-1:0 ]    E_M_bus    ;
    wire [`M_W_Wid-1:0 ]    M_W_bus    ; 

    wire [`E_RF_Wid-1:0]    E_RF_bus    ;
    wire [`M_RF_Wid-1:0]    M_RF_bus    ;
    wire [`W_RF_Wid-1:0]    W_RF_bus    ;
    
    wire stallreq_for_load, stallreq_for_ex, stallreq_for_memory,stallreq_for_fetch;

    wire[5:0]   stall;
    //wire        flush;
    wire[31:0]  new_pc;

    wire        next_delayslot_judge;

    wire[4:0]   cp0_r_addr;
    wire[31:0]  cp0_data_o;

    wire[36+32:0]  m_cp0_imm;
    wire[37:0]  m_cp0_bus;

    wire[37:0]  w_cp0_bus;

    wire[95:0]  cp0_bus;
    wire[31:0]  latest_epc;

    wire        load_judge;

    wire[31:0]  inst_sram_addr_v,data_sram_addr_v;

    assign inst_sram_addr = (inst_sram_addr_v[31]&~inst_sram_addr_v[30]) ? inst_sram_addr_v&32'h1fff_ffff : inst_sram_addr_v;
    assign data_sram_addr = (data_sram_addr_v[31]&~data_sram_addr_v[30]) ? data_sram_addr_v&32'h1fff_ffff : data_sram_addr_v;

    wire    m_except;
    
    Fetch  Fetch0(
        .clk            (clk                    ),       //from mycpu_core
        .rst            (~resetn                ),
        .fetch_available(fetch_available        ),

        .flush          (flush                  ),       //from CTRL
        .new_pc         (new_pc                 ),
        .stall          (stall                  ),

        .bran_bus       (bran_bus               ),       //from Decode
        .delayslot_judge_i(next_delayslot_judge ),

    //-----------------------------------------------

        .F_D_bus        (F_D_bus                ),       //forword Fetch
        .stallreq_for_fetch(stallreq_for_fetch  ),

        .inst_sram_en   (inst_sram_en           ),        //forword mycpu_core
        .inst_sram_wen  (inst_sram_wen          ),
        .inst_sram_addr (inst_sram_addr_v       ),
        .inst_sram_wdata(inst_sram_wdata        )
    );

    Decode Decode0(
    	.clk                (clk                ),
        .rst                (~resetn            ),
        .inst_sram_rdata    (inst_sram_rdata    ),
    
        .flush              (flush              ),
        .stall              (stall              ),

        .F_D_bus            (F_D_bus            ),

        .pre_load_judge     (load_judge         ),

        .E_RF_bus           (E_RF_bus           ),
        .M_RF_bus           (M_RF_bus           ),
        .W_RF_bus           (W_RF_bus           ),

     //----------------------------------------------

        .next_delayslot_judge_o(next_delayslot_judge),
        
        .stallreq_for_load     (stallreq_for_load   ),

        .bran_bus              (bran_bus            ),
        .D_E_bus               (D_E_bus             )

    );

    Execute Execute0(
    	.clk             (clk                   ),
        .rst             (~resetn               ),
        .memory_available(memory_available      ),

        .flush           (flush                 ),
        .stall           (stall                 ),
        
        .cp0_data_i      (cp0_data_o            ),

        .m_cp0_bus       (m_cp0_bus             ),
        .m_except        (m_except              ),
        .w_cp0_bus       (w_cp0_bus             ),

        .D_E_bus         (D_E_bus               ),

     //----------------------------------------------

        .cp0_r_addr      (cp0_r_addr            ),

        .E_M_bus         (E_M_bus               ),
        .E_RF_bus        (E_RF_bus              ),

        .stallreq_for_ex (stallreq_for_ex       ),
        .stallreq_for_memory(stallreq_for_memory),

        .load_judge      (load_judge            ),

        .data_sram_en    (data_sram_en          ),
        .data_sram_wen   (data_sram_wen         ),
        .data_sram_addr  (data_sram_addr_v      ),
        .data_sram_wdata (data_sram_wdata       ),
        .data_sram_sel   (data_sram_sel         )
    );

    Memory Memory0(
    	.clk             (clk                   ),
        .rst             (~resetn               ),

        .flush           (flush                 ),
        .stall           (stall                 ),

        .E_M_bus         (E_M_bus               ),

        .w_cp0_bus       (w_cp0_bus             ),
        .cp0_bus         (cp0_bus               ),

        .data_sram_rdata (data_sram_rdata       ),

     //----------------------------------------------
        .m_cp0_imm       (m_cp0_imm             ),
        .m_cp0_bus       (m_cp0_bus             ),
        .m_except        (m_except              ),

        .cp0_epc_o       (latest_epc            ),
    
        .M_W_bus         (M_W_bus               ),
        .M_RF_bus        (M_RF_bus              )
    );
    
    WriteBack WriteBack0(
    	.clk               (clk                 ),
        .rst               (~resetn             ),

        .flush             (flush               ),
        .stall             (stall               ),

        .m_cp0_bus         (m_cp0_bus           ),

        .M_W_bus           (M_W_bus             ),

     //----------------------------------------------

        .W_RF_bus          (W_RF_bus            ),
        .w_cp0_bus         (w_cp0_bus           ),

        .debug_wb_pc       (debug_wb_pc         ),
        .debug_wb_rf_wen   (debug_wb_rf_wen     ),
        .debug_wb_rf_wnum  (debug_wb_rf_wnum    ),
        .debug_wb_rf_wdata (debug_wb_rf_wdata   )
    );

    CP0_reg CP0_reg0(
        .clk                (clk                ),
        .rst                (~resetn            ),

        .r_addr_i           (cp0_r_addr         ),

        .m_cp0_bus          (m_cp0_imm          ),

        .w_cp0_bus          (w_cp0_bus          ),

        .interr_i           (ext_int            ),

    //-----------------------------------------------

        .cp0_bus            (cp0_bus            ),

        .data_o             (cp0_data_o         )
    );

    CTRL CTRL0(
    	.rst               (~resetn             ),

        .stallreq_for_ex   (stallreq_for_ex     ),
        .stallreq_for_load (stallreq_for_load   ),
        .stallreq_for_fetch(stallreq_for_fetch  ),
        .stallreq_for_memory(stallreq_for_memory),
        .except_info_i     (m_cp0_imm[3:0]      ),
        .cp0_epc_i         (latest_epc          ),

     //----------------------------------------------
        .flush             (flush               ),
        .new_pc            (new_pc              ), 

        .stall             (stall               )
    );
    
    
endmodule