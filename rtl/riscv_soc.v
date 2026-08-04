// riscv_soc.v
// Top-level: wires riscv_core (Wishbone master) to the address decoder,
// the three memory-mapped slaves (program mem, data mem, LED), and the
// read-data mux.
//
// ============================================================
// WISHBONE B3 SPEC COMPLIANCE (see Figure 1-2, "Standard connection
// for timing diagrams", WISHBONE SoC Architecture Spec Rev B.3)
//
// The crossed master<->slave connection required by the spec is exactly
// what this module wires up. Signal name equivalence:
//
//   Spec name         This design         Direction (Master -> Slave)
//   ---------         -----------         ----------------------------
//   CLK_I             clk                 shared clock, both sides
//   RST_I             reset               shared reset, both sides
//   ADR_O -> ADR_I    wb_adr              master drives, slave reads
//   DAT_O -> DAT_I    wb_dat_mosi         master drives (writes), slave reads
//   DAT_I <- DAT_O    wb_dat_miso         slave drives (reads), master reads
//   WE_O  -> WE_I     wb_we               1=write, 0=read
//   SEL_O -> SEL_I    wb_sel              byte-lane select (for SB/SH/SW)
//   STB_O -> STB_I    wb_stb              strobe: "this exact cycle is a request"
//   CYC_O -> CYC_I    wb_cyc              cycle: "a bus transaction is in progress"
//   ACK_O -> ACK_I    wb_ack              slave's "done" response
//
//   TAGN_O / TAGN_I   (not implemented)   optional address-tag signals for
//                                         user-defined metadata (e.g. cache
//                                         hints). Not required for a
//                                         compliant WISHBONE interface --
//                                         this design omits them, matching
//                                         the spec's "USER DEFINED" box
//                                         being optional.
// ============================================================

module riscv_soc (
    input  wire clk,      // == CLK_I
    input  wire reset,    // == RST_I

    input  wire [31:0] gpio_in,     // external input pins (buttons/switches/sensors)
    output wire [31:0] gpio_out     // external output pins (LEDs/motors/anything digital)
);

    // ---- CPU <-> shared Wishbone bus ----
    // wb_cyc == CYC_O/CYC_I, wb_stb == STB_O/STB_I, wb_we == WE_O/WE_I,
    // wb_adr == ADR_O/ADR_I, wb_ack == ACK_O/ACK_I
    wire        wb_cyc, wb_stb, wb_we, wb_ack;
    wire [31:0] wb_adr, wb_dat_mosi, wb_dat_miso;   // dat_mosi==DAT_O(master), dat_miso==DAT_I(master)
    wire [3:0]  wb_sel;                              // == SEL_O/SEL_I

    riscv_core CPU (
        .clk(clk),
        .reset(reset),
        .wb_cyc_o(wb_cyc),
        .wb_stb_o(wb_stb),
        .wb_we_o(wb_we),
        .wb_adr_o(wb_adr),
        .wb_dat_o(wb_dat_mosi),
        .wb_sel_o(wb_sel),
        .wb_dat_i(wb_dat_miso),
        .wb_ack_i(wb_ack)
    );

    // ---- Address decode ----
    // Splits the single shared CYC_O/STB_O into per-slave, address-qualified
    // CYC_I/STB_I lines -- this is the "crossbar" piece the spec figure
    // doesn't show (the figure is 1 master : 1 slave; we have 1 master : 3
    // slaves, so a decoder + read mux implement the fan-out/fan-in).
    wire prog_cyc, prog_stb, data_cyc, data_stb, gpio_cyc, gpio_stb, addr_valid;

    wb_addr_decoder DECODER (
        .wb_cyc_i(wb_cyc),
        .wb_stb_i(wb_stb),
        .wb_adr_i(wb_adr),
        .prog_cyc_o(prog_cyc),
        .prog_stb_o(prog_stb),
        .data_cyc_o(data_cyc),
        .data_stb_o(data_stb),
        .led_cyc_o(gpio_cyc),
        .led_stb_o(gpio_stb),
        .addr_valid_o(addr_valid)
    );

    // ---- Slaves ----
    wire [31:0] prog_dat, data_dat, gpio_dat;
    wire        prog_ack, data_ack, gpio_ack;

    wb_prog_mem_slave PROG_MEM (
        .clk(clk), .reset(reset),
        .wb_cyc_i(prog_cyc), .wb_stb_i(prog_stb), .wb_we_i(wb_we),
        .wb_adr_i(wb_adr), .wb_dat_i(wb_dat_mosi), .wb_sel_i(wb_sel),
        .wb_dat_o(prog_dat), .wb_ack_o(prog_ack)
    );

    wb_data_mem_slave DATA_MEM (
        .clk(clk), .reset(reset),
        .wb_cyc_i(data_cyc), .wb_stb_i(data_stb), .wb_we_i(wb_we),
        .wb_adr_i(wb_adr), .wb_dat_i(wb_dat_mosi), .wb_sel_i(wb_sel),
        .wb_dat_o(data_dat), .wb_ack_o(data_ack)
    );

    wb_gpio_slave GPIO (
        .clk(clk), .reset(reset),
        .wb_cyc_i(gpio_cyc), .wb_stb_i(gpio_stb), .wb_we_i(wb_we),
        .wb_adr_i(wb_adr), .wb_dat_i(wb_dat_mosi), .wb_sel_i(wb_sel),
        .wb_dat_o(gpio_dat), .wb_ack_o(gpio_ack),
        .gpio_out(gpio_out),
        .gpio_in(gpio_in)
    );

    // ---- Read-data mux back to the CPU ----
    // Combines the three slaves' DAT_O/ACK_O back into the single
    // DAT_I/ACK_I the master expects (only one slave is ever selected
    // at a time, so a simple OR is correct here).
    wb_read_mux READ_MUX (
        .prog_dat_i(prog_dat), .prog_ack_i(prog_ack),
        .data_dat_i(data_dat), .data_ack_i(data_ack),
        .led_dat_i(gpio_dat),   .led_ack_i(gpio_ack),
        .wb_dat_o(wb_dat_miso),
        .wb_ack_o(wb_ack)
    );

endmodule