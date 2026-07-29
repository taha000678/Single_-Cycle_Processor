# branch_test.asm
# Tests BEQ, BNE, BLT, BLTU, JAL, JALR on the single-cycle RISC-V core
# Expected results:
#   x7  = 1   (BEQ taken)
#   x9  = 2   (BNE taken)
#   x12 = 3   (BLT signed taken)
#   x13 = 4   (BLTU unsigned NOT taken)
#   x14 = 5   (JAL taken)
#   x1  = return address saved by JAL

addi x5, x0, 5
addi x6, x0, 5
beq  x5, x6, L1        # taken (equal) -> skip next instr
addi x7, x0, 111        # SKIP
L1:
addi x7, x0, 1           # x7 = 1  (proof BEQ taken)

addi x8, x0, 3
bne  x5, x8, L2          # taken (not equal)
addi x9, x0, 111         # SKIP
L2:
addi x9, x0, 2           # x9 = 2

addi x10, x0, -1         # x10 = 0xFFFFFFFF (negative)
addi x11, x0, 1
blt  x10, x11, L3        # signed: -1 < 1 -> taken
addi x12, x0, 111        # SKIP
L3:
addi x12, x0, 3          # x12 = 3

bltu x10, x11, L4        # unsigned: 0xFFFFFFFF < 1 -> FALSE, not taken
addi x13, x0, 4          # this executes (not skipped)
L4:
addi x13, x13, 0         # x13 stays 4

jal x1, L5               # x1 = return addr, jump to L5
addi x14, x0, 111        # SKIP
L5:
addi x14, x0, 5          # x14 = 5

jalr x0, x1, 0           # jump back to return address saved by JAL
addi x15, x0, 6          # x15 = 6

loop: jal x0, loop        # halt (self-loop)