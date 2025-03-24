`include "Defines.vh"
module regfile(
    input            clk,
    input            we,
    input[4:0]       waddr,
    input[31:0]      wdata,
    input[4:0]       raddr1,
    input[4:0]       raddr2,

    output[31:0]     rdata1,
    output[31:0]     rdata2
);
    reg [31:0] reg_array [31:0];
    
    always @ (posedge clk) begin    // write
        if (we && waddr!=5'b0) begin
            reg_array[waddr] <= wdata;
        end
    end

// read out 1
    assign rdata1 = (raddr1 == 5'b0) ? 32'b0 : reg_array[raddr1];

// read out2
    assign rdata2 = (raddr2 == 5'b0) ? 32'b0 : reg_array[raddr2];

endmodule