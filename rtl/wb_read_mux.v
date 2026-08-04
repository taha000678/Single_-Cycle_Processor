// wb_read_mux.v
// Since only one slave is ever selected at a time (per wb_addr_decoder),
// this simply OR's the (already-gated) slave outputs together to drive
// the shared read-data bus back to the CPU. Also OR's the ack lines.

module wb_read_mux (
    input  wire [31:0] prog_dat_i,
    input  wire        prog_ack_i,

    input  wire [31:0] data_dat_i,
    input  wire        data_ack_i,

    input  wire [31:0] led_dat_i,
    input  wire        led_ack_i,

    output wire [31:0] wb_dat_o,
    output wire        wb_ack_o
);

    assign wb_dat_o = prog_dat_i | data_dat_i | led_dat_i;
    assign wb_ack_o = prog_ack_i | data_ack_i | led_ack_i;

endmodule