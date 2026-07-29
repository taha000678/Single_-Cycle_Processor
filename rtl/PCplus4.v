`timescale 1ns/1ps

module PCplus4 (
    input  [31:0] fromPC,
    output [31:0] NextoPC
);
    assign NextoPC = fromPC + 32'd4;
endmodule
