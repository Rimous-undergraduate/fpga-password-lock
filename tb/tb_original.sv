`timescale 1ns/1ps
module tb_original;
 reg clk=0, rst=0; reg [3:0] sw=0,key=15;
 wire [6:0] a,b,c,d; wire r,g;
 reg testclk=0;
 FSM_AuthLock dut(clk,rst,sw,key,a,b,c,d,r,g);
 always #10 clk=~clk;
 always #100 testclk=~testclk;
 initial begin
  $dumpfile("results/original.vcd"); $dumpvars(0,tb_original);
  #1; rst=1; #10; rst=0; #1000;
  if(dut.clk_1ms!==1'bx || dut.initial_sw!==4'bxxxx)
   $fatal(1,"Expected uninitialized divider/baseline in unseeded RTL");
  $display("REPRODUCED: reset does not initialize divider or initial_sw in original RTL");
  // Explicit test-only seeding bypasses startup X to isolate sensitivity-list bug.
  force dut.clk_1ms=testclk;
  dut.initial_sw=0;
  dut.state=dut.ST_INPUT0; #1;
  rst=1; #10; rst=0; #250;
  sw=1; #500;
  if(dut.state!==dut.ST_IDLE || dut.next_state!==dut.ST_IDLE)
   $fatal(1,"Expected stale next_state after switch-only change");
  $display("REPRODUCED: SW changes but original RTL remains IDLE (incomplete sensitivity)");
  $finish;
 end
endmodule
