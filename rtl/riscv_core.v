`timescale 1ns/1ps

// ============================================================
//  riscv_core.v
//  CPU with one shared Wishbone master interface
// ============================================================

module riscv_core (
    input         clk,
    input         reset,

    // One shared Wishbone Master interface
    output        wb_cyc_o,
    output        wb_stb_o,
    output        wb_we_o,
    output [31:0] wb_adr_o,
    output [31:0] wb_dat_o,
    output [3:0]  wb_sel_o,
    input  [31:0] wb_dat_i,
    input         wb_ack_i
);

    // -------------------------------------------------------------------------
    // FETCH/EXEC controller for shared instruction/data bus
    // -------------------------------------------------------------------------
    localparam ST_FETCH = 1'b0;
    localparam ST_EXEC  = 1'b1;

    reg state;
    reg [31:0] instr_reg;

    wire fetch_phase = (state == ST_FETCH);
    wire exec_phase  = (state == ST_EXEC);

    // FIXED: declare before using inside always block
    wire cpu_mem_req;

    // Keep internal signal name for GTKWave/testbench compatibility
    wire [31:0] instruction;
    assign instruction = instr_reg;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state     <= ST_FETCH;
            instr_reg <= 32'h0000_0013;     // NOP = addi x0, x0, 0
        end else begin
            case (state)
                ST_FETCH: begin
                    if (wb_ack_i) begin
                        instr_reg <= wb_dat_i;
                        state     <= ST_EXEC;
                    end
                end

                ST_EXEC: begin
                    if ((cpu_mem_req == 1'b0) || wb_ack_i)
                        state <= ST_FETCH;
                end
            endcase
        end
    end

    // -------------------------------------------------------------------------
    // Internal datapath wires
    // -------------------------------------------------------------------------
    wire [31:0] PC_out;
    wire [31:0] PCplus4;
    wire [31:0] PCin;
    wire [31:0] PC_update_value;

    wire [31:0] RD1;
    wire [31:0] RD2;
    wire [31:0] immediate;
    wire [31:0] ALU_A_input;
    wire [31:0] ALU_mux_out;
    wire [31:0] ALU_result;
    wire [31:0] WriteBack;
    wire [31:0] WB_after_lui;
    wire [31:0] JAL_WB;
    wire [31:0] Branch_Addr;
    wire [31:0] Final_Target;
    wire [31:0] cpu_rdata;

    wire ALUSrc;
    wire MemtoReg;
    wire RegWrite;
    wire MemRead;
    wire MemWrite;
    wire Branch;
    wire Jump;

    wire [1:0] ALUop;
    wire [3:0] ALU_Ctrl;
    wire [2:0] imm_sel;

    wire Zero;
    wire Branch_Taken;
    wire PC_Sel;
    wire cpu_ack;

    wire is_lui;
    wire is_auipc;
    wire is_jalr;

    // LSU-generated Wishbone signals before shared-bus mux
    wire        lsu_wb_cyc;
    wire        lsu_wb_stb;
    wire        lsu_wb_we;
    wire [31:0] lsu_wb_adr;
    wire [31:0] lsu_wb_dat;
    wire [3:0]  lsu_wb_sel;

    assign is_lui   = (instruction[6:0] == 7'b0110111);
    assign is_auipc = (instruction[6:0] == 7'b0010111);
    assign is_jalr  = (instruction[6:0] == 7'b1100111);

    // AUIPC: ALU input A = PC; all others use register rs1
    assign ALU_A_input = is_auipc ? PC_out : RD1;

    // -------------------------------------------------------------------------
    // Program counter
    // PC updates only in EXEC phase. It holds its value during FETCH.
    // -------------------------------------------------------------------------
    assign PC_update_value = exec_phase ? PCin : PC_out;

    program_counter PC_REG (
        .clk(clk),
        .reset(reset),
        .PC_in(PC_update_value),
        .PC_out(PC_out)
    );

    PCplus4 PC_INC (
        .fromPC(PC_out),
        .NextoPC(PCplus4)
    );

    // -------------------------------------------------------------------------
    // Control unit
    // -------------------------------------------------------------------------
    Control_Unit CU (
        .instruction(instruction[6:0]),
        .ALUSrc(ALUSrc),
        .MemtoReg(MemtoReg),
        .RegWrite(RegWrite),
        .MemRead(MemRead),
        .MemWrite(MemWrite),
        .Branch(Branch),
        .Jump(Jump),
        .ALUop(ALUop)
    );

    // -------------------------------------------------------------------------
    // Register file
    // Register write is enabled only during EXEC phase.
    // -------------------------------------------------------------------------
    Register_File RF (
        .clk(clk),
        .reset(reset),
        .Reg_write(exec_phase & RegWrite),
        .rs1(instruction[19:15]),
        .rs2(instruction[24:20]),
        .rd(instruction[11:7]),
        .write_data(JAL_WB),
        .Read_Data1(RD1),
        .Read_Data2(RD2)
    );

    // -------------------------------------------------------------------------
    // Immediate selection
    // -------------------------------------------------------------------------
    assign imm_sel =
        (instruction[6:0] == 7'b0100011) ? 3'b001 : // S-type
        (instruction[6:0] == 7'b1100011) ? 3'b010 : // B-type
        (instruction[6:0] == 7'b0110111 ||
         instruction[6:0] == 7'b0010111) ? 3'b011 : // U-type
        (instruction[6:0] == 7'b1101111) ? 3'b100 : // J-type
        3'b000;                                      // I-type default

    immediate_generator IMM_GEN (
        .instruction(instruction),
        .imm_sel(imm_sel),
        .immediate(immediate)
    );

    // -------------------------------------------------------------------------
    // ALU
    // -------------------------------------------------------------------------
    ALU_Control ALU_CU (
        .ALUOp(ALUop),
        .funct7(instruction[31:25]),
        .funct3(instruction[14:12]),
        .ALU_Control(ALU_Ctrl)
    );

    Mux1 ALU_MUX (
        .sel1(ALUSrc),
        .A1(RD2),
        .B1(immediate),
        .Mux1_out(ALU_mux_out)
    );

    ALU_unit ALU (
        .A(ALU_A_input),
        .B(ALU_mux_out),
        .ALU_Sel(ALU_Ctrl),
        .Result(ALU_result),
        .Zero(Zero)
    );

    // -------------------------------------------------------------------------
    // Branch and jump logic
    // -------------------------------------------------------------------------
    Adder BRANCH_ADD (
        .in_1(PC_out),
        .in_2(immediate),
        .Sum_out(Branch_Addr)
    );

    assign Branch_Taken = Branch & Zero;
    assign PC_Sel       = Branch_Taken | Jump;

    // JALR target: rs1 + imm, bit-0 forced to 0
    assign Final_Target = is_jalr ? ((RD1 + immediate) & 32'hFFFF_FFFE) : Branch_Addr;

    Mux2 PC_MUX (
        .sel2(PC_Sel),
        .A2(PCplus4),
        .B2(Final_Target),
        .Mux2_out(PCin)
    );

    // -------------------------------------------------------------------------
    // Load/store unit
    // Data/MMIO bus request is active only in EXEC phase.
    // -------------------------------------------------------------------------
    assign cpu_mem_req = exec_phase & (MemRead | MemWrite);

    wb_master_lsu LSU (
        .clk(clk),
        .reset(reset),
        .cpu_mem_req(cpu_mem_req),
        .cpu_mem_we(MemWrite),
        .cpu_addr(ALU_result),
        .cpu_wdata(RD2),
        .cpu_funct3(instruction[14:12]),
        .cpu_rdata(cpu_rdata),
        .cpu_ack(cpu_ack),
        .wb_cyc_o(lsu_wb_cyc),
        .wb_stb_o(lsu_wb_stb),
        .wb_we_o(lsu_wb_we),
        .wb_adr_o(lsu_wb_adr),
        .wb_dat_o(lsu_wb_dat),
        .wb_sel_o(lsu_wb_sel),
        .wb_dat_i(wb_dat_i),
        .wb_ack_i(wb_ack_i)
    );

    // -------------------------------------------------------------------------
    // One shared Wishbone master bus output
    // FETCH drives program-memory address using PC.
    // EXEC drives data/LED address using LSU for load/store.
    // -------------------------------------------------------------------------
    assign wb_cyc_o = fetch_phase ? 1'b1    : lsu_wb_cyc;
    assign wb_stb_o = fetch_phase ? 1'b1    : lsu_wb_stb;
    assign wb_we_o  = fetch_phase ? 1'b0    : lsu_wb_we;
    assign wb_adr_o = fetch_phase ? PC_out  : lsu_wb_adr;
    assign wb_dat_o = fetch_phase ? 32'b0   : lsu_wb_dat;
    assign wb_sel_o = fetch_phase ? 4'b1111 : lsu_wb_sel;

    // -------------------------------------------------------------------------
    // Write-back path
    // -------------------------------------------------------------------------
    Mux3 WB_MUX (
        .sel3(MemtoReg),
        .A3(ALU_result),
        .B3(cpu_rdata),
        .Mux3_out(WriteBack)
    );

    assign WB_after_lui = is_lui ? immediate : WriteBack;

    Mux1 JAL_MUX (
        .sel1(Jump),
        .A1(WB_after_lui),
        .B1(PCplus4),
        .Mux1_out(JAL_WB)
    );

endmodule
