`include "lib/Defines.vh"
module Execute(
    input                   clk,
    input                   rst,
    input                   memory_available,

    input                   flush,
    input[5:0]              stall,

    input[31:0]             cp0_data_i,
    input[37:0]             m_cp0_bus,
    input                   m_except,
    input[37:0]             w_cp0_bus, 

    input[`D_E_Wid-1:0]     D_E_bus,


    output                  data_sram_en,
    output[3:0]             data_sram_wen,
    output[31:0]            data_sram_addr,
    output[31:0]            data_sram_wdata,
    output[3:0]             data_sram_sel,

    output                  stallreq_for_ex,
    output                  stallreq_for_memory,

    output[4:0]             cp0_r_addr,

    output[`E_M_Wid-1:0]    E_M_bus,
    output[`E_RF_Wid-1:0]   E_RF_bus,
    output                  load_judge
);
    
/****************************************Accept data from the Decode phase*******************************************************/

    reg[`D_E_Wid-1:0] D_E_bus_r;

    always@ (posedge clk) begin
        if (rst|flush) begin
            D_E_bus_r <= `D_E_Wid'b0;
        
        end else if (stall[1] & (~stall[2])) begin
            D_E_bus_r <= `D_E_Wid'b0;
            
        end else if (~stall[1]) begin
            D_E_bus_r <= D_E_bus;
            
        end
    end
/*****************************************************Assign************************************************************************/
    wire[31:0]              e_pc, inst;
    wire[`Instset_Wid-1:0]  Inst_Set;

    wire                    rf_we;
    wire[4:0]               rf_waddr;
    wire[31:0]              rf_rdata1, rf_rdata2;

    wire[2:0]               sel_alu_src1;
    wire[3:0]               sel_alu_src2;

    //wire                    data_ram_en;
    //wire                    data_ram_wen;

    wire[31:0]              hi_i, lo_i;

    wire                    sel_rf_res;
    wire[4:0]               cp0_w_addr;
    wire[31:0]              except_info_i;
    wire                    F_adel;
    wire                    delayslot_judge_i;

    assign {
        F_adel           ,  // 312
        delayslot_judge_i,  // 311
        except_info_i,      // 310:279
        cp0_w_addr,         // 278:274
        cp0_r_addr,         // 273:269
        Inst_Set,           // 268:206
        hi_i, lo_i,         // 205:142
        e_pc,               // 141:110
        inst,               // 109:78
        sel_alu_src1,       // 77:75
        sel_alu_src2,       // 74:72
        rf_we,              // 70
        rf_waddr,           // 69:65
        sel_rf_res,         // 64
        rf_rdata1,          // 63:32
        rf_rdata2           // 31:0
    } = D_E_bus_r;

    wire[14:0]      arithmetic  = Inst_Set[62:48]; 
    wire[7:0]       logic       = Inst_Set[47:40];
    wire[5:0]       shift       = Inst_Set[39:34];
    wire[11:0]      branch      = Inst_Set[33:22];
    wire[3:0]       move        = Inst_Set[21:18];
    wire[11:0]      memory      = Inst_Set[14:3];
    wire[1:0]       special     = Inst_Set[2:1];

    assign load_judge = | memory[11:5];
