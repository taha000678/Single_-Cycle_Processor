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

            // LUI  — ALUop=11 (always-ADD). WB_after_lui mux bypasses the ALU
            //        result anyway, so this is mostly a don't-care, but keeping
            //        it on the always-ADD path is the safe/consistent choice.
            7'b0110111: {ALUSrc,MemtoReg,RegWrite,MemRead,MemWrite,Branch,Jump,ALUop} = 9'b101000011;

            // AUIPC — must use ALUop=11 (always-ADD), same as LUI/loads/stores.
            //         AUIPC's bits[14:12] are part of its immediate, NOT a real
            //         funct3 -- so any ALUop that decodes based on funct3
            //         (like 00) can select the wrong ALU operation depending
            //         on what garbage bits happen to sit there. Only the
            //         always-ADD encoding is safe here.
            7'b0010111: {ALUSrc,MemtoReg,RegWrite,MemRead,MemWrite,Branch,Jump,ALUop} = 9'b101000011;

            // Default / NOP
            default:    {ALUSrc,MemtoReg,RegWrite,MemRead,MemWrite,Branch,Jump,ALUop} = 9'b000000000;
        endcase
    end
endmodule