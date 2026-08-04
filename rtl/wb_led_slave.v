// wb_led_slave.v
// A single memory-mapped register at address 0x2000.
// Writing to it sets the LED pattern; reading it returns the current value.

module wb_led_slave (
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

    output reg  [31:0] led_reg   // exposed for the FPGA top module / simulation checks
);

    wire selected = wb_cyc_i & wb_stb_i;

    assign wb_ack_o = selected;
    assign wb_dat_o = selected ? led_reg : 32'b0;

    always @(posedge clk) begin
        if (reset) begin
            led_reg <= 32'b0;
        end else if (selected && wb_we_i) begin
            if (wb_sel_i[0]) led_reg[7:0]   <= wb_dat_i[7:0];
            if (wb_sel_i[1]) led_reg[15:8]  <= wb_dat_i[15:8];
            if (wb_sel_i[2]) led_reg[23:16] <= wb_dat_i[23:16];
            if (wb_sel_i[3]) led_reg[31:24] <= wb_dat_i[31:24];
        end
    end

endmodule