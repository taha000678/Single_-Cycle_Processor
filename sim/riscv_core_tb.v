`timescale 1ns/1ps

// ============================================================
//  riscv_core_tb.v
//  Standalone testbench for riscv_core.v ONLY.
//  Uses core_test_mem.v (a single combined memory) instead of
//  the full Wishbone SoC (address decoder + 3 separate slaves +
//  LED peripheral), which come in a later stage.
// ============================================================

module riscv_core_tb;

    reg clk = 0;
    reg reset = 1;
    always #5 clk = ~clk;

    wire        wb_cyc, wb_stb, wb_we, wb_ack;
    wire [31:0] wb_adr, wb_dat_mosi, wb_dat_miso;
    wire [3:0]  wb_sel;

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

    core_test_mem MEM (
        .clk(clk),
        .reset(reset),
        .wb_cyc_i(wb_cyc),
        .wb_stb_i(wb_stb),
        .wb_we_i(wb_we),
        .wb_adr_i(wb_adr),
        .wb_dat_i(wb_dat_mosi),
        .wb_sel_i(wb_sel),
        .wb_dat_o(wb_dat_miso),
        .wb_ack_o(wb_ack)
    );

    // Debug taps for GTKWave
    wire [31:0] pc_debug   = CPU.PC_out;
    wire [31:0] instr_debug= CPU.instruction;
    wire [31:0] x5_debug   = CPU.RF.reg_mem[5];
    wire [31:0] x6_debug   = CPU.RF.reg_mem[6];
    wire [31:0] x7_debug   = CPU.RF.reg_mem[7];
    wire [31:0] x10_debug  = CPU.RF.reg_mem[10];
    wire [31:0] x11_debug  = CPU.RF.reg_mem[11];
    wire [31:0] x12_debug  = CPU.RF.reg_mem[12];
    wire [31:0] dmem_0x1000_debug = MEM.mem[1024]; // word index for byte addr 0x1000
    wire [31:0] dmem_0x1004_debug = MEM.mem[1025]; // word index for byte addr 0x1004
    wire [31:0] x9_debug  = CPU.RF.reg_mem[9];
    wire [31:0] x13_debug = CPU.RF.reg_mem[13];
    wire [31:0] x14_debug = CPU.RF.reg_mem[14];

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
        $dumpfile("riscv_core.vcd");
        $dumpvars(0, riscv_core_tb);

        reset = 1;
        repeat (5) @(posedge clk);
        reset = 0;

        repeat (500) @(posedge clk);

        $display("===========================================================");
        $display(" riscv_core standalone testbench");
        $display("===========================================================");
        $display("Final PC = 0x%08h", pc_debug);

        check("x7  (BEQ taken)",         x7_debug,  32'd1);
        check("x9  (BNE taken)",         x9_debug,  32'd2);
        check("x12 (BLT taken)",         x12_debug, 32'd3);
        check("x13 (BLTU not-taken)",    x13_debug, 32'd4);
        check("x14 (JAL taken)",         x14_debug, 32'd5);

        $display("===========================================================");
        $display(" Results: %0d PASSED | %0d FAILED", pass_count, fail_count);
        $display("===========================================================");

        $finish;
    end

    initial begin
        #100000;
        $display("[TIMEOUT] Simulation stopped.");
        $finish;
    end

endmodule