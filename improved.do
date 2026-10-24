file mkdir results
vlog rtl/FSM_AuthLock_improved.v
vlog -sv tb/tb_improved.sv
vsim -voptargs=+acc work.tb_improved
add wave sim:/tb_improved/clk
add wave sim:/tb_improved/rst
add wave sim:/tb_improved/dut/clk_1ms
add wave -radix hexadecimal sim:/tb_improved/sw
add wave -radix hexadecimal sim:/tb_improved/key
add wave -radix hexadecimal sim:/tb_improved/dut/initial_sw
add wave -radix hexadecimal sim:/tb_improved/dut/state
add wave -radix hexadecimal sim:/tb_improved/dut/next_state
add wave -radix hexadecimal sim:/tb_improved/dut/input_PW
add wave sim:/tb_improved/red
add wave sim:/tb_improved/green
run 1 us
wave zoom full
