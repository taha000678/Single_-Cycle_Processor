`timescale 1ns/1ps

// ============================================================
//  Control_Unit.v  
module Control_Unit (
    input  [6:0] instruction,

    output reg       ALUSrc,
    output reg       MemtoReg,
    output reg       RegWrite,
    output reg       MemRead,
    output reg       MemWrite,
    output reg       Branch,
    output reg       Jump,
    output reg [1:0] ALUop
);
    // Signal packing order (MSB→LSB):
    //  {ALUSrc, MemtoReg, RegWrite, MemRead, MemWrite, Branch, Jump, ALUop[1:0]}
    //   bit8     bit7      bit6      bit5     bit4      bit3   bit2   bit1 bit0

    always @(*) begin
        case (instruction)
            // R-Type  (ALUop=10 → ALU_Control uses funct7+funct3)
            7'b0110011: {ALUSrc,MemtoReg,RegWrite,MemRead,MemWrite,Branch,Jump,ALUop} = 9'b001000010;

            // I-ALU  addi/xori/ori/andi/slli/srli/srai/slti/sltiu
            //         (ALUop=00 → ALU_Control uses funct3 only)
            7'b0010011: {ALUSrc,MemtoReg,RegWrite,MemRead,MemWrite,Branch,Jump,ALUop} = 9'b101000000;

            // I-LOAD  lw  (ALUop=11 default → ADD for address)
            7'b0000011: {ALUSrc,MemtoReg,RegWrite,MemRead,MemWrite,Branch,Jump,ALUop} = 9'b111100011;

            // S-Type  sw  (ALUop=11 default → ADD for address)
            7'b0100011: {ALUSrc,MemtoReg,RegWrite,MemRead,MemWrite,Branch,Jump,ALUop} = 9'b100010011;

            // B-Type  beq/bne/blt/bge/bltu/bgeu
            //         (ALUop=01 → ALU_Control uses funct3 for branch op)
            7'b1100011: {ALUSrc,MemtoReg,RegWrite,MemRead,MemWrite,Branch,Jump,ALUop} = 9'b000001001;

            // JAL
            7'b1101111: {ALUSrc,MemtoReg,RegWrite,MemRead,MemWrite,Branch,Jump,ALUop} = 9'b001000100;

            // JALR
            7'b1100111: {ALUSrc,MemtoReg,RegWrite,MemRead,MemWrite,Branch,Jump,ALUop} = 9'b101000100;

            // LUI  — ALUop value doesn't matter (WB_after_lui mux bypasses ALU result)
            //         keeping 2'b11 (ADD default) is harmless
            7'b0110111: {ALUSrc,MemtoReg,RegWrite,MemRead,MemWrite,Branch,Jump,ALUop} = 9'b101000011;

            // AUIPC — FIXED: changed ALUop from 2'b11 to 2'b00
            //         riscv_core routes PC_out → ALU-A, immediate → ALU-B.
            //         ALUop=00 uses the I-ALU ADD path → Result = PC + imm_u ✓
            7'b0010111: {ALUSrc,MemtoReg,RegWrite,MemRead,MemWrite,Branch,Jump,ALUop} = 9'b101000000;
            //                                                                 ^^^^ was 011, now 000

            // Default / NOP
            default:    {ALUSrc,MemtoReg,RegWrite,MemRead,MemWrite,Branch,Jump,ALUop} = 9'b000000000;
        endcase
    end
endmodule
