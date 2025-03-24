`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
/*by srmk*/
//////////////////////////////////////////////////////////////////////////////////

`include "defines_cpu.vh"
module execute_pt1(
    clk,
    resetn,
    flush,
    //info
    info_data_ex,
    info_hilo_ex,
    info_cp0_ex,
    additional_data_ex,


    info_dept2_expt1,
    info_exe,

    //except
    except_type_expt1,
    except_type_mem,

    //stall
    stall_req_ex

    );
    input   wire                                    clk;
    input   wire                                    resetn;
    input   wire                                    flush;

    output  wire[`info_data_bus]                    info_data_ex;
    output  wire[`info_cp0_bus]                     info_cp0_ex;
    output  wire[`info_hilo_bus]                    info_hilo_ex;

    input   wire[`info_decode_pt2_bus]              info_dept2_expt1;
    input   wire[`data_bus]                         additional_data_ex;

    output  wire[`info_exe_bus]                     info_exe;

    input   wire[`except_bus]                       except_type_expt1;
    output  wire[`except_bus]                       except_type_mem;

    output  wire                                    stall_req_ex;

    //----------------------------------------------------------------------------


    wire[`reg_addr_bus]                             w_addr;
    wire[`data_bus]                                 ope_data_1;
    wire[`data_bus]                                 ope_data_2;
    wire[`alu_op_bus]                               alu_op;
    wire[`alu_sel_bus]                              alu_sel;
    wire                                            delay_slot;

    assign  {w_addr,ope_data_1,ope_data_2,alu_op,alu_sel,delay_slot}            =       info_dept2_expt1;

    wire[`data_bus]                                 w_data;
    wire                                            w_en;

    //reg data

    //arthmetic
    wire[`data_bus]                                 data_arthmetic;
    

    //add
    wire[`data_bus]                                 ope_data_1_mux              =       (~ope_data_1) + 1;  
    wire[`data_bus]                                 ope_data_2_mux              =       (~ope_data_2) + 1;

    wire[`data_bus]                                 ope_data_2_add              =       (alu_op == `ex_sub_op|| 
                                                                                         alu_op == `ex_subu_op|
                                                                                         alu_op == `ex_slt_op)?ope_data_2_mux: 
                                                                                                               ope_data_2;

    wire[`data_bus]                                 data_sum                    =       ope_data_1 + ope_data_2_add;

    wire                                            over_flow                   =       (((!ope_data_1[31] && !ope_data_2_add[31]) && data_sum[31])||
                                                                                        ((ope_data_1[31] && ope_data_2_add[31]) && !data_sum[31]))&&
                                                                                        (alu_op == `ex_add_op||
                                                                                         alu_op == `ex_addi_op|| 
                                                                                         alu_op == `ex_sub_op)&&
                                                                                        (alu_sel == `exe_arthmetic);

    wire                                            compare                     =       (alu_op == `ex_slt_op)?((ope_data_1[31]&&!ope_data_2[31])||
                                                                                                                (!ope_data_1[31]&&!ope_data_2[31]&&data_sum[31])||
                                                                                                                (ope_data_1[31]&&ope_data_2[31]&&data_sum[31])): 
                                                                                                               ope_data_1 < ope_data_2;    

    assign                                          data_arthmetic              =       (alu_op == `ex_slt_op|| 
                                                                                         alu_op == `ex_sltu_op)?{31'b0,compare}: 
                                                                                        (alu_op == `ex_add_op ||
                                                                                         alu_op == `ex_addu_op || 
                                                                                         alu_op == `ex_addi_op || 
                                                                                         alu_op == `ex_addiu_op ||
                                                                                         alu_op == `ex_sub_op ||
                                                                                         alu_op == `ex_subu_op) ?data_sum: 
                                                                                         (alu_op == `ex_mul_op) ? mult_result[31:0]:`zero_32;
                                                                                           
    wire                                            w_en_arthmetic              =       over_flow?`false_v: 
                                                                                                  `true_v;

    //logic
    wire[`data_bus]                                 data_logic                  =       (alu_op == `ex_or_op)?ope_data_1 | ope_data_2: 
                                                                                        (alu_op == `ex_and_op)?ope_data_1 & ope_data_2: 
                                                                                        (alu_op == `ex_nor_op)?~(ope_data_1 | ope_data_2): 
                                                                                        (alu_op == `ex_xor_op)?ope_data_1 ^ ope_data_2: 
                                                                                        `zero_32;

    wire                                            w_en_logic                  =       `true_v; 

    //shift
    wire[`data_bus]                                 sra_data                    =       ({32{ope_data_2[31]}} << (6'd32-{1'b0,ope_data_1[4:0]}))|
                                                                                        ope_data_2 >> ope_data_1[4:0];

    wire[`data_bus]                                 data_shift                  =       (alu_op == `ex_sll_op)?ope_data_2 << ope_data_1[4:0]: 
                                                                                        (alu_op == `ex_srl_op)?ope_data_2 >> ope_data_1[4:0]:
                                                                                        (alu_op == `ex_sra_op)?sra_data: 
                                                                                        `zero_32;

    wire                                            w_en_shift                  =       `true_v;

    //branch
    wire[`data_bus]                                 data_branch                 =       ope_data_2;

    wire                                            w_en_branch                 =       (alu_op == `ex_bgezal_op||
                                                                                         alu_op == `ex_bltzal_op|| 
                                                                                         alu_op == `ex_jal_op|| 
                                                                                         alu_op == `ex_jalr_op)?`true_v: 
                                                                                                                `false_v;

    //move
    wire[`data_bus]                                 data_move                   =       ope_data_1;
    wire                                            w_en_move                   =       (alu_op == `ex_mfhi_op ||
                                                                                         alu_op == `ex_mflo_op )?`true_v: 
                                                                                                                 `false_v;

    //memory
    wire                                            wrong_addr                  =       except_type_expt1[4];
    wire[`data_bus]                                 mem_data                    =       ope_data_2;
                                                                                                      
    wire[`addr_bus]                                 mem_addr                    =       additional_data_ex;
    wire                                            w_en_memory                 =       (!wrong_addr)?((alu_op == `ex_lb_op|| 
                                                                                                       alu_op == `ex_lbu_op||
                                                                                                       alu_op == `ex_lh_op||
                                                                                                       alu_op == `ex_lhu_op||
                                                                                                       alu_op == `ex_lw_op||
                                                                                                       alu_op == `ex_lwl_op||
                                                                                                       alu_op == `ex_lwr_op)?`true_v: 
                                                                                                                             `false_v):`false_v;
    //special
    wire[`data_bus]                                 data_special                =       ope_data_1;                            
    wire                                            w_en_special                =       (alu_op == `ex_mfc0_op)?`true_v: 
                                                                                                                `false_v;

    //w_data
    assign                                          w_data                      =       (alu_sel == `exe_arthmetic)?data_arthmetic:
                                                                                        (alu_sel == `exe_logic)?data_logic:
                                                                                        (alu_sel == `exe_branch)?data_branch: 
                                                                                        (alu_sel == `exe_move)?data_move: 
                                                                                        (alu_sel == `exe_shift)?data_shift: 
                                                                                        (alu_sel == `exe_special)?data_special: 
                                                                                        `zero_32; 
    assign                                          w_en                        =       (w_addr  == 5'b0)?`false_v:
                                                                                        (alu_sel == `exe_arthmetic)?w_en_arthmetic:
                                                                                        (alu_sel == `exe_logic)?w_en_logic:
                                                                                        (alu_sel == `exe_branch)?w_en_branch: 
                                                                                        (alu_sel == `exe_move)?w_en_move: 
                                                                                        (alu_sel == `exe_shift)?w_en_shift: 
                                                                                        (alu_sel == `exe_special)?w_en_special:
                                                                                        (alu_sel == `exe_memory)?w_en_memory: 
                                                                                        `false_v;

    wire                                            finish_reg                  =       !(alu_sel == `exe_memory);

    assign                                          info_data_ex                =       {w_data,w_addr,w_en,finish_reg};
    

    //div mult
    //div
    /*
    wire                                            signed_div_i                =       (alu_op == `ex_div_op)?`true_v: 
                                                                                        (alu_op == `ex_divu_op)?`false_v: 
                                                                                        `false_v;

    wire[`data_bus]                                 opdata1_i                   =       ope_data_1;
    wire[`data_bus]                                 opdata2_i                   =       ope_data_2;

    wire                                            ready_o;
    wire[63:0]                                      result_o;                         

    wire                                            start_i                     =       (alu_sel == `exe_arthmetic)?((alu_op == `ex_div_op||
                                                                                                                      alu_op == `ex_divu_op)?((!ready_o)?`true_v: 
                                                                                                                                                         `false_v): 
                                                                                                                                             `false_v):
                                                                                                                    `false_v;
    wire                                            annul_i                     =       flush;

    wire                                            stall_for_div               =       start_i;

    div inst_div
        (
            .clk          (clk),
            .resetn       (resetn),
            .signed_div_i (signed_div_i),
            .opdata1_i    (opdata1_i),
            .opdata2_i    (opdata2_i),
            .start_i      (start_i),
            .annul_i      (annul_i),
            .result_o     (result_o),
            .ready_o      (ready_o)
        );
        */
    wire[63:0]  div_result;
    wire[31:0]  div_data1_o,div_data2_o;
    wire        div_busy_i,div_end_i;
    wire        div = (alu_op==`ex_div_op);
    wire        divu = (alu_op==`ex_divu_op); 
    wire        div_sign_o,div_start_o;
    wire        stallreq_for_div;

    assign div_data1_o = div|divu ? (~div_end_i ? (~div_busy_i ?  ope_data_1:32'b0):32'b0):32'b0;
    assign div_data2_o = div|divu ? (~div_end_i ? (~div_busy_i ?  ope_data_2:32'b0):32'b0):32'b0;
    assign div_sign_o = div ? (~div_end_i ? (~div_busy_i ?  1'b1:1'b0):1'b0):1'b0;
    assign div_start_o = div|divu ? (~div_end_i ? (~div_busy_i ?  1'b1:1'b0):1'b0):1'b0;
    assign stallreq_for_div = div|divu ? (~div_end_i ? 1'b1 : 1'b0) : 1'b0;

    DivCore DivCore0
        (
            .clk(clk),
            .rst(~resetn),

            .A(div_data1_o),
            .B(div_data2_o),

            .start(div_start_o),

            .sign(div_sign_o),

        /*********************************************/

            .Data_ready(div_end_i),

            .result(div_result),

            .Busy(div_busy_i)
        );

/******************************************/

    //mult                            

   // wire[`data_bus]                                 mult_data_1                 =       (alu_op == `ex_mult_op&&ope_data_1[31])?ope_data_1_mux: 
                                                                                                                               // ope_data_1;

    //wire[`data_bus]                                 mult_data_2                 =       (alu_op == `ex_mult_op&&ope_data_2[31])?ope_data_2_mux: 
                                                                                                                                //ope_data_2;

   // wire[63:0]                                      temp_mult                   =       mult_data_1 * mult_data_2;

   // wire[63:0]                                      temp_mult_mux               =       (~temp_mult)+1;

   // wire[63:0]                                      mult_result                 =       (alu_op == `ex_mult_op)?((ope_data_1[31] ^ ope_data_2[31])?temp_mult_mux: 
    
    wire[63:0]  mult_result;  
    wire        mult_busy_i,mult_end_i;                                                                                                                                     //temp_mult): 
    wire        mult =  (alu_op==`ex_mult_op);
    wire        multu=  (alu_op==`ex_multu_op);
    wire        mul = (alu_op==`ex_mul_op);                                                                                                           // temp_mult;                                                                                                                           
    wire[31:0]  mult_data1_o,mult_data2_o;
    wire        mult_sign_o,mult_start_o;
    wire        stallreq_for_mult;

    assign mult_data1_o = mult|multu|mul ? (~mult_end_i ? (~mult_busy_i ?  ope_data_1:32'b0):32'b0):32'b0;
    assign mult_data2_o = mult|multu|mul ? (~mult_end_i ? (~mult_busy_i ?  ope_data_2:32'b0):32'b0):32'b0;
    assign mult_sign_o = mult|mul ? (~mult_end_i ? (~mult_busy_i ?  1'b1:1'b0):1'b0):1'b0;
    assign mult_start_o = mult|multu|mul ? (~mult_end_i ? (~mult_busy_i ?  1'b1:1'b0):1'b0):1'b0;
    assign stallreq_for_mult = mult|multu|mul ? (~mult_end_i ? 1'b1 : 1'b0) : 1'b0;

    assign                                          stall_req_ex                =       stallreq_for_div | stallreq_for_mult;

    MultCore MultCore0
        (
            .clk(clk),

            .A(mult_data1_o),
            .B(mult_data2_o),

            .start(mult_start_o),

            .sign(mult_sign_o),


            /*********************************************/

            .Data_ready(mult_end_i),

            .result(mult_result),

            .Busy(mult_busy_i)
        );



/*********************************/
    //hilo
    wire[`data_bus]                                 data_hi                     =       (alu_sel == `exe_arthmetic&&(alu_op == `ex_div_op||
                                                                                                                     alu_op == `ex_divu_op))?div_result[63:32]: 
                                                                                        (alu_sel == `exe_arthmetic&&(alu_op == `ex_mult_op||
                                                                                                                     alu_op == `ex_multu_op))?mult_result[63:32]:
                                                                                                                    ope_data_1;

    wire                                            w_en_hi                     =       (alu_sel == `exe_move&&alu_op == `ex_mthi_op)||
                                                                                        (alu_sel == `exe_arthmetic&&(alu_op == `ex_div_op||
                                                                                                                     alu_op == `ex_divu_op||
                                                                                                                     alu_op == `ex_mult_op||
                                                                                                                     alu_op == `ex_multu_op));

    wire[`data_bus]                                 data_lo                     =       (alu_sel == `exe_arthmetic&&(alu_op == `ex_div_op||
                                                                                                                     alu_op == `ex_divu_op))?div_result[31:0]: 
                                                                                        (alu_sel == `exe_arthmetic&&(alu_op == `ex_mult_op||
                                                                                                                     alu_op == `ex_multu_op))?mult_result[31:0]:
                                                                                                                    ope_data_1;

    wire                                            w_en_lo                     =       (alu_sel == `exe_move&&alu_op == `ex_mtlo_op)||
                                                                                        (alu_sel == `exe_arthmetic&&(alu_op == `ex_div_op||
                                                                                                                     alu_op == `ex_divu_op||
                                                                                                                     alu_op == `ex_mult_op||
                                                                                                                     alu_op == `ex_multu_op));

    wire                                            hi_valid                    =       `true_v;
    wire                                            lo_valid                    =       `true_v;
    assign                                          info_hilo_ex                =       {w_en_hi,w_en_lo,data_hi,data_lo,hi_valid,lo_valid};  
    //cp0
    wire[`data_bus]                                 cp0_w_data                  =       ope_data_1;
    wire[`reg_addr_bus]                             cp0_w_addr                  =       w_addr;
    wire                                            cp0_w_en                    =       (alu_sel == `exe_special && alu_op == `ex_mtc0_op);
    wire                                            cp0_finish                  =       `true_v;

    assign                                          info_cp0_ex                 =       {cp0_w_data,cp0_w_addr,cp0_w_en,cp0_finish}; 



    //info
    assign                                          info_exe                    =       {alu_op,alu_sel,delay_slot,mem_data,mem_addr};
    assign                                          except_type_mem             =       {except_type_expt1[8:4],over_flow,except_type_expt1[2:0]};

endmodule
