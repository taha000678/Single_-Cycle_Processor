// wb_data_mem_slave.v
// Data memory: 1024 words (4KB), address range 0x1000-0x1FFF.
// Zero-wait-state: ack is combinational.
// Supports byte-lane writes via wb_sel_i (for SB/SH/SW).

module wb_data_mem_slave (
    input  wire        clk,
    input  wire        reset,

    input  wire        wb_cyc_i,
    input  wire        wb_stb_i,
    input  wire        wb_we_i,
    input  wire [31:0] wb_adr_i,
    input  wire [31:0] wb_dat_i,
    input  wire [3:0]  wb_sel_i,

    output wire [31:0] wb_dat_o,
    output wire        wb_ack_o
);

    reg [31:0] mem [0:1023];
    wire [9:0] word_addr = wb_adr_i[11:2];

    integer k;
    initial begin
        for (k = 0; k < 1024; k = k + 1)
            mem[k] = 32'h00000000;
    end

    wire selected = wb_cyc_i & wb_stb_i;

    assign wb_ack_o = selected;
    assign wb_dat_o = selected ? mem[word_addr] : 32'b0;

    always @(posedge clk) begin
        if (selected && wb_we_i) begin
            if (wb_sel_i[0]) mem[word_addr][7:0]   <= wb_dat_i[7:0];
            if (wb_sel_i[1]) mem[word_addr][15:8]  <= wb_dat_i[15:8];
            if (wb_sel_i[2]) mem[word_addr][23:16] <= wb_dat_i[23:16];
            if (wb_sel_i[3]) mem[word_addr][31:24] <= wb_dat_i[31:24];
        end
    end

endmodule