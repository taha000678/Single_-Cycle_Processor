`timescale 1ns/1ps

// ============================================================
//  ALU_Control.v  —  BUG #3

module ALU_Control (
    input  [1:0] ALUOp,
    input  [6:0] funct7,
    input  [2:0] funct3,
    output reg [3:0] ALU_Control
);
    always @(*) begin
        case (ALUOp)

            // --------------------------------------------------
            // R-Type: use both funct7 and funct3
            // --------------------------------------------------
            2'b10: begin
                case ({funct7, funct3})
                    10'b0000000_000: ALU_Control = 4'b0000; // ADD
                    10'b0100000_000: ALU_Control = 4'b0001; // SUB
                    10'b0000000_100: ALU_Control = 4'b0010; // XOR
                    10'b0000000_110: ALU_Control = 4'b0011; // OR
                    10'b0000000_111: ALU_Control = 4'b0100; // AND
                    10'b0000000_001: ALU_Control = 4'b0101; // SLL
                    10'b0000000_101: ALU_Control = 4'b0110; // SRL
                    10'b0100000_101: ALU_Control = 4'b0111; // SRA
                    10'b0000000_010: ALU_Control = 4'b1000; // SLT
                    10'b0000000_011: ALU_Control = 4'b1001; // SLTU
                    default:         ALU_Control = 4'b0000;
                endcase
            end

            // --------------------------------------------------
            // I-ALU: addi xori ori andi slli srli SRAI slti sltiu
            // FIXED: funct3=101 now checks funct7[5] to separate
            //        SRLI (logical) from SRAI (arithmetic).
            // --------------------------------------------------
            2'b00: begin
                case (funct3)
                    3'b000: ALU_Control = 4'b0000; // ADDI
                    3'b100: ALU_Control = 4'b0010; // XORI
                    3'b110: ALU_Control = 4'b0011; // ORI
                    3'b111: ALU_Control = 4'b0100; // ANDI
                    3'b001: ALU_Control = 4'b0101; // SLLI
                    // FIXED ↓  was: 4'b0110 always (SRLI only)
                    3'b101: ALU_Control = funct7[5] ? 4'b0111 : 4'b0110; // SRAI : SRLI
                    3'b010: ALU_Control = 4'b1000; // SLTI
                    3'b011: ALU_Control = 4'b1001; // SLTIU
                    default: ALU_Control = 4'b0000;
                endcase
            end

            // --------------------------------------------------
            // B-Type: use funct3 to select branch comparison
            // --------------------------------------------------
            2'b01: begin
                case (funct3)
                    3'b000: ALU_Control = 4'b1010; // BEQ
                    3'b001: ALU_Control = 4'b1011; // BNE
                    3'b100: ALU_Control = 4'b1100; // BLT
                    3'b101: ALU_Control = 4'b1101; // BGE
                    3'b110: ALU_Control = 4'b1110; // BLTU
                    3'b111: ALU_Control = 4'b1111; // BGEU
                    default: ALU_Control = 4'b0000;
                endcase
            end

            // S-Type / Load: default → ADD (address calculation)
            default: ALU_Control = 4'b0000;

        endcase
    end
endmodule
