`include "lib/Defines.vh"
module Memory(
    input                   clk,                //from mycpu_core
    input                   rst,
    input[31:0]             data_sram_rdata,

    input                   flush,              //from CTRL
    input[5:0]              stall,

    input[95:0]             cp0_bus,            //from cp0

    input[37:0]             w_cp0_bus,          //from Write_back
    
    input[`E_M_Wid-1:0]     E_M_bus,            //from Execute
    

    output                  m_except,
    
    output[36+32:0]         m_cp0_imm,          //forward cp0

    output[31:0]            cp0_epc_o,          //forward CTRL

    output[`M_W_Wid-1:0]    M_W_bus,            //forward Write_back

    output[37:0]            m_cp0_bus,          //forward Write_back,Execute
    
    output[`M_RF_Wid-1:0]   M_RF_bus            //forward Decode
);
/*******************************************Accept data from the Exucute phase*******************************************************/
    reg [`E_M_Wid-1:0] E_M_bus_r;

    always @ (posedge clk) begin
        if (rst|flush) begin
            E_M_bus_r <= `E_M_Wid'b0;
           
        end else if (stall[2] & ~stall[3]) begin
            E_M_bus_r <= `E_M_Wid'b0;
           
        end else if (~stall[2]) begin
            E_M_bus_r <= E_M_bus;
           
        end
    end

/*******************************************************Assign************************************************************************/
    //wire        data_ram_en;
    //wire        data_ram_wen;
    wire[3:0]   data_ram_sel;

    wire        sel_rf_res;
    wire        rf_we;
    wire[4:0]   rf_waddr;
    wire[31:0]  rf_wdata;

    wire [31:0] e_result;

    wire [11:0] mem_op;
    wire [65:0] hilo_bus;
    wire [31:0] m_pc;

    wire[37:0] m_cp0_bus_i;
    wire[31:0] except_info_i;
    wire       delayslot_judge_i;
    wire[31:0] Badaddr;

    assign {
        Badaddr,
        delayslot_judge_i,  // 223
        except_info_i,      // 222:191
        m_cp0_bus_i,        // 190:153
        mem_op,             // 152:141
        hilo_bus,           // 140:75
        m_pc,               // 74:43
        data_ram_sel,       // 42:39
        sel_rf_res,         // 38
        rf_we,              // 37
        rf_waddr,           // 36:32
        e_result            // 31:0
    } =  E_M_bus_r;

    assign m_cp0_bus = m_cp0_bus_i;

    wire lb,lbu,lh,lhu,lw,lwl,lwr,sb,sh,sw,swl,swr; 

    assign { lb,lbu,lh,lhu,lw,lwl,lwr,
                    sb,sh,sw,swl,swr } = mem_op;
/*******************************************************Mem_inst***********************************************************************/
    wire[7:0]   byte_data;
    wire[15:0]  half_data;
    wire[31:0]  word_data;

    assign byte_data = data_ram_sel[3] ? data_sram_rdata[31:24] : 
                       data_ram_sel[2] ? data_sram_rdata[23:16] :
                       data_ram_sel[1] ? data_sram_rdata[15: 8] : 
                       data_ram_sel[0] ? data_sram_rdata[ 7: 0] : 8'b0;

    assign half_data = data_ram_sel[2] ? data_sram_rdata[31:16] :
                       data_ram_sel[0] ? data_sram_rdata[15: 0] : 16'b0;

    assign word_data = data_sram_rdata;

    wire[31:0] m_result =   lb     ? {{24{byte_data[7]}},byte_data} :
                            lbu    ? {{24{1'b0}},byte_data} :
                            lh     ? {{16{half_data[15]}},half_data} :
                            lhu    ? {{16{1'b0}},half_data} :
                            lw     ? word_data : 32'b0; 
    


    assign rf_wdata = |(mem_op[11:5]) ? m_result : e_result;

/**************************************************************Cp0**********************************************************************/
    wire w_cp0_we;
    wire[4:0] w_cp0_addr;
    wire[31:0] w_cp0_wdata;
    
    wire[31:0] cp0_status_i, cp0_cause_i, cp0_epc_i;

    assign {w_cp0_we,w_cp0_addr,w_cp0_wdata} =  w_cp0_bus;
    assign {cp0_status_i, cp0_cause_i, cp0_epc_i} = cp0_bus;

    wire[31:0] cp0_status = (w_cp0_we & w_cp0_addr==`CP0_Reg_status) ? w_cp0_wdata:cp0_status_i;
    wire[31:0] cp0_epc    = (w_cp0_we & w_cp0_addr==`CP0_Reg_epc) ? w_cp0_wdata:cp0_epc_i;
    wire[31:0] cp0_cause  = (w_cp0_we & w_cp0_addr==`CP0_Reg_cause) ? w_cp0_wdata:cp0_cause_i;

    assign  cp0_epc_o = cp0_epc;
    wire    delayslot_judge_o = delayslot_judge_i;

/***********************************************************Exception*******************************************************************/
    wire interrupt  =   ((cp0_cause[15:8] & (cp0_status[15:8])) != 8'h00) && 
                        (cp0_status[1] == 1'b0) && 
                        (cp0_status[0] == 1'b1);

    wire[3:0] except_info_o =   {4{interrupt}}          & 4'h1 |
                                {4{except_info_i[0]}}   & 4'ha |       //inst_invalid
                                {4{except_info_i[1]}}   & 4'he |       //eret
                                {4{except_info_i[2]}}   & 4'h8 |       //syscall
                                {4{except_info_i[3]}}   & 4'h9 |       //break
                                {4{except_info_i[4]}}   & 4'hc |       //over
                                {4{except_info_i[5]}}   & 4'h4 |       //AdeL
                                {4{except_info_i[6]}}   & 4'h5 ;       //AdeS

    assign m_except = | except_info_o ;
/***************************************************************Output******************************************************************/
    assign m_cp0_imm = {
        Badaddr,
        delayslot_judge_o,
        m_pc,
        except_info_o
    };

    assign M_W_bus = {
        hilo_bus,   // 135:70
        m_pc,       // 69:38
        rf_we,      // 37
        rf_waddr,   // 36:32
        rf_wdata    // 31:0
    };

    assign M_RF_bus = {
        hilo_bus,
        rf_we,
        rf_waddr,
        rf_wdata
    };

endmodule