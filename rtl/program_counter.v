`timescale 1ns/1ps

module program_counter (
    input         clk,
    input         reset,
    input  [31:0] PC_in,
    output reg [31:0] PC_out
);
    always @(posedge clk or posedge reset) begin
        if (reset)
            PC_out <= 32'h0000_0000;
        else
            PC_out <= PC_in;
    end
endmodule
