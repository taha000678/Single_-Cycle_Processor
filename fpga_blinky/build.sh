#!/bin/bash
# build.sh -- synthesize, place-and-route, and pack the blinky bitstream
# for iCESugar-Pro. Run this from inside the fpga_blinky/ folder.
set -e

echo "== Step 1: Synthesis (yosys) =="
yosys -p 'synth_ecp5 -top blinky -json blinky.json' blinky.v

echo "== Step 2: Place & Route (nextpnr-ecp5) =="
nextpnr-ecp5 --25k --package CABGA256 \
    --json blinky.json \
    --lpf icesugarpro.lpf \
    --textcfg blinky_out.config \
    --freq 25

echo "== Step 3: Pack bitstream (ecppack) =="
ecppack blinky_out.config blinky.bit

echo "== Done! =="
echo "blinky.bit is ready. Copy/drag it onto the iCELink USB drive to program the board."