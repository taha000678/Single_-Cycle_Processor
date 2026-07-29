`timescale 1ns/1ps

module Register_File (
    input         clk,
    input         reset,
    input         Reg_write,
    input  [4:0]  rs1,
    input  [4:0]  rs2,
    input  [4:0]  rd,
    input  [31:0] write_data,
    output reg [31:0] Read_Data1,
    output reg [31:0] Read_Data2
);
    reg [31:0] reg_mem [0:31];
    integer i;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            for (i = 0; i < 32; i = i + 1)
                reg_mem[i] <= 32'd0;
        end else begin
            if (Reg_write && (rd != 5'd0))
                reg_mem[rd] <= write_data;
            reg_mem[0] <= 32'd0; // x0 always zero
        end
    end

    always @(*) begin
        Read_Data1 = (rs1 == 5'd0) ? 32'd0 : reg_mem[rs1];
        Read_Data2 = (rs2 == 5'd0) ? 32'd0 : reg_mem[rs2];
    end
endmodule
