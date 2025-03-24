`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
/*by srmk*/
//////////////////////////////////////////////////////////////////////////////////

`include "defines_cpu.vh"
module cpu(
    clk,
    resetn,
    inst,

    fetch_available,
    pc,
    fetch_en,

    mem_w_en,
    mem_addr,
    mem_r_en,
    mem_w_data,
    mem_sel,
    mem_r_data,
    mem_available,

    pc_wb,
    w_addr_wb,
    w_data_wb,
    w_en_wb,
    ext_int
    );
    input wire                              mem_available;
    input wire[5:0]     ext_int;

    input wire                              clk;
    input wire                              resetn;
    input wire[`inst_bus]                   inst;
    input wire                              fetch_available;

    output wire[`addr_bus]                  pc;
    output wire                             fetch_en;

    output wire                                 mem_w_en;
    output wire[`addr_bus]                      mem_addr;
    output wire                                 mem_r_en;
    output wire[`data_bus]                      mem_w_data;
    output wire[`sel_bus]                       mem_sel;
    input wire[`data_bus]                       mem_r_data;

    output wire[`addr_bus]                      pc_wb;
    output wire[`reg_addr_bus]                  w_addr_wb;
    output wire[`data_bus]                      w_data_wb;
    output wire                                 w_en_wb;
    //-----------------------------------------------



    wire[`stall_bus]                        stall;
    wire                                    stall_fetch             =       stall[6];
    wire[`stall_module_bus]                 stall_fe_dept1          =       stall[6:5];
    wire[`stall_module_bus]                 stall_de_pt1_pt2        =       stall[5:4];
    wire[`stall_module_bus]                 stall_dept2_expt1       =       stall[4:3];
    wire[`stall_module_bus]                 stall_expt1_mempt1      =       stall[3:2];
    wire[`stall_module_bus]                 stall_mem_pt1_pt2       =       stall[2:1];
    wire[`stall_module_bus]                 stall_mempt2_wb         =       stall[1:0];    

    wire                                    stall_req_fetch;
    //fetch
    wire                                    flush;
    wire[`inst_bus]                         new_pc;
    wire                                    branch_en;
    wire[`addr_bus]                         branch_pc;
    wire                                    resetn_fe_in;
    wire                                    flush_fe_in;

    fetch inst_fetch
        (
            .clk             (clk),
            .resetn          (resetn),
            .flush           (flush),
            .new_pc          (new_pc),
            .branch_en       (branch_en),
            .branch_pc       (branch_pc),
            .pc              (pc),
            .fetch_en        (fetch_en),
            .stall_fetch     (stall_fetch),
            .stall_req_fetch (stall_req_fetch),
            .fetch_available  (fetch_available),
            .resetn_fe_in    (resetn_fe_in),
            .flush_fe_in     (flush_fe_in)
        );

    //decode pt1    
    wire                                    resetn_pre;
    wire[`addr_bus]                         pc_dept1;
    wire                                    flush_pre;
    wire[`stall_module_bus]                 stall_fe_dept1_pre;

    wire                                    resetn_fe;
    wire                                    flush_fe;

    stage_fe_dept1 inst_stage_fe_dept1
        (
            .resetn             (resetn),
            .clk                (clk),
            .flush              (flush),
            .pc                 (pc),
            .stall_fe_dept1     (stall_fe_dept1),
            .pc_dept1           (pc_dept1),
            .resetn_pre         (resetn_pre),
            .stall_fe_dept1_pre (stall_fe_dept1_pre),
            .flush_pre          (flush_pre),
            .resetn_fe_in       (resetn_fe_in),
            .resetn_fe          (resetn_fe),
            .flush_fe_in        (flush_fe_in),
            .flush_fe           (flush_fe)
        );

    wire[`inst_bus]                         inst_dept1;
    wire                                    inst_save;
    wire[`info_decode_pt2_bus]              info_decode_pt2;
    wire                                    save        =       info_decode_pt2[0];

    inst_tran inst_inst_tran
        (
            .clk                (clk),
            .stall_fe_dept1_pre (stall_fe_dept1_pre),
            .flush_pre          (flush_pre),
            .resetn_pre         (resetn_pre),
            .inst               (inst),
            .branch_en          (branch_en),
            .inst_dept1         (inst_dept1),
            .resetn_fe          (resetn_fe),
            .save               (save),
            .flush_fe           (flush_fe),
            .resetn            (resetn),
            .fetch_available    (fetch_available),
            .flush             (flush)
        );

    wire[`info_decode_pt1_i]                info_decode_pt1;
    wire[`except_bus]                       except_type;
    wire[`addr_bus]                         pc_de_pt1_pt2;

    decode_pt1 inst_decode_pt1
        (
            .inst_dept1      (inst_dept1),
            .pc_dept1        (pc_dept1),
            .info_decode_pt1 (info_decode_pt1),
            .except_type     (except_type),
            .pc_de_pt1_pt2   (pc_de_pt1_pt2),
            .inst_save       (inst_save)
        );

    //decode pt2
    wire[`inst_bus]                         inst_dept2;
    wire[`info_decode_pt1_i]                info_decode_pt1_pt2;
    wire[`except_bus]                       except_type_decode_pt1_pt2;
    wire[`addr_bus]                         pc_dept2;

    stage_decode_pt1_pt2 inst_stage_decode_pt1_pt2
        (
            .stall_de_pt1_pt2           (stall_de_pt1_pt2),
            .resetn                     (resetn),
            .flush                      (flush),
            .clk                        (clk),
            .pc_de_pt1_pt2              (pc_de_pt1_pt2),
            .info_decode_pt1            (info_decode_pt1),
            .inst_dept1                 (inst_dept1),
            .except_type                (except_type),
            .inst_dept2                 (inst_dept2),
            .info_decode_pt1_pt2        (info_decode_pt1_pt2),
            .except_type_decode_pt1_pt2 (except_type_decode_pt1_pt2),
            .pc_dept2                   (pc_dept2)
        );

    //reg_file

    wire[`reg_addr_bus]                     w_addr;
    wire[`data_bus]                         w_data;
    wire                                    w_en;
    wire[`reg_addr_bus]                     r_addr_1;
    wire                                    r_en_1;
    wire[`reg_addr_bus]                     r_addr_2;
    wire                                    r_en_2;
    wire[`data_bus]                         r_data_1;
    wire[`data_bus]                         r_data_2;

    assign                                  w_addr_wb           =       w_addr;
    assign                                  w_data_wb           =       w_data;
    assign                                  w_en_wb             =       w_en;

    reg_file data_reg_file
        (
            .clk      (clk),
            .w_addr   (w_addr),
            .w_data   (w_data),
            .w_en     (w_en),
            .r_addr_1 (r_addr_1),
            .r_en_1   (r_en_1),
            .r_addr_2 (r_addr_2),
            .r_en_2   (r_en_2),
            .r_data_1 (r_data_1),
            .r_data_2 (r_data_2)
        );

    //cp0
    wire[`data_bus]                         cp0_r_data;
    wire[`reg_addr_bus]                     cp0_r_addr;
    wire                                    cp0_r_en;
    //hilo
    wire                                    r_en_hi;
    wire                                    r_en_lo;

    wire[`data_bus]                         r_data_hi;
    wire[`data_bus]                         r_data_lo;
    //info
    
    wire[`except_bus]                       except_type_pt2;
    wire[`addr_bus]                         pc_dept2_ex;
    //info reg
    wire[`info_data_bus]                    info_data_ex;
    wire[`info_data_bus]                    info_data_mem_1;
    wire[`info_data_bus]                    info_data_mem_2;
    //info hilo
    wire[`info_hilo_bus]                    info_hilo_ex;
    wire[`info_hilo_bus]                    info_hilo_mem_1;
    wire[`info_hilo_bus]                    info_hilo_mem_2;
    //info cp0
    wire[`info_data_bus]                    info_cp0_ex;
    wire[`info_data_bus]                    info_cp0_mem_1;
    wire[`info_data_bus]                    info_cp0_mem_2;
    //stall_req
    wire                                    stall_req_dept2;

    wire[`data_bus]                         additional_data;

    wire[`data_bus]                         cp0_cause;
    wire[`data_bus]                         cp0_status;
    wire[`addr_bus]                         wrong_mem_addr;


    decode_pt2 inst_decode_pt2
        (
            .inst_dept2                 (inst_dept2),
            .info_decode_pt1_pt2        (info_decode_pt1_pt2),
            .except_type_decode_pt1_pt2 (except_type_decode_pt1_pt2),
            .pc_dept2                   (pc_dept2),
            .branch_addr                (branch_pc),
            .branch_en                  (branch_en),
            .r_addr_1                   (r_addr_1),
            .r_en_1                     (r_en_1),
            .r_addr_2                   (r_addr_2),
            .r_en_2                     (r_en_2),
            .r_data_1                   (r_data_1),
            .r_data_2                   (r_data_2),
            .cp0_r_data                 (cp0_r_data),
            .cp0_r_addr                 (cp0_r_addr),
            .cp0_r_en                   (cp0_r_en),
            .r_en_hi                    (r_en_hi),
            .r_en_lo                    (r_en_lo),
            .r_data_hi                  (r_data_hi),
            .r_data_lo                  (r_data_lo),
            .info_decode_pt2            (info_decode_pt2),
            .except_type_pt2            (except_type_pt2),
            .pc_dept2_ex                (pc_dept2_ex),
            .info_data_ex               (info_data_ex),
            .info_data_mem_1            (info_data_mem_1),
            .info_data_mem_2            (info_data_mem_2),
            .info_hilo_ex               (info_hilo_ex),
            .info_hilo_mem_1            (info_hilo_mem_1),
            .info_hilo_mem_2            (info_hilo_mem_2),
            .info_cp0_ex                (info_cp0_ex),
            .info_cp0_mem_1             (info_cp0_mem_1),
            .info_cp0_mem_2             (info_cp0_mem_2),
            .stall_req_dept2            (stall_req_dept2),
            .additional_data            (additional_data),
            .cp0_cause                  (cp0_cause),
            .cp0_status                 (cp0_status)
        );

    wire                                    delay;
    wire[`addr_bus]                         pc_expt1;
    wire[`except_bus]                       except_type_expt1;
    wire[`info_decode_pt2_bus]              info_dept2_expt1;  
    wire[`data_bus]                         additional_data_ex;

    stage_dept2_expt1 inst_stage_dept2_expt1
        (
            .resetn              (resetn),
            .clk                 (clk),
            .flush               (flush),
            .stall_dept2_expt1   (stall_dept2_expt1),
            .pc_dept2_ex         (pc_dept2_ex),
            .info_decode_pt2     (info_decode_pt2),
            .delay_slot          (delay),
            .except_type_pt2     (except_type_pt2),
            .pc_expt1            (pc_expt1),
            .info_dept2_expt1    (info_dept2_expt1),
            .next_in_delay       (delay),
            .except_type_expt1   (except_type_expt1),
            .additional_data     (additional_data),
            .additional_data_ex  (additional_data_ex)
        );

    wire[`info_exe_bus]                     info_exe;
    wire[`except_bus]                       except_type_mem;
    wire                                    stall_req_ex;
    execute_pt1 inst_execute_pt1
        (
            .info_data_ex       (info_data_ex),
            .info_hilo_ex       (info_hilo_ex),
            .info_cp0_ex        (info_cp0_ex),
            .additional_data_ex (additional_data_ex),
            .info_dept2_expt1   (info_dept2_expt1),
            .info_exe           (info_exe),
            .except_type_expt1  (except_type_expt1),
            .except_type_mem    (except_type_mem),
            .stall_req_ex       (stall_req_ex),
            .clk                (clk),
            .resetn             (resetn),
            .flush              (flush)
        );

    wire[`info_exe_bus]                     info_exe_mem;
    wire[`except_bus]                       except_type_ex_mem;
    wire[`addr_bus]                         pc_mempt1;

    stage_ex_mem1 inst_stage_ex_mem1
        (
            .clk                (clk),
            .resetn             (resetn),
            .flush              (flush),
            .stall_expt1_mempt1 (stall_expt1_mempt1),
            .info_data_ex       (info_data_ex),
            .info_hilo_ex       (info_hilo_ex),
            .info_cp0_ex        (info_cp0_ex),
            .info_data_mem_1    (info_data_mem_1),
            .info_hilo_mem_1    (info_hilo_mem_1),
            .info_cp0_mem_1     (info_cp0_mem_1),
            .info_exe           (info_exe),
            .info_exe_mem       (info_exe_mem),
            .except_type_mem    (except_type_mem),
            .except_type_ex_mem (except_type_ex_mem),
            .pc_expt1           (pc_expt1),
            .pc_mempt1          (pc_mempt1)
        );

    wire                                            stall_req_mempt1;
    memory_pt1 inst_memory_pt1
        (
            .info_exe_mem        (info_exe_mem),
            .except_type_ex_mem (except_type_ex_mem),
            .mem_w_en           (mem_w_en),
            .mem_addr           (mem_addr),
            .mem_r_en           (mem_r_en),
            .mem_w_data         (mem_w_data),
            .mem_sel            (mem_sel),
            .flush              (flush),
            .stall_req_mempt1   (stall_req_mempt1),
            .mem_available       (mem_available)
        );

    wire[`addr_bus]                                 pc_mempt2;

    wire[`info_exe_bus]                             info_mempt1_mempt2;
    wire[`except_bus]                               except_type_cp0;

    wire[`info_data_bus]                            info_data_mem_2i;

    wire[`info_hilo_bus]                            info_hilo_mem_2i;

    wire                                            resetn_pre_mem;
    wire[`stall_module_bus]                         stall_pre_mem;
    wire                                            flush_pre_mem;

    


    stage_mempt1_mempt2 inst_stage_mempt1_mempt2
        (
            .clk                (clk),
            .resetn             (resetn),
            .flush              (flush),
            .info_exe_mem       (info_exe_mem),
            .except_type_ex_mem (except_type_ex_mem),
            .info_data_mem_1    (info_data_mem_1),
            .info_hilo_mem_1    (info_hilo_mem_1),
            .info_cp0_mem_1     (info_cp0_mem_1),
            .stall_mem_pt1_pt2  (stall_mem_pt1_pt2),
            .info_mempt1_mempt2 (info_mempt1_mempt2),
            .except_type_cp0    (except_type_cp0),
            .info_data_mem_2i   (info_data_mem_2i),
            .info_hilo_mem_2i   (info_hilo_mem_2i),
            .info_cp0_mem_2     (info_cp0_mem_2),
            .stall_pre_mem      (stall_pre_mem),
            .resetn_pre_mem     (resetn_pre_mem),
            .flush_pre_mem      (flush_pre_mem),
            .pc_mempt1          (pc_mempt1),
            .pc_mempt2          (pc_mempt2)
        );

    wire[`data_bus]                                 mem_r_data_mempt2;

    data_tran inst_data_tran
        (
            .clk               (clk),
            .stall_pre_mem     (stall_pre_mem),
            .flush_pre_mem     (flush_pre_mem),
            .resetn_pre_mem    (resetn_pre_mem),
            .mem_r_data        (mem_r_data),
            .mem_r_data_mempt2 (mem_r_data_mempt2)
        );

    wire[`addr_bus]                                 mem_addr_ex;
    wire                                            delay_slot_cp0;

    memory_pt2 inst_memory_pt2
        (
            .info_data_mem_2i   (info_data_mem_2i),
            .info_hilo_mem_2i   (info_hilo_mem_2i),
            .info_mempt1_mempt2 (info_mempt1_mempt2),
            .mem_r_data_mempt2  (mem_r_data_mempt2),
            .info_data_mem_2    (info_data_mem_2),
            .info_hilo_mem_2    (info_hilo_mem_2),
            .mem_addr_ex        (mem_addr_ex),
            .delay_slot_cp0     (delay_slot_cp0)
        );

    wire                                            w_en_hi;
    wire                                            w_en_lo;
    wire[`data_bus]                                 data_hi;
    wire[`data_bus]                                 data_lo;

    wire                                            cp0_w_en;
    wire[`reg_addr_bus]                             cp0_w_addr;
    wire[`data_bus]                                 cp0_w_data;

    stage_write_back inst_stage_write_back
        (
            .clk             (clk),
            .resetn          (resetn),
            .flush           (flush),
            .stall_mempt2_wb (stall_mempt2_wb),
            .info_data_mem_2 (info_data_mem_2),
            .info_hilo_mem_2 (info_hilo_mem_2),
            .info_cp0_mem_2  (info_cp0_mem_2),
            .pc_mempt2       (pc_mempt2),
            .w_addr          (w_addr),
            .w_en            (w_en),
            .w_data          (w_data),
            .w_en_hi         (w_en_hi),
            .data_hi         (data_hi),
            .w_en_lo         (w_en_lo),
            .data_lo         (data_lo),
            .cp0_w_en        (cp0_w_en),
            .cp0_w_addr      (cp0_w_addr),
            .cp0_w_data      (cp0_w_data),
            .pc_wb           (pc_wb)
        );

        
    hilo_reg inst_hilo_reg
        (
            .w_en_hi   (w_en_hi),
            .data_hi   (data_hi),
            .w_en_lo   (w_en_lo),
            .data_lo   (data_lo),
            .clk       (clk),
            .resetn    (resetn),
            .r_en_hi   (r_en_hi),
            .r_en_lo   (r_en_lo),
            .r_data_hi (r_data_hi),
            .r_data_lo (r_data_lo)
        );



    stall_ctrl inst_stall_ctrl
        (
            .stall_req_fetch  (stall_req_fetch),
            .stall_req_dept2  (stall_req_dept2),
            .stall_req_ex     (stall_req_ex),
            .stall_req_mempt1 (stall_req_mempt1),
            .stall            (stall)
        );


    cp0 inst_cp0
        (
            .resetn          (resetn),
            .clk             (clk),
            .except_type_cp0 (except_type_cp0),
            .delay_slot_cp0  (delay_slot_cp0),
            .pc_mempt2       (pc_mempt2),
            .cp0_r_addr      (cp0_r_addr),
            .cp0_r_en        (cp0_r_en),
            .cp0_r_data      (cp0_r_data),
            .cp0_w_en        (cp0_w_en),
            .cp0_w_addr      (cp0_w_addr),
            .cp0_w_data      (cp0_w_data),
            .cp0_cause       (cp0_cause),
            .cp0_status      (cp0_status),
            .cp0_epc         (),
            .mem_addr_ex     (mem_addr_ex),
            .flush           (flush),
            .new_pc          (new_pc),
            .ext_int(ext_int)
        );


endmodule
