// wb_prog_mem_slave.v
// Program memory: 1024 words (4KB), address range 0x0000-0x0FFF.
// Zero-wait-state: ack is combinational (same cycle as stb).
// Loaded from a hex file at simulation start via $readmemh.

module wb_prog_mem_slave (
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

    initial begin
        $readmemh("test_full.hex", mem);   // <-- change this filename to load a different program
    end

    wire selected = wb_cyc_i & wb_stb_i;

    assign wb_ack_o = selected;
    assign wb_dat_o = selected ? mem[word_addr] : 32'b0;

    // Program memory is normally instruction-fetch-only, but writes are
    // supported here too (useful for self-modifying test setups / debug).
    always @(posedge clk) begin
        if (selected && wb_we_i) begin
            if (wb_sel_i[0]) mem[word_addr][7:0]   <= wb_dat_i[7:0];
            if (wb_sel_i[1]) mem[word_addr][15:8]  <= wb_dat_i[15:8];
            if (wb_sel_i[2]) mem[word_addr][23:16] <= wb_dat_i[23:16];
            if (wb_sel_i[3]) mem[word_addr][31:24] <= wb_dat_i[31:24];
        end
    end

endmodule