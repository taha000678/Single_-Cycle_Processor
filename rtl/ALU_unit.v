`timescale 1ns/1ps

// ============================================================
//  ALU_unit.v  —  BUG #1 FIXED

module ALU_unit (
    input  [31:0] A,
    input  [31:0] B,
    input  [3:0]  ALU_Sel,
    output reg [31:0] Result,
    output Zero
);
    wire [4:0] shamt = B[4:0];

    always @(*) begin
        case (ALU_Sel)
            4'b0000: Result = A + B;                                    // ADD / ADDI
            4'b0001: Result = A - B;                                    // SUB
            4'b0010: Result = A ^ B;                                    // XOR / XORI
            4'b0011: Result = A | B;                                    // OR  / ORI
            4'b0100: Result = A & B;                                    // AND / ANDI
            4'b0101: Result = A << shamt;                               // SLL / SLLI
            4'b0110: Result = A >> shamt;                               // SRL / SRLI
            4'b0111: Result = $signed(A) >>> shamt;                     // SRA / SRAI
            4'b1000: Result = ($signed(A) < $signed(B))  ? 32'd1 : 32'd0; // SLT
            4'b1001: Result = (A < B)                    ? 32'd1 : 32'd0; // SLTU
            4'b1010: Result = (A == B)                   ? 32'd1 : 32'd0; // BEQ
            4'b1011: Result = (A != B)                   ? 32'd1 : 32'd0; // BNE
            4'b1100: Result = ($signed(A) < $signed(B))  ? 32'd1 : 32'd0; // BLT
            4'b1101: Result = ($signed(A) >= $signed(B)) ? 32'd1 : 32'd0; // BGE
            4'b1110: Result = (A < B)                    ? 32'd1 : 32'd0; // BLTU
            4'b1111: Result = (A >= B)                   ? 32'd1 : 32'd0; // BGEU
            default: Result = 32'd0;
        endcase
    end

    // ---------------------------------------------------------------
    // FIXED: was (Result != 32'd0) ? 1 : 0  — that was INVERTED.
    // ---------------------------------------------------------------
    assign Zero = Result[0];

endmodule
