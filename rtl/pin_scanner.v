// pin_scanner.v -- lights up one candidate GPIO pin at a time (~1.2s each)
// so we can visually identify which physical pin drives which external LED.
// Watch the breadboard LEDs: whichever one lights up tells us the pin name
// from the SCAN_ORDER list below.

module pin_scanner (
    input  wire clk,        // 25 MHz onboard oscillator (pin P6)
    output wire scan0,      // candidate pin: T6
    output wire scan1,      // candidate pin: P7
    output wire scan2,      // candidate pin: R5
    output wire scan3,      // candidate pin: R6
    output wire scan4,      // candidate pin: R4
    output wire scan5,      // candidate pin: T4
    output wire scan6,      // candidate pin: R3
    output wire scan7,      // candidate pin: T3
    output wire scan8,      // candidate pin: F5
    output wire scan9,      // candidate pin: H5
    output wire scan10,     // candidate pin: N4
    output wire scan11      // candidate pin: J5
);

    // ~1.2 second per step at 25 MHz (2^24.5 cycles roughly)
    reg [24:0] clk_div = 25'd0;
    always @(posedge clk) clk_div <= clk_div + 1'b1;
    wire tick = (clk_div == 25'd0);

    reg [3:0] pos = 4'd0;
    always @(posedge clk) begin
        if (tick) begin
            if (pos == 4'd11) pos <= 4'd0;
            else pos <= pos + 1'b1;
        end
    end

    assign scan0  = (pos == 4'd0);
    assign scan1  = (pos == 4'd1);
    assign scan2  = (pos == 4'd2);
    assign scan3  = (pos == 4'd3);
    assign scan4  = (pos == 4'd4);
    assign scan5  = (pos == 4'd5);
    assign scan6  = (pos == 4'd6);
    assign scan7  = (pos == 4'd7);
    assign scan8  = (pos == 4'd8);
    assign scan9  = (pos == 4'd9);
    assign scan10 = (pos == 4'd10);
    assign scan11 = (pos == 4'd11);

endmodule