/*******************************************************ALU****************************************************************************/
    wire[31:0] imm_sign_extend = {{16{inst[15]}},inst[15:0]};//立即数有符号扩展
    wire[31:0] imm_zero_extend = {16'b0, inst[15:0]};        //立即数无符号扩展
    wire[31:0] sa_zero_extend  = {27'b0,inst[10:6]};

    wire[31:0] alu_src1 = sel_alu_src1[1] ? e_pc :                          //确定操作数1
                          sel_alu_src1[2] ? sa_zero_extend : rf_rdata1;

    wire[31:0] alu_src2 = sel_alu_src2[1] ? 32'd8           :               //确定操作数1
                          sel_alu_src2[2] ? imm_zero_extend :
                          sel_alu_src2[3] ? imm_sign_extend : rf_rdata2;

    wire[31:0] alu_result;

    wire op_add =   |{arithmetic[14:13],arithmetic[6:5],branch[5:2],memory};//确定指令
    wire op_sub   = | arithmetic[12:11]  ;
    wire op_slt   = arithmetic[7] | arithmetic[10]  ;
    wire op_sltu  = arithmetic[4] | arithmetic[9]   ;
    
    wire op_xor   = logic[0]      | logic[4]        ;
    wire op_and   = logic[1]      | logic[7]        ; 
    wire op_or    = logic[2]      | logic[5]        ;
    wire op_lui   = logic[3];
    wire op_nor   = logic[6];

    wire op_sll   = shift[2]      | shift[5]        ;
    wire op_srl   = shift[0]      | shift[3]        ;
    wire op_sra   = shift[1]      | shift[4]        ;

    

    wire[31:0] add_sub_result, slt_result, sltu_result,
               and_result, nor_result, or_result, xor_result,
               sll_result, srl_result, sra_result, lui_result;

///////////////////////加减法//////////////////////////
    wire [31:0] a;
    wire [31:0] b;
    wire        cin;
    wire [31:0] adder_result;
    wire        cout;

    assign a   = alu_src1;              //rs,rt,rd
    assign b   = (op_sub | op_slt | op_sltu) ? ~alu_src2 : alu_src2;
    assign cin = (op_sub | op_slt | op_sltu) ? 1'b1      : 1'b0    ;
    assign {cout, adder_result} = a + b + cin;

    assign add_sub_result = adder_result;

    wire[31:0] b1 = (arithmetic[12]) ? (~alu_src2+1) : alu_src2;    //sub
    wire over_sit = ((!a[31] & !b1[31]) & (adder_result[31]))     //符号位
                    | ((a[31] & b1[31]) & (!adder_result[31]));

////////////////////////大小比较///////////////////////////

    assign slt_result[31:1] = 31'b0;
    assign slt_result[0] = (alu_src1[31] & ~alu_src2[31]) 
                         | (~(alu_src1[31]^alu_src2[31]) & adder_result[31]);
    
    assign sltu_result[31:1] = 31'b0;
    assign sltu_result[0] = ~cout;

/////////////////////////移位运算//////////////////////////
    assign sll_result = alu_src2 << alu_src1[4:0];
    assign srl_result = alu_src2 >> alu_src1[4:0];
    assign sra_result = ($signed(alu_src2)) >>> alu_src1[4:0]; //有符号数右移使用>>>,符号数为1则高位补1,反之补0

//////////////////////逻辑运算/////////////////////////////
    assign and_result = alu_src1 & alu_src2;        //与运算
    assign or_result  = alu_src1 | alu_src2;        //或运算
    assign nor_result = ~or_result;                 //或非运算
    assign xor_result = alu_src1 ^ alu_src2;        //异或运算
    assign lui_result = {alu_src2[15:0], 16'b0};    //{imm,16'b0}

    assign alu_result = ({32{op_add|op_sub  }} & add_sub_result)
                      | ({32{op_slt         }} & slt_result)
                      | ({32{op_sltu        }} & sltu_result)
                      | ({32{op_and         }} & and_result)
                      | ({32{op_nor         }} & nor_result)
                      | ({32{op_or          }} & or_result)
                      | ({32{op_xor         }} & xor_result)
                      | ({32{op_sll         }} & sll_result)
                      | ({32{op_srl         }} & srl_result)
                      | ({32{op_sra         }} & sra_result)
                      | ({32{op_lui         }} & lui_result)
                      | ({32{mul         }} & mult_result[31:0]);

/******************************************************Data_sram******************************************************/

    wire[31:0]  moveres;

    wire[31:0]  e_result =  special[1]  ? moveres  :
                            move[2]     ? lo_i     :
                            move[3]     ? hi_i     : alu_result;
    wire [3:0] byte_sel;

    decoder_2_4 u_decoder_2_4(
    	.in  (e_result[1:0]),
        .out (byte_sel      )
    );

    assign    data_sram_sel = (memory[4] | memory[10] | memory[11])   ? byte_sel                              :
                              (memory[3] | memory[9]  | memory[8])    ? {{2{byte_sel[2]}},{2{byte_sel[0]}}}   :
                              (memory[2] | memory[7])                 ? 4'b1111                               : 4'b0000;

    wire AdEL,AdES;

    assign data_sram_en     = |memory & (~(AdEL|AdES)) & ~m_except ;
    assign data_sram_wen    = {4{|memory[4:0]}}&data_sram_sel;
    assign data_sram_addr   = e_result;
    assign data_sram_wdata  = memory[4] ? {4{rf_rdata2[7:0]}}  :
                              memory[3] ? {2{rf_rdata2[15:0]}} :
                              memory[2] ?  rf_rdata2           :32'b0;
/**********************************************************Exception***************************************************************/
    wire over   =  (arithmetic[6] | arithmetic[12] | arithmetic[14]) & over_sit;        //addi,sub,add    
    
    assign AdEL = (memory[9]|memory[8]) & (data_sram_addr[0]!=1'b0)       ? 1'b1  :
                   memory[7]            & (data_sram_addr[1:0]!=2'b00)    ? 1'b1  :
                   F_adel                                                 ? 1'b1  : 0;
    assign AdES = memory[3] & (data_sram_addr[0]!=1'b0)         ? 1'b1 :
                  memory[2] & (data_sram_addr[1:0]!=2'b00)      ? 1'b1 : 0;

    wire[31:0]   except_info_o = {except_info_i[31:7],AdES,AdEL,over,except_info_i[4:1]};

    //assign Bd_wen = AdEL|AdES|F_adel;
    wire[31:0] Badaddr = F_adel       ? e_pc           :
                        (AdEL|AdES)   ? data_sram_addr : 32'b0;
/***********************************************************mul & div***************************************************************/

    wire        div  = arithmetic[1]; 
    wire        divu = arithmetic[0];
    wire[63:0]  div_result;
    wire[31:0]  div_data1_o,div_data2_o;
    wire        div_busy_i,div_end_i;
    wire        div_sign_o,div_start_o;
    wire        stallreq_for_div;

    wire        div_tran = (div|divu) & ~div_busy_i;

    assign div_data1_o = {32{div_tran}} & rf_rdata1;
    assign div_data2_o = {32{div_tran}} & rf_rdata2;
    assign div_sign_o  = div_tran & div;
    assign div_start_o = div_tran;
    assign stallreq_for_div = (div|divu) & (~div_end_i);

    DivCore DivCore0
        (
            .clk(clk),

            .A(div_data1_o),
            .B(div_data2_o),

            .start(div_start_o),

            .sign(div_sign_o),

        /******************************/

            .Data_ready(div_end_i),

            .result(div_result),

            .Busy(div_busy_i)
        );

    wire mul    = arithmetic[8];
    wire mult   = arithmetic[3];
    wire multu  = arithmetic[2];
    wire[63:0]  mult_result;  
    wire        mult_busy_i,mult_end_i;                                                                                                                                                                                                                                             // temp_mult;                                                                                                                           
    wire[31:0]  mult_data1_o,mult_data2_o;
    wire        mult_sign_o,mult_start_o;
    wire        stallreq_for_mult;

    wire   mult_tran = (mult|multu|mul) & ~mult_busy_i;

    assign mult_data1_o = {32{mult_tran}}&rf_rdata1;
    assign mult_data2_o = {32{mult_tran}}&rf_rdata2;
    assign mult_sign_o  = mult_tran&~multu;
    assign mult_start_o = mult_tran;
    assign stallreq_for_mult = (mult|multu|mul) & (~mult_end_i);

    MultCore MultCore0
        (
            .clk(clk),

            .A(mult_data1_o),
            .B(mult_data2_o),

            .start(mult_start_o),

            .sign(mult_sign_o),

            /*******************************/

            .Data_ready(mult_end_i),

            .result(mult_result),

            .Busy(mult_busy_i)
        );

    assign    stallreq_for_ex     =     stallreq_for_div | stallreq_for_mult;

    assign    stallreq_for_memory =     (|memory)&!memory_available&!flush&(except_info_o==`Zero_Word);

/**************************************************************************/

    wire op_mul = mult | multu;
    wire op_div = div  | divu;

    wire hi_we = move[1] | div | divu | mult | multu;
    wire lo_we = move[0] | div | divu | mult | multu;

    wire[31:0] hi_o = move[1]   ? rf_rdata1 : 
                      op_mul    ? mult_result[63:32] :
                      op_div    ? div_result[63:32]  : 32'b0;
    
    wire[31:0] lo_o = move[0]   ? rf_rdata1 :
                      op_mul    ? mult_result[31:0] :
                      op_div    ? div_result[31:0]  : 32'b0;

    wire[65:0] hilo_bus = { hi_we, hi_o, lo_we, lo_o };

/**************************************************** cp0 *************************************************************************/

   wire          m_cp0_we   , w_cp0_we   ;
   wire[4:0]     m_cp0_addr , w_cp0_addr ;
   wire[31:0]    m_cp0_wdata, w_cp0_wdata;
   wire          e_cp0_we = special[0];
  
   assign {m_cp0_wdata,m_cp0_addr,m_cp0_we} = m_cp0_bus;
   assign {w_cp0_wdata,w_cp0_addr,w_cp0_we} = w_cp0_bus;

   
   assign moveres = (m_cp0_we==1'b1 && m_cp0_addr==cp0_r_addr) ? m_cp0_wdata :
                    (w_cp0_we==1'b1 && w_cp0_addr==cp0_r_addr) ? w_cp0_wdata : cp0_data_i;

    wire[31:0] e_cp0_wdata;
    wire[37:0] e_cp0_bus;

    assign e_cp0_wdata = special[0] ? rf_rdata2 : 32'b0;
    assign e_cp0_bus   = {e_cp0_we,cp0_w_addr,e_cp0_wdata};
    
/************************************************Output******************************************************************************/

     wire  delayslot_judge_o = delayslot_judge_i;

    assign E_M_bus = {
        Badaddr,
        delayslot_judge_o,  // 223
        except_info_o,      // 222:191
        e_cp0_bus,          // 190:153
        memory,             // 152:141
        hilo_bus,           // 140:75
        e_pc,               // 74:43
        data_sram_sel,       // 42:39
        sel_rf_res,         // 38
        rf_we,              // 37
        rf_waddr,           // 36:32
        e_result            // 31:0
    };

    assign E_RF_bus = {
        hilo_bus,
        rf_we,
        rf_waddr,
        e_result
    };
    
endmodule