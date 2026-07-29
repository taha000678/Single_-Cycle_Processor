`timescale 1ns/1ps

module wb_master_lsu (
    input         clk,
    input         reset,

    // ------------------------------------------------------------
    // CPU-side interface
    // ------------------------------------------------------------
    input         cpu_mem_req,      // Active for load or store
    input         cpu_mem_we,       // 1 = store, 0 = load
    input  [31:0] cpu_addr,         // Effective memory address
    input  [31:0] cpu_wdata,        // Register data used by store
    input  [2:0]  cpu_funct3,       // Instruction funct3 field

    output [31:0] cpu_rdata,        // Extended load result
    output        cpu_ack,          // Transaction acknowledgement

    // ------------------------------------------------------------
    // Wishbone master outputs
    // ------------------------------------------------------------
    output        wb_cyc_o,
    output        wb_stb_o,
    output        wb_we_o,
    output [31:0] wb_adr_o,
    output [31:0] wb_dat_o,
    output [3:0]  wb_sel_o,

    // ------------------------------------------------------------
    // Wishbone master inputs
    // ------------------------------------------------------------
    input  [31:0] wb_dat_i,
    input         wb_ack_i
);

    // ============================================================
    // Byte-lane selection
    //
    // Load funct3:
    // 000 = LB
    // 001 = LH
    // 010 = LW
    // 100 = LBU
    // 101 = LHU
    //
    // Store funct3:
    // 000 = SB
    // 001 = SH
    // 010 = SW
    // ============================================================
    reg [3:0] byte_select;

    always @(*) begin
        case (cpu_funct3[1:0])

            // Byte access
            2'b00: begin
                case (cpu_addr[1:0])
                    2'b00: byte_select = 4'b0001;
                    2'b01: byte_select = 4'b0010;
                    2'b10: byte_select = 4'b0100;
                    2'b11: byte_select = 4'b1000;
                    default: byte_select = 4'b0000;
                endcase
            end

            // Halfword access
            2'b01: begin
                if (cpu_addr[1] == 1'b0)
                    byte_select = 4'b0011;
                else
                    byte_select = 4'b1100;
            end

            // Word access
            default: begin
                byte_select = 4'b1111;
            end

        endcase
    end

    // ============================================================
    // Store-data alignment
    //
    // Wishbone slave writes only the byte lanes selected by
    // wb_sel_o. Therefore, SB and SH data must be shifted into
    // the correct byte positions.
    // ============================================================
    reg [31:0] aligned_wdata;

    always @(*) begin
        case (cpu_funct3[1:0])

            // SB
            2'b00: begin
                case (cpu_addr[1:0])
                    2'b00:
                        aligned_wdata = {
                            24'b0,
                            cpu_wdata[7:0]
                        };

                    2'b01:
                        aligned_wdata = {
                            16'b0,
                            cpu_wdata[7:0],
                            8'b0
                        };

                    2'b10:
                        aligned_wdata = {
                            8'b0,
                            cpu_wdata[7:0],
                            16'b0
                        };

                    2'b11:
                        aligned_wdata = {
                            cpu_wdata[7:0],
                            24'b0
                        };

                    default:
                        aligned_wdata = 32'b0;
                endcase
            end

            // SH
            2'b01: begin
                if (cpu_addr[1] == 1'b0)
                    aligned_wdata = {
                        16'b0,
                        cpu_wdata[15:0]
                    };
                else
                    aligned_wdata = {
                        cpu_wdata[15:0],
                        16'b0
                    };
            end

            // SW
            default: begin
                aligned_wdata = cpu_wdata;
            end

        endcase
    end

    // ============================================================
    // Load-data lane selection
    // ============================================================
    reg [7:0] selected_byte;

    always @(*) begin
        case (cpu_addr[1:0])
            2'b00: selected_byte = wb_dat_i[7:0];
            2'b01: selected_byte = wb_dat_i[15:8];
            2'b10: selected_byte = wb_dat_i[23:16];
            2'b11: selected_byte = wb_dat_i[31:24];
            default: selected_byte = 8'b0;
        endcase
    end

    reg [15:0] selected_halfword;

    always @(*) begin
        if (cpu_addr[1] == 1'b0)
            selected_halfword = wb_dat_i[15:0];
        else
            selected_halfword = wb_dat_i[31:16];
    end

    // ============================================================
    // Load-data sign and zero extension
    // ============================================================
    reg [31:0] extended_rdata;

    always @(*) begin
        case (cpu_funct3)

            // LB: signed byte load
            3'b000: begin
                extended_rdata = {
                    {24{selected_byte[7]}},
                    selected_byte
                };
            end

            // LH: signed halfword load
            3'b001: begin
                extended_rdata = {
                    {16{selected_halfword[15]}},
                    selected_halfword
                };
            end

            // LW: word load
            3'b010: begin
                extended_rdata = wb_dat_i;
            end

            // LBU: unsigned byte load
            3'b100: begin
                extended_rdata = {
                    24'b0,
                    selected_byte
                };
            end

            // LHU: unsigned halfword load
            3'b101: begin
                extended_rdata = {
                    16'b0,
                    selected_halfword
                };
            end

            default: begin
                extended_rdata = wb_dat_i;
            end

        endcase
    end

    // ============================================================
    // Wishbone master interface
    //
    // Current design assumes zero-wait-state slaves.
    // ============================================================
    assign wb_cyc_o = cpu_mem_req;
    assign wb_stb_o = cpu_mem_req;
    assign wb_we_o  = cpu_mem_we;

    assign wb_adr_o = cpu_addr;
    assign wb_dat_o = aligned_wdata;
    assign wb_sel_o = byte_select;

    assign cpu_rdata = extended_rdata;
    assign cpu_ack   = wb_ack_i;

    // clk and reset are currently unused because this LSU is
    // combinational and assumes immediate Wishbone acknowledgement.

endmodule
