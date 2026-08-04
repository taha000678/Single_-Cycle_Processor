// wb_gpio_slave.v
// General-purpose I/O peripheral, 2 memory-mapped registers within the
// GPIO region (0x2000-0x2FFF):
//
//   0x2000 (bit2=0)  GPIO_OUT  -- read/write. Writing drives physical
//                                output pins. Reading returns the last
//                                value written (so software can check
//                                "what did I set this to").
//   0x2004 (bit2=1)  GPIO_IN   -- read-only. Returns the current state
//                                of the physical input pins (buttons,
//                                switches, sensors). Writes here are
//                                ignored.

module wb_gpio_slave (
    input  wire        clk,
    input  wire        reset,

    input  wire        wb_cyc_i,
    input  wire        wb_stb_i,
    input  wire        wb_we_i,
    input  wire [31:0] wb_adr_i,
    input  wire [31:0] wb_dat_i,
    input  wire [3:0]  wb_sel_i,

    output wire [31:0] wb_dat_o,
    output wire        wb_ack_o,

    output reg  [31:0] gpio_out,       // drives physical output pins
    input  wire [31:0] gpio_in         // physical input pins (buttons/switches/sensors)
);

    wire selected  = wb_cyc_i & wb_stb_i;
    wire sel_in_reg = wb_adr_i[2];      // 0 = GPIO_OUT (0x2000), 1 = GPIO_IN (0x2004)

    assign wb_ack_o = selected;
    assign wb_dat_o = selected ? (sel_in_reg ? gpio_in : gpio_out) : 32'b0;

    always @(posedge clk) begin
        if (reset) begin
            gpio_out <= 32'b0;
        end else if (selected && wb_we_i && !sel_in_reg) begin
            // Only the GPIO_OUT register (0x2000) is writable.
            // Writes to GPIO_IN (0x2004) are silently ignored -- it's
            // read-only, driven by the external world.
            if (wb_sel_i[0]) gpio_out[7:0]   <= wb_dat_i[7:0];
            if (wb_sel_i[1]) gpio_out[15:8]  <= wb_dat_i[15:8];
            if (wb_sel_i[2]) gpio_out[23:16] <= wb_dat_i[23:16];
            if (wb_sel_i[3]) gpio_out[31:24] <= wb_dat_i[31:24];
        end
    end

endmodule