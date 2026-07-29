`timescale 1ns/1ps

module Mux1 (input sel1, input [31:0] A1, B1, output [31:0] Mux1_out);
    assign Mux1_out = sel1 ? B1 : A1;
endmodule
