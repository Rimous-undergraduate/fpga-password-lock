`timescale 1ns/1ps
// AI-assisted comparison harness. NOT an unmodified power-up test.
// Both internal divided-clock nets are overridden by common_clk (80 ns period).
// Original internal startup values are explicitly seeded at t=1 ns.
// External CLK_50, reset, SW and KEY are identical for both instances.
// Divider correctness and physical FPGA behavior are outside this experiment.
module tb_compare;
 reg clk=0, common_clk=0, rst=0;
 reg [3:0] sw=4'hA, key=4'hF;
 wire [6:0] oh3,oh2,oh1,oh0,ih3,ih2,ih1,ih0;
 wire original_red,original_green,improved_red,improved_green;
 integer checks=0;
 FSM_AuthLock original_dut(clk,rst,sw,key,oh3,oh2,oh1,oh0,original_red,original_green);
 FSM_AuthLock_improved #(.CLK_HALF_CYCLES(2),.RESULT_TICKS(8),.BLINK_TICKS(2))
 improved_dut(clk,rst,sw,key,ih3,ih2,ih1,ih0,improved_red,improved_green);
 always #10 clk=~clk;
 always #40 common_clk=~common_clk;
 task tick; begin @(posedge common_clk); #1; end endtask
 task ck(input bit good,input string msg); begin
  if(!good) $fatal(1,"FAIL: %s",msg);
  checks=checks+1; $display("PASS: %s",msg);
 end endtask
 task set_sw(input [3:0] value); begin @(negedge common_clk); sw=value; end endtask
 task digit(input [3:0] value,input integer button); begin
  set_sw(value); repeat(2) tick;
  @(negedge common_clk); key[button]=0; tick;
  @(negedge common_clk); key[button]=1; tick;
 end endtask
 task start_entry; begin
  set_sw(sw^4'h1); tick;
  ck(improved_dut.state===improved_dut.ST_INPUT0,"improved starts on SW change");
 end endtask
 initial begin
  force original_dut.clk_1ms=common_clk;
  force improved_dut.clk_1ms=common_clk;
  #1;
  // Test-only startup assumptions; original RTL itself is not modified.
  original_dut.initial_sw=4'hA;
  original_dut.state=original_dut.ST_ERROR; // ensures reset causes a state event
  original_dut.count_ST_STOP=0; original_dut.count_ST_ERROR=0;
  original_dut.input_PW=0; original_dut.input_hex=32'h10101010;
  original_dut.LEDG_7=0; original_dut.LEDR_0=0;
  original_dut.cnt_1ms.count_1ms=0; original_dut.cnt_1ms.CLK_1ms=0;
  original_dut.blinkseg_0.count=0; original_dut.blinkseg_0.sw=8'h17;
  original_dut.blinkseg_0.SEG_32B=32'h10101010;
  $display("CONDITIONS: common forced internal clock; original startup seeded; reduced improved timers");
  @(negedge clk); rst=1;
  repeat(3) @(negedge clk); rst=0;
  repeat(3) tick;
  ck(original_dut.state===0 && improved_dut.state===0,"both begin in IDLE with SW=A");
  ck(original_dut.initial_sw===4'hA && improved_dut.initial_sw===4'hA,"both have matching A baseline");
  start_entry;
  ck(original_dut.state===0 && original_dut.next_state===0,"original stalls in IDLE after identical SW change");
  digit(0,3); digit(1,2); digit(10,1); digit(15,0);
  tick;
  ck(improved_green===1 && improved_red===0,"same 01AF stimulus: improved shows PASS");
  ck(original_green===0 && original_red===0 && original_dut.state===0,"same 01AF stimulus: original still IDLE");
  repeat(12) tick;
  ck(improved_dut.state===0,"improved returns to IDLE after scaled timeout");
  start_entry;
  digit(0,3); digit(1,2); digit(10,1); digit(14,0);
  tick;
  ck(improved_red===1 && improved_green===0,"same 01AE stimulus: improved shows FAIL");
  ck(original_dut.state===0,"same 01AE stimulus: original still IDLE");
  repeat(12) tick;
  $display("ALL %0d COMPARISON CHECKS PASSED",checks);
  $finish;
 end
 initial begin #20000; $fatal(1,"watchdog timeout"); end
endmodule
