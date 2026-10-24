file mkdir results
vlog original/FSM_AuthLock_original.v
vlog -sv tb/tb_original.sv
vsim -voptargs=+acc work.tb_original
add wave sim:/tb_original/clk
add wave sim:/tb_original/rst
add wave sim:/tb_original/sw
add wave sim:/tb_original/dut/clk_1ms
add wave -radix hexadecimal sim:/tb_original/dut/initial_sw
add wave -radix hexadecimal sim:/tb_original/dut/state
add wave -radix hexadecimal sim:/tb_original/dut/next_state
run 1 us
wave zoom full
