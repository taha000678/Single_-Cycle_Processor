`timescale 1ns/1ps

module immediate_generator (
    input  [31:0] instruction,
    input  [2:0]  imm_sel,
    output reg [31:0] immediate
);
    wire [31:0] imm_i = {{20{instruction[31]}}, instruction[31:20]};
    wire [31:0] imm_s = {{20{instruction[31]}}, instruction[31:25], instruction[11:7]};
    wire [31:0] imm_b = {{19{instruction[31]}}, instruction[31], instruction[7],
                          instruction[30:25], instruction[11:8], 1'b0};
    wire [31:0] imm_u = {instruction[31:12], 12'b0};
    wire [31:0] imm_j = {{11{instruction[31]}}, instruction[31], instruction[19:12],
                          instruction[20], instruction[30:21], 1'b0};

    always @(*) begin
        case (imm_sel)
            3'b000: immediate = imm_i;
            3'b001: immediate = imm_s;
            3'b010: immediate = imm_b;
            3'b011: immediate = imm_u;
            3'b100: immediate = imm_j;
            default: immediate = 32'd0;
        endcase
    end
endmodule
