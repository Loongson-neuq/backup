`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
/*by srmk*/ 
//////////////////////////////////////////////////////////////////////////////////

`include "defines_cpu.vh"
module decode_pt2(
    //decode
    inst_dept2,
    info_decode_pt1_pt2,
    except_type_decode_pt1_pt2,
    pc_dept2,
    additional_data,
    //branch
    branch_addr,
    branch_en,
    //data
        //regs
        r_addr_1,
        r_en_1,
        r_addr_2,
        r_en_2,
        r_data_1,
        r_data_2,
        //cp0
        cp0_r_data,
        cp0_r_addr,
        cp0_r_en,
        //hilo
        r_en_hi,
        r_en_lo,

        r_data_hi,
        r_data_lo,
    //info
    info_decode_pt2,
    except_type_pt2,
    pc_dept2_ex,

    info_data_ex,
    info_data_mem_1,
    info_data_mem_2,

    info_hilo_ex,
    info_hilo_mem_1,
    info_hilo_mem_2,

    info_cp0_ex,
    info_cp0_mem_1,
    info_cp0_mem_2,
    //stall req
    stall_req_dept2,
    //cp0
    cp0_cause,
    cp0_status
    );

    input wire[`data_bus]                       cp0_cause;
    input wire[`data_bus]                       cp0_status;
  
    //decode
    input wire[`inst_bus]                       inst_dept2;
    input wire[`info_decode_pt1_i]              info_decode_pt1_pt2;
    input wire[`except_bus]                     except_type_decode_pt1_pt2; 
    input wire[`addr_bus]                       pc_dept2;
    //branch
    output wire[`addr_bus]                      branch_addr;
    output wire                                 branch_en;
    //data
        //regs
        output wire[`reg_addr_bus]              r_addr_1;
        output wire                             r_en_1;
        output wire[`reg_addr_bus]              r_addr_2;
        output wire                             r_en_2;

        input wire[`data_bus]                   r_data_1;
        input wire[`data_bus]                   r_data_2;
        //cp0
        input   wire[`data_bus]                 cp0_r_data;
        output   wire[`reg_addr_bus]            cp0_r_addr;
        output   wire                           cp0_r_en;
        //hilo
        output wire                             r_en_hi;
        output wire                             r_en_lo;

        input wire[`data_bus]                   r_data_hi;
        input wire[`data_bus]                   r_data_lo;
    //info
    output wire[`info_decode_pt2_bus]           info_decode_pt2;
    output wire[`except_bus]                    except_type_pt2;
    output wire[`addr_bus]                      pc_dept2_ex;
    //info reg
    input   wire[`info_data_bus]    info_data_ex;
    input   wire[`info_data_bus]    info_data_mem_1;
    input   wire[`info_data_bus]    info_data_mem_2;
    //info hilo
    input wire[`info_hilo_bus]      info_hilo_ex;
    input wire[`info_hilo_bus]      info_hilo_mem_1;
    input wire[`info_hilo_bus]      info_hilo_mem_2;
    //info cp0
    input   wire[`info_data_bus]    info_cp0_ex;
    input   wire[`info_data_bus]    info_cp0_mem_1;
    input   wire[`info_data_bus]    info_cp0_mem_2;
    output  wire[`data_bus]         additional_data;
    //stall_req
    output wire                     stall_req_dept2;


    //---------------------------------------------------------------------------

    wire[`alu_op_bus]   alu_op;
    wire[`alu_sel_bus]  alu_sel;
    wire[`reg_addr_bus] w_addr;

    wire[`data_bus]   immediate_32_de; 
    wire[`data_bus]   immediate_32; 

    wire[`op_bus]       op                          =    inst_dept2[`op_index];
    wire[`ed_bus]       ed                          =    inst_dept2[`ed_index];

    //assign r_en_1 = info_decode_pt1_pt2[60];

    assign pc_dept2_ex = pc_dept2;

    assign {r_en_1,r_en_2,r_addr_1,r_addr_2,
            alu_op,alu_sel,immediate_32_de,w_addr}  =       info_decode_pt1_pt2[`info_decode_pt1_i];

    assign r_en_hi                                  =       alu_sel == `exe_move && ed ==  `ex_mfhi; 
    assign r_en_lo                                  =       alu_sel == `exe_move && ed ==  `ex_mflo;

    assign cp0_r_en                                 =       alu_sel == `exe_special && alu_op == `ex_mfc0_op;
    assign cp0_r_addr                               =       (alu_sel == `exe_special && alu_op == `ex_mfc0_op)?r_addr_1: 
                                                                                                               `zero_reg_addr;     

    //branch

    wire[`addr_bus] next_pc                         =       pc_dept2 + 4;

    wire[`addr_bus] pc_plus_8                       =       pc_dept2 + 8;
    wire[`addr_bus] pc_added                        =       next_pc + immediate_32_de;
    wire[`addr_bus] pc_j                            =       {next_pc[31:28],immediate_32_de[27:0]};



    assign immediate_32                             =       (alu_sel == `exe_branch)?pc_plus_8:
                                                                                    immediate_32_de; 
    //---------------------------------------------------------------------------------------------
    wire[`data_bus] ope_data_reg_1;
    wire[`data_bus] ope_data_reg_2;
    wire            data_valid_1;
    wire            data_valid_2;

    wire[`data_bus] ope_data_hi;
    wire[`data_bus] ope_data_lo;
    wire            hi_data_valid;
    wire            lo_data_valid;

    wire[`data_bus] ope_data_cp0;
    wire            data_valid_cp0;

    //ope data
    wire[`data_bus] ope_data_1;
    wire[`data_bus] ope_data_2;

    wire[`addr_bus] storage_addr                    =               ope_data_1 + immediate_32_de;

    assign  additional_data                         =               (alu_sel == `exe_memory)?storage_addr:
                                                                    (alu_sel == `exe_branch)?branch_addr: 
                                                                    `zero_32;

    assign  ope_data_1                              =               (alu_sel == `exe_nop|| 
                                                                     alu_sel == `exe_arthmetic|| 
                                                                     alu_sel == `exe_logic||
                                                                     alu_sel == `exe_shift||
                                                                     alu_sel == `exe_branch||
                                                                     alu_sel == `exe_trap||
                                                                     alu_sel == `exe_memory)?ope_data_reg_1:
                                                                    (alu_sel == `exe_move&&(ed == `ex_mthi || ed == `ex_mtlo))?ope_data_reg_1:
                                                                    (alu_sel == `exe_move&&ed == `ex_mfhi)?ope_data_hi:
                                                                    (alu_sel == `exe_move&&ed == `ex_mflo)?ope_data_lo:
                                                                    (alu_sel == `exe_special&&alu_op == `ex_mfc0_op)?ope_data_cp0: 
                                                                    (alu_sel == `exe_special&&alu_op == `ex_mtc0_op)?ope_data_reg_1: 
                                                                     `zero_32;

    assign   ope_data_2                             =               (alu_sel == `exe_nop|| 
                                                                     alu_sel == `exe_arthmetic|| 
                                                                     alu_sel == `exe_logic||
                                                                     alu_sel == `exe_shift||
                                                                     alu_sel == `exe_branch||
                                                                     alu_sel == `exe_trap)?ope_data_reg_2:
                                                                    (alu_sel == `exe_memory)?ope_data_reg_2: 
                                                                    (alu_sel == `exe_move&&(ed == `ex_mthi || ed == `ex_mtlo))?ope_data_reg_2:
                                                                    (alu_sel == `exe_move&&ed == `ex_mfhi)?ope_data_hi:
                                                                    (alu_sel == `exe_move&&ed == `ex_mflo)?ope_data_lo:
                                                                    (alu_sel == `exe_special)?ope_data_cp0: 
                                                                     `zero_32;                                                                 



        data_check data_check_1
        (
            .info_data_ex    (info_data_ex),
            .info_data_mem_1 (info_data_mem_1),
            .info_data_mem_2 (info_data_mem_2),
            .r_data          (r_data_1),
            .r_addr          (r_addr_1),
            .r_en            (r_en_1),
            .immediate_32    (immediate_32),
            .ope_data_reg    (ope_data_reg_1),
            .data_valid      (data_valid_1)
        );

        data_check data_check_2
        (
            .info_data_ex    (info_data_ex),
            .info_data_mem_1 (info_data_mem_1),
            .info_data_mem_2 (info_data_mem_2),
            .r_data          (r_data_2),
            .r_addr          (r_addr_2),
            .r_en            (r_en_2),
            .immediate_32    (immediate_32),
            .ope_data_reg    (ope_data_reg_2),
            .data_valid      (data_valid_2)
        );

            hilo_check inst_hilo_check
        (
            .info_hilo_ex    (info_hilo_ex),
            .info_hilo_mem_1 (info_hilo_mem_1),
            .info_hilo_mem_2 (info_hilo_mem_2),
            .r_en_hi         (r_en_hi),
            .r_en_lo         (r_en_lo),
            .r_data_hi       (r_data_hi),
            .r_data_lo       (r_data_lo),
            .ope_data_hi     (ope_data_hi),
            .ope_data_lo     (ope_data_lo),
            .hi_data_valid   (hi_data_valid),
            .lo_data_valid   (lo_data_valid)
        );

            cp0_check inst_cp0_check
        (
            .info_cp0_ex    (info_cp0_ex),
            .info_cp0_mem_1 (info_cp0_mem_1),
            .info_cp0_mem_2 (info_cp0_mem_2),
            .cp0_r_data     (cp0_r_data),
            .cp0_r_addr     (cp0_r_addr),
            .cp0_r_en       (cp0_r_en),
            .ope_data_cp0   (ope_data_cp0),
            .data_valid_cp0 (data_valid_cp0)
        );

    //------------------------------------------------------------------------------------------------
    wire    next_delay_slot                     =                   (alu_sel == `exe_branch);

    assign stall_req_dept2                      =                   (~data_valid_1)||(~data_valid_2)||
                                                                    (~hi_data_valid)||(~lo_data_valid)||(~data_valid_cp0);

    assign  branch_en                           =                  (alu_sel == `exe_branch)?(((alu_op == `ex_beq_op && 
                                                                                               ope_data_1 == ope_data_2)||
                                                                                              (alu_op == `ex_bne_op && 
                                                                                               ope_data_1 != ope_data_2)|| 
                                                                                              (alu_op == `ex_bgez_op && 
                                                                                               !ope_data_1[31])||
                                                                                              (alu_op == `ex_bgtz_op &&
                                                                                               !ope_data_1[31] && |ope_data_1[30:0])||
                                                                                              (alu_op == `ex_blez_op && 
                                                                                               (ope_data_1[31] || !(|ope_data_1)))||
                                                                                              (alu_op == `ex_bltz_op &&
                                                                                               ope_data_1[31])||
                                                                                              (alu_op == `ex_bgezal_op &&
                                                                                               !ope_data_1[31])||
                                                                                              (alu_op == `ex_bltzal_op &&
                                                                                               ope_data_1[31])||
                                                                                              (op == `ex_j||
                                                                                               op == `ex_jal||
                                                                                               alu_op == `ex_jr_op||
                                                                                               alu_op == `ex_jalr_op))?`true_v: 
                                                                                                               `false_v):`false_v;

    assign  branch_addr                         =                   (alu_sel == `exe_branch)?(((alu_op == `ex_beq_op && 
                                                                                               ope_data_1 == ope_data_2)||
                                                                                              (alu_op == `ex_bne_op && 
                                                                                               ope_data_1 != ope_data_2)|| 
                                                                                              (alu_op == `ex_bgez_op && 
                                                                                               !ope_data_1[31])||
                                                                                              (alu_op == `ex_bgtz_op &&
                                                                                               !ope_data_1[31] && |ope_data_1[30:0])||
                                                                                              (alu_op == `ex_blez_op && 
                                                                                               (ope_data_1[31] || !(|ope_data_1)))||
                                                                                              (alu_op == `ex_bltz_op &&
                                                                                               ope_data_1[31])||
                                                                                              (alu_op == `ex_bgezal_op &&
                                                                                               !ope_data_1[31])||
                                                                                              (alu_op == `ex_bltzal_op &&
                                                                                               ope_data_1[31]))?pc_added:
                                                                                              (op == `ex_j||
                                                                                               op == `ex_jal)?pc_j:
                                                                                              (alu_op == `ex_jr_op||
                                                                                               alu_op == `ex_jalr_op)?ope_data_1: 
                                                                                                              `zero_32):`zero_32;

    assign  info_decode_pt2                     =                   {w_addr,ope_data_1,ope_data_2,alu_op,alu_sel,next_delay_slot};
    //except

    wire[`data_bus] cp0_cause_new;
    wire[`data_bus] cp0_status_new;
    //get new cp0

    cp0_check cause_check
        (
            .info_cp0_ex    (info_cp0_ex),
            .info_cp0_mem_1 (info_cp0_mem_1),
            .info_cp0_mem_2 (info_cp0_mem_2),
            .cp0_r_data     (cp0_cause),
            .cp0_r_addr     (`CP0_REG_CAUSE),
            .cp0_r_en       (`true_v),
            .ope_data_cp0   (cp0_cause_new),
            .data_valid_cp0 ()
        );


    cp0_check status_check
        (
            .info_cp0_ex    (info_cp0_ex),
            .info_cp0_mem_1 (info_cp0_mem_1),
            .info_cp0_mem_2 (info_cp0_mem_2),
            .cp0_r_data     (cp0_status),
            .cp0_r_addr     (`CP0_REG_STATUS),
            .cp0_r_en       (`true_v),
            .ope_data_cp0   (cp0_status_new),
            .data_valid_cp0 ()
        );        


    wire interrupt                              =                       ((cp0_cause_new[15:8] & (cp0_status_new[15:8])) != 8'h00) && 
                                                                        (cp0_status_new[1] == 1'b0) && 
                                                                        (cp0_status_new[0] == 1'b1);

    wire store_except                           =                   (alu_sel == `exe_memory)?(((op == `ex_sh)&&
                                                                                                storage_addr[0])?`true_v: 
                                                                                              ((op == `ex_sw)&&
                                                                                                (|storage_addr[1:0]))?`true_v: 
                                                                                                                    `false_v):`false_v;
    wire load_except                            =                   (alu_sel == `exe_memory)?(((op == `ex_lh||
                                                                                                op == `ex_lhu)&&
                                                                                                storage_addr[0])?`true_v: 
                                                                                              ((op == `ex_lw)&&
                                                                                                (|storage_addr[1:0]))?`true_v: 
                                                                                                                    `false_v):`false_v;
    
    assign except_type_pt2                      =                   {except_type_decode_pt1_pt2[8],store_except,interrupt,except_type_decode_pt1_pt2[5],load_except,except_type_decode_pt1_pt2[3:0]};

endmodule
