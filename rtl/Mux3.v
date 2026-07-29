`timescale 1ns/1ps

module Mux3 (input sel3, input [31:0] A3, B3, output [31:0] Mux3_out);
    assign Mux3_out = sel3 ? B3 : A3;
endmodule
