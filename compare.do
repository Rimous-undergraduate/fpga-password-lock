file mkdir results
# Run from authlock_review directory. Existing work library may be reused.
# If needed first execute: vlib work
vlog original/FSM_AuthLock_original.v
vlog rtl/FSM_AuthLock_improved.v
vlog -sv tb/tb_compare.sv
vsim -voptargs=+acc work.tb_compare
add wave sim:/tb_compare/common_clk
add wave sim:/tb_compare/rst
add wave -radix hexadecimal sim:/tb_compare/sw
add wave -radix hexadecimal sim:/tb_compare/key
add wave -divider Original
add wave -radix hexadecimal sim:/tb_compare/original_dut/initial_sw
add wave -radix hexadecimal sim:/tb_compare/original_dut/state
add wave -radix hexadecimal sim:/tb_compare/original_dut/next_state
add wave -radix hexadecimal sim:/tb_compare/original_dut/input_PW
add wave sim:/tb_compare/original_red
add wave sim:/tb_compare/original_green
add wave -divider Improved
add wave -radix hexadecimal sim:/tb_compare/improved_dut/initial_sw
add wave -radix hexadecimal sim:/tb_compare/improved_dut/state
add wave -radix hexadecimal sim:/tb_compare/improved_dut/next_state
add wave -radix hexadecimal sim:/tb_compare/improved_dut/input_PW
add wave sim:/tb_compare/improved_red
add wave sim:/tb_compare/improved_green
run 1 us
wave zoom full
