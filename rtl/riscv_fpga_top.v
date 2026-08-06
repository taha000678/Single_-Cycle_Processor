// riscv_fpga_top.v -- FPGA top-level wrapper for the RISC-V SoC.
// Connects riscv_soc (clk, reset, gpio_in, gpio_out) to real board pins.
// LEDs show a forward-then-backward chase pattern (R -> G -> B -> G -> R ...)
// so we can visually confirm the bitstream and clock are alive.

module riscv_fpga_top (
    input  wire clk,      // 25 MHz onboard oscillator (pin P6)
    output wire led_r,    // onboard RGB LED (pin A11)
    output wire led_g,    // onboard RGB LED (pin A12)
    output wire led_b,     // onboard RGB LED (pin B11)
    output wire led0,      // external LED, P5 pin C5
    output wire led1,      // external LED, P5 pin C6
    output wire led2,      // external LED, P5 pin C7
    output wire led3       // external LED, P5 pin C8
);

    // ---- Power-on reset ----
    reg [4:0] por_counter = 5'd0;
    reg       por_reset   = 1'b1;

    always @(posedge clk) begin
        if (por_counter < 5'd31) begin
            por_counter <= por_counter + 1'b1;
            por_reset   <= 1'b1;
        end else begin
            por_reset <= 1'b0;
        end
    end

    // ---- GPIO wires to/from the SoC ----
    wire [31:0] gpio_in;
    wire [31:0] gpio_out;
    assign gpio_in = 32'b0;   // no external inputs wired up yet

    // ---- External LED chase output (CPU-driven via 0x2000) ----
    assign led0 = gpio_out[0];
    assign led1 = gpio_out[1];
    assign led2 = gpio_out[2];
    assign led3 = gpio_out[3];

    // ---- The actual RISC-V SoC ----
    riscv_soc CPU_SOC (
        .clk      (clk),
        .reset    (por_reset),
        .gpio_in  (gpio_in),
        .gpio_out (gpio_out)
    );

    // ---- LED chase pattern: forward then backward ----
    // clk_div slows things down so the eye can see each step
    // (25,000,000 / 2^22 =~ 6 steps per second)
    reg [21:0] clk_div = 22'd0;
    always @(posedge clk) begin
        clk_div <= clk_div + 1'b1;
    end
    wire tick = (clk_div == 22'd0);   // one-cycle pulse each rollover

    // led_pos: 0 = R, 1 = G, 2 = B
    reg [1:0] led_pos   = 2'd0;
    reg       direction = 1'b0;       // 0 = forward, 1 = backward

    always @(posedge clk) begin
        if (tick) begin
            if (direction == 1'b0) begin
                // moving forward: R -> G -> B
                if (led_pos == 2'd2) begin
                    direction <= 1'b1;
                    led_pos   <= 2'd1;
                end else begin
                    led_pos <= led_pos + 1'b1;
                end
            end else begin
                // moving backward: B -> G -> R
                if (led_pos == 2'd0) begin
                    direction <= 1'b0;
                    led_pos   <= 2'd1;
                end else begin
                    led_pos <= led_pos - 1'b1;
                end
            end
        end
    end

    assign led_r = (led_pos == 2'd0);
    assign led_g = (led_pos == 2'd1);
    assign led_b = (led_pos == 2'd2);

endmodule
