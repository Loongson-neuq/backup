`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
/*by srmk*/
//////////////////////////////////////////////////////////////////////////////////

`define     EMPTY           2'b00
`define     WAIT            2'b01 
`define     TRAN            2'b11

module sram_like(
    input                   clk,
    input                   resetn,

    //to slave
    output                  req,
    output                  wr,
    output[31:0]            addr,
    output[1:0]             size,
    output[31:0]            wdata,

    //to master
    input                   addr_ok,
    input                   data_ok,
    input[31:0]             rdata,

    //cpu
    input                   flush,
    input                   r_en_cpu,
    input                   w_en_cpu,
    input[31:0]             w_data_cpu,
    output[31:0]            r_data_cpu,
    input[3:0]              sel_cpu,
    input[31:0]             addr_cpu,
   
    output                  trans_valid
);

    //------------------------------------------------------
    
    reg[1:0]                    state;

    reg                         req_reg;
    reg                         wr_reg;
    reg[1:0]                    size_reg;
    reg[31:0]                   addr_reg;
                   

    reg[31:0]                   r_data_reg;
    reg[31:0]                   w_data_reg;


    assign trans_valid      =       (state == `TRAN) & data_ok;

    assign req              =       (state == `WAIT) & req_reg;
    assign wr               =       (state == `WAIT) & wr_reg ;
    assign size             =       size_reg;
    assign addr             =       addr_reg;


    assign r_data_cpu       =       r_data_reg;
    assign wdata            =       w_data_reg; 

    wire[1:0] size_2        =       (sel_cpu == 4'b0001||sel_cpu == 4'b0010||sel_cpu == 4'b0100||sel_cpu == 4'b1000) ? 2'b00 : 
                                    (sel_cpu == 4'b0011||sel_cpu == 4'b1100)                                         ? 2'b01 : 
                                    (sel_cpu == 4'b1111|| sel_cpu == 4'b0111||sel_cpu == 4'b1110)                    ? 2'b10 : 2'b00;

    wire[1:0] addr_2        =       (sel_cpu[0]) ? 2'b00 : 
                                    (sel_cpu[1]) ? 2'b01 : 
                                    (sel_cpu[2]) ? 2'b10 : 
                                    (sel_cpu[3]) ? 2'b11 : 2'b00;


    always @(posedge clk) begin
        if(resetn == 1'b0) begin
            req_reg     <=      1'b0;
            wr_reg      <=      1'b0;
            size_reg    <=      2'b0;
            addr_reg    <=      32'b0;
            r_data_reg  <=      32'b0;
            w_data_reg  <=      32'b0;
        end else begin
            case (state)
                `EMPTY:     begin
                    req_reg     <=      r_en_cpu||w_en_cpu;
                    wr_reg      <=      w_en_cpu;
                    size_reg    <=      size_2;
                    addr_reg    <=      {addr_cpu[31:2],addr_2};
                    r_data_reg  <=      32'b0;
                    w_data_reg  <=      w_data_cpu;
                end
                `WAIT:      begin
                    req_reg     <=      req_reg;
                    wr_reg      <=      wr_reg;
                    size_reg    <=      size_reg;
                    addr_reg    <=      addr_reg;
                    r_data_reg  <=      r_data_reg;
                    w_data_reg  <=      w_data_reg;
                end
                `TRAN:      begin 
                    req_reg     <=      1'b0;
                    wr_reg      <=      1'b0;
                    size_reg    <=      2'b0;
                    addr_reg    <=      32'b0;
                    r_data_reg  <=      rdata;
                    w_data_reg  <=      32'b0; 
                end
                default : /* default */;
            endcase     
        end
    end   


    reg[1:0]                   next_state;

    always@(*)begin
    if(resetn==1'b0 | flush)
        next_state <= `EMPTY;
    else begin
        case(state)
        `EMPTY: 
            next_state <= (w_en_cpu||r_en_cpu) ? `WAIT  : `EMPTY;
        `WAIT:
            next_state <= (addr_ok)            ? `TRAN  : `WAIT;
        `TRAN:
            next_state <= (data_ok)            ? `EMPTY : `TRAN;
        endcase
    end
    end

    always @(posedge clk) begin
        if(resetn == 1'b0) begin
            state       <=      `EMPTY;
        end else begin
            state       <=      next_state;
        end
    end

endmodule

 // assign  next_state  =       (state == `EMPTY)?((w_en_cpu||r_en_cpu)?`WAIT: 
    //                                                      `EMPTY): 
    //                             (state == `WAIT)?((addr_ok)?`TRAN: 
    //                                                         `WAIT): 
    //                             (state == `TRAN)?((data_ok)?`EMPTY: 
    //                                                         `TRAN): 
    //                             `EMPTY;

