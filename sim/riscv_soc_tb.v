`timescale 1ns/1ps

// ============================================================
//  riscv_soc_tb.v
//  Testbench for the FULL SoC (CPU + address decoder + 3 slaves).
//  Unlike the standalone core_test_mem.v setup, this exercises the
//  real address decode -- so 0x2000 (LED) is properly separate from
//  0x0000 (program mem), not aliased.
// ============================================================

module riscv_soc_tb;

    reg clk = 0;
    reg reset = 1;
    always #5 clk = ~clk;

    wire [31:0] gpio_out;
    reg  [31:0] gpio_in = 32'h000000FF;   // simulated external input pins (e.g. 8 switches all on)

    riscv_soc SOC (
        .clk(clk),
        .reset(reset),
        .gpio_in(gpio_in),
        .gpio_out(gpio_out)
    );

    // Debug taps into the data memory slave (word index = (addr-0x1000)/4)
    wire [31:0] r_add  = SOC.DATA_MEM.mem[0];
    wire [31:0] r_sub  = SOC.DATA_MEM.mem[1];
    wire [31:0] r_and  = SOC.DATA_MEM.mem[2];
    wire [31:0] r_or   = SOC.DATA_MEM.mem[3];
    wire [31:0] r_xor  = SOC.DATA_MEM.mem[4];
    wire [31:0] r_shl  = SOC.DATA_MEM.mem[5];
    wire [31:0] r_shr  = SOC.DATA_MEM.mem[6];
    wire [31:0] r_cmp  = SOC.DATA_MEM.mem[7];
    wire [31:0] r_loop = SOC.DATA_MEM.mem[8];
    wire [31:0] r_call = SOC.DATA_MEM.mem[9];
    wire [31:0] r_ucmp = SOC.DATA_MEM.mem[10];
    wire [31:0] r_byte = SOC.DATA_MEM.mem[11];
    wire [31:0] r_half = SOC.DATA_MEM.mem[12];
    wire [31:0] r_done = SOC.DATA_MEM.mem[13];
    wire [31:0] r_gpio_out = SOC.DATA_MEM.mem[14];
    wire [31:0] r_gpio_in  = SOC.DATA_MEM.mem[15];

    // Debug taps to see exactly what the CPU/bus are doing
    wire [31:0] pc_debug    = SOC.CPU.PC_out;
    wire [31:0] instr_debug = SOC.CPU.instruction;
    wire        soc_wb_cyc  = SOC.wb_cyc;
    wire        soc_wb_stb  = SOC.wb_stb;
    wire        soc_wb_we   = SOC.wb_we;
    wire [31:0] soc_wb_adr  = SOC.wb_adr;
    wire        soc_wb_ack  = SOC.wb_ack;
    wire [31:0] sp_debug    = SOC.CPU.RF.reg_mem[2];

    always @(sp_debug) begin
        if (!reset)
            $display("[SP CHANGE] time=%0t pc=%08h instr=%08h  sp -> %08h", $time, pc_debug, instr_debug, sp_debug);
    end

    integer pass_count = 0;
    integer fail_count = 0;

    task check(input [255:0] name, input [31:0] got, input [31:0] expected);
        begin
            if (got === expected) begin
                $display("[PASS] %0s got=0x%08h", name, got);
                pass_count = pass_count + 1;
            end else begin
                $display("[FAIL] %0s got=0x%08h expected=0x%08h", name, got, expected);
                fail_count = fail_count + 1;
            end
        end
    endtask

    initial begin
        $dumpfile("riscv_soc.vcd");
        $dumpvars(0, riscv_soc_tb);

        reset = 1;
        repeat (5) @(posedge clk);
        reset = 0;

        // Print the first 60 cycles so we can see if PC advances or gets stuck
        $display("time     pc       instr    sp       cyc stb we ack adr");
        repeat (60) begin
            @(posedge clk);
            $display("%0t  %08h %08h %08h  %0d   %0d  %0d  %0d  %08h",
                      $time, pc_debug, instr_debug, sp_debug, soc_wb_cyc, soc_wb_stb, soc_wb_we, soc_wb_ack, soc_wb_adr);
        end

        repeat (2940) @(posedge clk);   // remaining cycles

        $display("===========================================================");
        $display(" riscv_soc full SoC testbench -- test_full.c");
        $display("===========================================================");

        check("ADD  (a+b)",             r_add,  32'd13);
        check("SUB  (a-b)",             r_sub,  32'd7);
        check("AND  (a&b)",             r_and,  32'd2);
        check("OR   (a|b)",             r_or,   32'd11);
        check("XOR  (a^b)",             r_xor,  32'd9);
        check("SLL  (a<<2)",            r_shl,  32'd40);
        check("SRA/SRL (a>>1)",         r_shr,  32'd5);
        check("Branches (cmp)",         r_cmp,  32'd3);
        check("Loop sum (0..9)",        r_loop, 32'd45);
        check("Function call",          r_call, 32'd13);
        check("Unsigned cmp (BLTU)",    r_ucmp, 32'd1);
        check("Byte load (SB/LBU)",     r_byte, 32'h000000AB);
        check("Halfword load (SH/LHU)", r_half, 32'h0000BEEF);
        check("Done marker",            r_done, 32'hDEADBEEF);
        check("GPIO out (write+readback)", r_gpio_out, 32'hA5A5A5A5);
        check("GPIO in (external pins)",   r_gpio_in,  32'h000000FF);

        $display("===========================================================");
        $display(" Results: %0d PASSED | %0d FAILED", pass_count, fail_count);
        $display(" GPIO output = 0x%08h", gpio_out);
        $display("===========================================================");

        $finish;
    end

    initial begin
        #300000;
        $display("[TIMEOUT] Simulation stopped.");
        $finish;
    end

endmodule