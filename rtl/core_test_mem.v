`timescale 1ns/1ps

module core_test_mem (
    input         clk,
    input         reset,

    input         wb_cyc_i,
    input         wb_stb_i,
    input         wb_we_i,
    input  [31:0] wb_adr_i,
    input  [31:0] wb_dat_i,
    input  [3:0]  wb_sel_i,

    output [31:0] wb_dat_o,
    output        wb_ack_o
);
    // 2048 words x 32-bit = 8 KB, covers 0x0000-0x1FFF
    reg [31:0] mem [0:2047];
    integer k;

    wire [10:0] word_addr = wb_adr_i[12:2];

    initial begin
        for (k = 0; k < 2048; k = k + 1)
            mem[k] = 32'h0000_0013; // pre-fill with NOP so unused fetches are harmless
        $readmemh("test_full.hex", mem, 0, 1023); // loads program words into addr 0x0000-0x0FFF only
    end

    assign wb_dat_o = (wb_cyc_i && wb_stb_i && !wb_we_i) ? mem[word_addr] : 32'b0;
    assign wb_ack_o = wb_cyc_i && wb_stb_i;

    always @(posedge clk) begin
        if (wb_cyc_i && wb_stb_i && wb_we_i) begin
            if (wb_sel_i[0]) mem[word_addr][7:0]   <= wb_dat_i[7:0];
            if (wb_sel_i[1]) mem[word_addr][15:8]  <= wb_dat_i[15:8];
            if (wb_sel_i[2]) mem[word_addr][23:16] <= wb_dat_i[23:16];
            if (wb_sel_i[3]) mem[word_addr][31:24] <= wb_dat_i[31:24];
        end
    end
endmodule
