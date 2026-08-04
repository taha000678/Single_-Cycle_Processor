// wb_addr_decoder.v
// Decodes the CPU's Wishbone address into per-slave chip-select (cyc/stb)
// signals, based on the memory map:
//   0x0000 - 0x0FFF : Program memory
//   0x1000 - 0x1FFF : Data memory
//   0x2000 - 0x2FFF : LED peripheral
//
// Only the selected slave sees cyc_i/stb_i asserted; the others stay idle.

module wb_addr_decoder (
    input  wire        wb_cyc_i,
    input  wire        wb_stb_i,
    input  wire [31:0] wb_adr_i,

    output wire         prog_cyc_o,
    output wire         prog_stb_o,
    output wire         data_cyc_o,
    output wire         data_stb_o,
    output wire         led_cyc_o,
    output wire         led_stb_o,

    output wire        addr_valid_o   // 1 if address matched a known region
);

    wire sel_prog = (wb_adr_i[31:12] == 20'h00000);  // 0x0000-0x0FFF
    wire sel_data = (wb_adr_i[31:12] == 20'h00001);  // 0x1000-0x1FFF
    wire sel_led  = (wb_adr_i[31:12] == 20'h00002);  // 0x2000-0x2FFF

    assign prog_cyc_o = wb_cyc_i & sel_prog;
    assign prog_stb_o = wb_stb_i & sel_prog;

    assign data_cyc_o = wb_cyc_i & sel_data;
    assign data_stb_o = wb_stb_i & sel_data;

    assign led_cyc_o  = wb_cyc_i & sel_led;
    assign led_stb_o  = wb_stb_i & sel_led;

    assign addr_valid_o = sel_prog | sel_data | sel_led;

endmodule