`include "lib/Defines.vh"
module Decode(
    input                       clk,                    //from mycpu_core
    input                       rst,
    input[31:0]                 inst_sram_rdata,

    input                       flush,                  //from CTRL
    input[5:0]                  stall,

    input[`F_D_Wid-1:0]         F_D_bus,                //from Fetch

    input                       pre_load_judge,
    input[`E_RF_Wid-1:0]        E_RF_bus,               //from Execute
    input[`M_RF_Wid-1:0]        M_RF_bus,               //from Memory
    input[`W_RF_Wid-1:0]        W_RF_bus,               //from Write_back
    

    output                      next_delayslot_judge_o, //forward Fetch 
    output                      stallreq_for_load,      //forward CTRL

    output[`D_E_Wid-1:0]        D_E_bus,                //forWard Execute
    output[`Bran_Wid-1:0]       bran_bus                //forWard Fetch_pre,Feych
);
/****************************************Accept data from the Fetch phase*******************************************************/
    reg         stall_buff;
    reg[31:0]   inst_buff;
    reg[`F_D_Wid-1:0]   F_D_bus_r;

    always@(posedge clk)begin
        if(rst|flush)begin
            F_D_bus_r  <= `F_D_Wid'b0;
            stall_buff <= 1'b0;

        end else if(stall[0]&(~stall[1]))begin  //Fetch pause-Decode continue
            F_D_bus_r  <= `F_D_Wid'b0;
            stall_buff <= 1'b0;
        end else if(~stall[0])begin             //Fetch continue
            F_D_bus_r  <= F_D_bus;
            stall_buff <= 1'b0;
        end else if(stall[0]&stall[1]&~stall_buff)begin //将初暂停的指令缓�?
            inst_buff  <= inst_sram_rdata;
            stall_buff <= 1'b1;
        end
    end

    wire[31:0]              d_pc, inst;
    wire                    ce, F_adel, delayslot_judge_i;

    assign inst = stall_buff ? inst_buff : inst_sram_rdata;

    assign {F_adel,delayslot_judge_i,ce, d_pc} = F_D_bus_r;

    wire[4:0]   rs = inst[25:21];
    wire[4:0]   rt = inst[20:16];
    wire[4:0]   rd = inst[15:11];

