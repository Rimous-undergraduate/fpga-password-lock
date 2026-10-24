#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
mkdir -p results
iverilog -g2012 -Wall -s tb_original -o results/original.sim original/FSM_AuthLock_original.v tb/tb_original.sv 2>results/original_compile.log
vvp results/original.sim | tee results/original.log
iverilog -g2012 -Wall -s tb_improved -o results/improved.sim rtl/FSM_AuthLock_improved.v tb/tb_improved.sv 2>results/improved_compile.log
vvp results/improved.sim | tee results/improved.log
iverilog -g2012 -Wall -s tb_compare -o results/compare.sim original/FSM_AuthLock_original.v rtl/FSM_AuthLock_improved.v tb/tb_compare.sv 2>results/compare_compile.log
vvp results/compare.sim | tee results/compare.log
