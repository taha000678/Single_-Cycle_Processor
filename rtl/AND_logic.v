`timescale 1ns/1ps

module AND_logic (input branch, input zero, output and_out);
    assign and_out = branch & zero;
endmodule