/********************************************************Inst_reco*******************************************************************/
                   
    wire[14:0]      arithmetic; //add,addu,sub,subu,slt,sltu,mul,slti,addi,addiu,sltiu,mult,multu,div,divu
    wire[7:0]       logic     ; //And,Nor,Or,Xor,lui,ori,andi,xor
    wire[5:0]       shift     ; //sll,sra,srl,sllv,srav,srlv
    wire[11:0]      branch    ; //beq,bne,bgez,bgtz,blez,bltz,bltzal,bgezal,jal,jalr,j,jr
    wire[3:0]       move      ; //mfhi,mflo,mthi,mtlo
    wire[2:0]       trap      ; //break,syscall,eret
    wire[11:0]      memory    ; //lb,lbu,lh,lhu,lw,lwl,lwr,sb,sh,sw,swl,swr
    wire[1:0]       special   ; //mfc0,mtc0

    wire                    nop        = (inst==32'b0);

    wire[`Instset_Wid-1:0]  Inst_Set   = {arithmetic,logic,shift,branch,move,trap,memory,special,nop};

    Inst_reco Inst_reco0
    (
        .inst               (inst),

        .arithmetic         (arithmetic),
        .logic              (logic),
        .shift              (shift),
        .branch             (branch),
        .move               (move),
        .trap               (trap),
        .memory             (memory),
        .special            (special)
    );


/***************************************************Exception************************************************************************/
    wire        Inst_invalid    = ~(|Inst_Set);

    wire[31:0] except_info_o    =   {27'b0,trap[2],trap[1],trap[0],Inst_invalid & !F_adel,1'b0};


/*********************************************solving data-related problems**********************************************************/
    wire       e_rf_we   , m_rf_we      , w_rf_we   ;
    wire[4:0]  e_rf_waddr, m_rf_waddr,  w_rf_waddr;
    wire[31:0] e_rf_wdata, m_rf_wdata,  w_rf_wdata;

    wire       e_hi_we, m_hi_we, w_hi_we;
    wire       e_lo_we, m_lo_we, w_lo_we;
    wire[31:0] e_hi_i , m_hi_i , w_hi_i ;
    wire[31:0] e_lo_i , m_lo_i , w_lo_i ;

    assign {e_hi_we, e_hi_i, e_lo_we, e_lo_i, 
            e_rf_we, e_rf_waddr, e_rf_wdata}     = E_RF_bus;

    assign {m_hi_we, m_hi_i, m_lo_we, m_lo_i, 
            m_rf_we, m_rf_waddr, m_rf_wdata}     = M_RF_bus;

    assign {w_hi_we, w_hi_i, w_lo_we, w_lo_i, 
            w_rf_we, w_rf_waddr, w_rf_wdata}     = W_RF_bus;
    
/*******************************************************Write back Regfile_hilo******************************************************/
    wire[31:0] hi_o, lo_o;
    hilo_reg  hilo_reg0(
    	.clk   (clk      ),
        .rst   (rst      ),
        .hi_we (w_hi_we  ),
        .hi_i  (w_hi_i   ),
        .lo_we (w_lo_we  ) ,
        .lo_i  (w_lo_i   ),

        .hi_o  (hi_o     ),
        .lo_o  (lo_o     )
    );

    wire[31:0] hi = e_hi_we  ? e_hi_i  :
                    m_hi_we  ? m_hi_i  :
                    w_hi_we  ? w_hi_i  :  hi_o;

    wire[31:0] lo = e_lo_we  ? e_lo_i  :
                    m_lo_we  ? m_lo_i  :
                    w_lo_we  ? w_lo_i  :  lo_o;
/*******************************************Determine  the type of the source Operand***************************************************/

    wire [2:0] sel_alu_src1;
    wire [3:0] sel_alu_src2;

    assign sel_alu_src1[0] = 1;                                     // rf_rdata1 to reg1
    assign sel_alu_src1[1] = |{branch[5:2]};                        // pc to reg1
    assign sel_alu_src1[2] = |{shift[5:3]};                         // sa_zero_extend to reg1

    assign sel_alu_src2[0] =  1;                                    //rf_rdata2 to reg2
    assign sel_alu_src2[1] = |{branch[5:2]};                        // 32'b8 to reg2
    assign sel_alu_src2[2] = |{logic[2:0]};                         // imm_zero_extend to reg2
    assign sel_alu_src2[3] = |{memory,logic[3],arithmetic[7:4]};    // imm_sign_extend to reg2

    wire   rf_we = |{arithmetic[14:4],logic,shift,memory[11:5],move[3:2],branch[5:2],special[1]};

    wire[2:0] sel_rf;

    assign sel_rf[0] = |{arithmetic[14:8],logic[7:4],shift,move[3:2]};
    assign sel_rf[1] = |{memory[11:5],arithmetic[7:4],logic[3:0],special[1]};
    assign sel_rf[2] = |{branch[5:2]};

    wire[4:0] rf_waddr = {5{sel_rf[0]}} & rd 
                        |{5{sel_rf[1]}} & rt
                        |{5{sel_rf[2]}} & 5'd31;

/***************************************************Write back Regfile_general**********************************************************/
    wire[31:0]  rf_rdata1, rf_rdata2;
    regfile regfile0(
    	.clk    (clk          ),
        .raddr1 (rs           ),
        .raddr2 (rt           ),
        .wen    (w_rf_we      ),
        .waddr  (w_rf_waddr   ),
        .wdata  (w_rf_wdata   ),

        .rdata1 (rf_rdata1    ),
        .rdata2 (rf_rdata2    )
    );

     wire[31:0]  rdata1,rdata2;

    assign  rdata1 = (e_rf_we & (e_rf_waddr == rs))     ? e_rf_wdata  :
                     (m_rf_we & (m_rf_waddr == rs))     ? m_rf_wdata  :
                     (w_rf_we & (w_rf_waddr == rs))     ? w_rf_wdata  :   rf_rdata1;

    assign  rdata2 = (e_rf_we & (e_rf_waddr == rt))     ? e_rf_wdata  :
                     (m_rf_we & (m_rf_waddr == rt))     ? m_rf_wdata  :
                     (w_rf_we & (w_rf_waddr == rt))     ? w_rf_wdata  :    rf_rdata2;

/****************************************** Processing of branch jump instructions**********************************************************/
    

    wire rs_eq_rt = (rdata1 == rdata2);
    wire rs_ge_z  = ~rdata1[31];
    wire rs_gt_z  = ($signed(rdata1) > 0);               //$signed修饰表示将rdata1视作有符号数
    wire rs_le_z  = ~rs_gt_z;                            //(rdata1[31] == 1'b1 || rdata1 == 32'b0);
    wire rs_lt_z  = (rdata1[31]);

    wire[31:0] pc_plus_4 = d_pc + 32'h4;

    wire   br_en = branch[11]  & rs_eq_rt | branch[10]  & ~rs_eq_rt
                  |branch[9]   & rs_ge_z  | branch[8]   & rs_gt_z
                  |branch[7]   & rs_le_z  | branch[6]   & rs_lt_z
                  |branch[5]   & rs_lt_z  | branch[4]   & rs_ge_z | (|branch[3:0]);

    wire[31:0] br_addr  = |(branch[11:4])             ? (pc_plus_4 + {{14{inst[15]}},inst[15:0],2'b0}) :
                           (branch[1]|branch[3])      ? {d_pc[31:28],inst[25:0],2'b0}                  :
                           (branch[0]|branch[2])      ? rdata1                                         : 32'b0;

    assign bran_bus = {br_en, br_addr};

/*****************************************Processing of memory access instructions*******************************************************/
    wire   data_sram_en  = |{memory};

    wire   data_sram_wen = |{memory[4:0]};

    wire   sel_rf_res    = |{memory[11:5]}; // 0 from alu_res . 1 from ld_res

/****************************************************************************************************************************************/
    assign   stallreq_for_load = pre_load_judge & (e_rf_waddr==rs|e_rf_waddr==rt); 

    wire[4:0] cp0_r_addr = special[1] ? rd : 5'b0;
    wire[4:0] cp0_w_addr = special[0] ? rd : 5'b0;

    assign next_delayslot_judge_o = | branch;

    wire delayslot_judge_o = delayslot_judge_i;

    assign D_E_bus = {
        F_adel,             // 312
        delayslot_judge_o,  // 311
        except_info_o,      // 310:279
        cp0_w_addr,         // 278:274
        cp0_r_addr,         // 273:269
        Inst_Set,           // 268:206
        hi, lo,             // 205:142
        d_pc,               // 141:110
        inst,               // 109:78
        sel_alu_src1,       // 77:75
        sel_alu_src2,       // 74:71
        rf_we,              // 70
        rf_waddr,           // 69:65
        sel_rf_res,         // 64
        rdata1,             // 63:32
        rdata2              // 31:0
    };


endmodule