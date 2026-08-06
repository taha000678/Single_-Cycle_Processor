// blinky.v -- simplest possible FPGA test: blink the onboard RGB LED.
// This has nothing to do with the RISC-V core yet -- it's purely to
// prove the toolchain (yosys -> nextpnr-ecp5 -> ecppack -> iCELink)
// works end to end before we put the real processor on the board.

module blinky (
    input  wire clk,     // 25 MHz onboard oscillator (pin P6)
    output wire led_r,   // onboard RGB LED (pin A11)
    output wire led_g,   // onboard RGB LED (pin A12)
    output wire led_b    // onboard RGB LED (pin B11)
);

    // 25,000,000 Hz clock. A 24-bit counter overflows roughly every
    // 2^24 / 25,000,000 ≈ 0.67 seconds -- a clearly visible blink.
    reg [23:0] counter = 24'd0;

    always @(posedge clk) begin
        counter <= counter + 1'b1;
    end

    // Drive all three colour channels with the same bit. If the LED is
    // active-low instead of active-high, it will just blink "inverted"
    // (on when you expect off) -- either way, you WILL see it blink.
    assign led_r = counter[23];
    assign led_g = 0;//counter[23];
    assign led_b = counter[23];

endmodule