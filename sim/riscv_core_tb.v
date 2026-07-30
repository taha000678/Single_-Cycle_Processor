`timescale 1ns/1ps
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
    wire [31:0] x9_debug   = CPU.RF.reg_mem[9];
    wire [31:0] x13_debug  = CPU.RF.reg_mem[13];
    wire [31:0] x14_debug  = CPU.RF.reg_mem[14];

    // test_full.c result words: DMEM base 0x1000 = mem word index 1024
    wire [31:0] r_add    = MEM.mem[1024 + 0];   // a+b            -> 13
    wire [31:0] r_sub    = MEM.mem[1024 + 1];   // a-b            -> 7
    wire [31:0] r_and    = MEM.mem[1024 + 2];   // a&b             -> 2
    wire [31:0] r_or     = MEM.mem[1024 + 3];   // a|b             -> 11
    wire [31:0] r_xor    = MEM.mem[1024 + 4];   // a^b             -> 9
    wire [31:0] r_shl    = MEM.mem[1024 + 5];   // a<<2            -> 40
    wire [31:0] r_shr    = MEM.mem[1024 + 6];   // a>>1            -> 5
    wire [31:0] r_cmp    = MEM.mem[1024 + 7];   // branches        -> 3
    wire [31:0] r_loop   = MEM.mem[1024 + 8];   // for-loop sum    -> 45
    wire [31:0] r_call   = MEM.mem[1024 + 9];   // function call   -> 13
    wire [31:0] r_ucmp   = MEM.mem[1024 + 10];  // unsigned cmp    -> 1
    wire [31:0] r_byte   = MEM.mem[1024 + 11];  // byte load       -> 0xAB
    wire [31:0] r_half   = MEM.mem[1024 + 12];  // halfword load   -> 0xBEEF
    wire [31:0] r_done   = MEM.mem[1024 + 13];  // done marker     -> 0xDEADBEEF

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

        repeat (2000) @(posedge clk);

        $display("===========================================================");
        $display(" riscv_core standalone testbench -- test_full.c");
        $display("===========================================================");
        $display("Final PC = 0x%08h", pc_debug);

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

        $display("===========================================================");
        $display(" Results: %0d PASSED | %0d FAILED", pass_count, fail_count);
        $display("===========================================================");

        $finish;
    end

    initial begin
        #200000;
        $display("[TIMEOUT] Simulation stopped.");
        $finish;
    end

endmodule