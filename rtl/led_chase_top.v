// led_chase_top.v -- drives 4 external LEDs (via P3 header, bottom row)
// with a forward-then-backward chase pattern.

module led_chase_top (
    input  wire clk,   // 25 MHz onboard oscillator (pin P6)
    output wire led0,  // P3 pin T6
    output wire led1,  // P3 pin R5
    output wire led2,  // P3 pin R4
    output wire led3   // P3 pin R3
);

    reg [21:0] clk_div = 22'd0;
    always @(posedge clk) clk_div <= clk_div + 1'b1;
    wire tick = (clk_div == 22'd0);

    reg [1:0] pos       = 2'd0;
    reg       direction = 1'b0;   // 0 = forward, 1 = backward

    always @(posedge clk) begin
        if (tick) begin
            if (direction == 1'b0) begin
                if (pos == 2'd3) begin
                    direction <= 1'b1;
                    pos       <= 2'd2;
                end else begin
                    pos <= pos + 1'b1;
                end
            end else begin
                if (pos == 2'd0) begin
                    direction <= 1'b0;
                    pos       <= 2'd1;
                end else begin
                    pos <= pos - 1'b1;
                end
            end
        end
    end

    assign led0 = (pos == 2'd0);
    assign led1 = (pos == 2'd1);
    assign led2 = (pos == 2'd2);
    assign led3 = (pos == 2'd3);

endmodule
