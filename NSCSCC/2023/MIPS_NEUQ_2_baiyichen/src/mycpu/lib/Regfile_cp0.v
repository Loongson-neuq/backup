`include "Defines.vh"
module CP0_reg
(
    input                   clk,
    input                   rst,

    input[36+32:0]          m_cp0_bus,
    input[37:0]             w_cp0_bus,

//(from Execute module)
    input[4:0]              r_addr_i,   //The number of the register in the cp0 to be read(the need for mfc0 instruction)
   
//(from Top)
    input[5:0]              interr_i,   //6 external hardware interrupt inputs


//(forward Execute module)

    output[31:0]            data_o,       //读出的cp0中某个寄存器的数值

//(forward Memory module)
    output[95:0]            cp0_bus    

);
    reg[31:0] Badaddr_o, count_o, epc_o, status_o, cause_o, compare_o;  
    assign   cp0_bus = {status_o, cause_o, epc_o};
    reg[31:0] pc_reg;
/*****************************************************************************************************/
    wire        w_en;
    wire[4:0]   w_addr_i;
    wire[31:0]  data_i;

    wire[31:0]  pc_i;
    wire        delayslot_flag;
    wire[3:0]   except_info_i;
    wire[31:0]  Badaddr_i;

    assign {Badaddr_i,delayslot_flag, pc_i, except_info_i} = m_cp0_bus;

    assign {w_en, w_addr_i, data_i}              = w_cp0_bus;

/*******************************************************************************************************/
    wire ene = (except_info_i!=4'b0 & except_info_i!=4'he);

//Badaddr_o//
    wire[31:0] Badaddr_temp = (except_info_i==4'h4|except_info_i==4'h5) ? Badaddr_i : Badaddr_o;

//status_o//
    wire EXL = (except_info_i==4'he) ? 1'b0 :
               ene                   ? 1'b1 : status_o[1];

//epc_o//
    wire[31:0]  right_epc = delayslot_flag ?  pc_i-4     : pc_i;

    wire[31:0]  epc_temp  = (ene & !status_o[1])                    ? (except_info_i==4'b1 ? pc_reg+4 : right_epc)  :
                            (w_en & w_addr_i==`CP0_Reg_epc)         ? data_i      : epc_o;

//cause_o//
    wire       BD      =  (ene & !status_o[1])  ? (delayslot_flag ? 1'b1 : 1'b0) : cause_o[31];

    wire[4:0]  ExeCode =    {5{except_info_i==4'h1}}      & 5'b00000 |
                            {5{except_info_i==4'h4}}      & 5'b00100 |
                            {5{except_info_i==4'h5}}      & 5'b00101 |  
                            {5{except_info_i==4'h8}}      & 5'b01000 |       
                            {5{except_info_i==4'h9}}      & 5'b01001 |  
                            {5{except_info_i==4'ha}}      & 5'b01010 |
                            {5{except_info_i==4'hc}}      & 5'b01100 |
                            {5{except_info_i==4'h0}}      & cause_o[6:2];

/*******************************************************************************************************/

    reg    count_state;
    always @(posedge clk) begin
		if(rst) 	
            count_state 		<= 1'b0;
		else 		
            count_state         <= ~count_state;
	end

    always@(posedge clk)begin
        if(rst)begin
            Badaddr_o       <= 32'b0;
            epc_o           <= 32'b0;
            status_o        <= 32'h00400000;
            cause_o         <= 32'b0;
            count_o         <= 32'b0;
            compare_o       <= 32'b0;
            pc_reg          <= 32'b0;
        end
        else begin
            pc_reg          <= pc_i;
            cause_o[14:10] <= interr_i[4:0];
            if((|compare_o)&&count_o == compare_o)begin
                cause_o[15] <= 1'b1;
            end else begin
                cause_o[15] <= interr_i[5];
            end
            if(count_state) 
                count_o <= count_o + 32'b1;

            if(w_en) begin
				case (w_addr_i) 

                    `CP0_Reg_count:  begin
                        count_o             <= data_i;
                    end

                    `CP0_Reg_compare: begin
                        compare_o           <= data_i;
                    end
			
					`CP0_Reg_status: begin
						status_o[15:8] 	    <= data_i[15:8];
						status_o[0] 	    <= data_i[0];
					end

					`CP0_Reg_cause:	 begin
						cause_o[9:8]        <= data_i[9:8];
					end
					
					default : begin
					end	
				endcase  
			end

            Badaddr_o        <= Badaddr_temp;                    
           
            epc_o            <= epc_temp;

            cause_o[31]      <= BD;
            cause_o[6:2]     <= ExeCode;

            status_o[1]      <= EXL;
        end
    end

     assign     data_o = {32{r_addr_i==`CP0_Reg_epc}}        &  epc_o     |
                         {32{(r_addr_i==`CP0_Reg_cause)}}    &  cause_o   |
                         {32{r_addr_i==`CP0_Reg_status}}     &  status_o  | 
                         {32{r_addr_i==`CP0_Reg_badaddr}}    &  Badaddr_o |
                         {32{r_addr_i==`CP0_Reg_compare}}    &  compare_o |
                         {32{r_addr_i==`CP0_Reg_count}}      &  count_o   ; 

endmodule