`include "Defines.vh"
module hilo_reg(
    input           clk,
    input           rst,

    input           hi_we,
    input[31:0]     hi_i,
    input           lo_we,
    input[31:0]     lo_i,


    output[31:0]    hi_o,
    output[31:0]    lo_o
);

    reg [31:0] hi_reg, lo_reg;

    always @ (posedge clk) begin    // write 
        if (rst) begin
            hi_reg <= 32'b0;
            lo_reg <= 32'b0;
        end else if (hi_we & lo_we) begin
            hi_reg <= hi_i;
            lo_reg <= lo_i;
        end else if (hi_we & ~lo_we) begin
            hi_reg <= hi_i;
        end else if (~hi_we & lo_we) begin
            lo_reg <= lo_i;
        end
    end

    assign hi_o = hi_reg;
    assign lo_o = lo_reg;

endmodule