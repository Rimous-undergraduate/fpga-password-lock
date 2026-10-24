`timescale 1ns/1ps
module tb_improved;
 reg clk=0, rst=0; reg [3:0] sw=0, key=15;
 wire [6:0] h3,h2,h1,h0; wire red,green;
 integer checks=0, n;
 FSM_AuthLock_improved #(.CLK_HALF_CYCLES(2),.RESULT_TICKS(8),.BLINK_TICKS(2)) dut
 (clk,rst,sw,key,h3,h2,h1,h0,red,green);
 always #10 clk=~clk;
 task tick; begin @(posedge dut.clk_1ms); #1; end endtask
 task ck(input bit good,input string msg); begin
  if (!good) $fatal(1,"FAIL: %s",msg);
  checks=checks+1; $display("PASS: %s",msg);
 end endtask
 task reset_at(input [3:0] value); begin
  @(negedge clk); sw=value; key=15; rst=1; #1;
  ck(dut.state===dut.ST_INIT && red===0 && green===0,"asynchronous reset clears state/LEDs");
  repeat(3) @(negedge clk); rst=0;
  tick; ck(dut.state===dut.ST_IDLE && dut.initial_sw===value,"INIT captures current switch baseline");
  repeat(3) tick;
  ck(dut.state===dut.ST_IDLE,"unchanged switches keep IDLE after reset");
 end endtask
 task begin_entry; begin
  @(negedge dut.clk_1ms); sw=sw^4'h1; tick;
  ck(dut.state===dut.ST_INPUT0,"switch-only change starts input");
 end endtask
 task digit(input [3:0] value,input integer k,input [3:0] target); begin
  @(negedge dut.clk_1ms); sw=value; tick;
  @(negedge dut.clk_1ms); key[k]=0; tick;
  ck(dut.state===target,"expected key advances exactly one input stage");
  @(negedge dut.clk_1ms); key[k]=1;
 end endtask
 task result_idle; begin
  for(n=0;n<15 && dut.state!==dut.ST_IDLE;n=n+1) tick;
  ck(dut.state===dut.ST_IDLE,"result timeout returns to IDLE");
  tick; ck(red===0 && green===0,"IDLE clears result LEDs");
  repeat(3) tick; ck(dut.state===dut.ST_IDLE,"STOP baseline prevents unwanted restart");
 end endtask
 initial begin
  $dumpfile("results/improved.vcd"); $dumpvars(0,tb_improved);
  reset_at(4'hA); begin_entry;
  digit(0,3,dut.ST_INPUT1);
  // Old KEY[3] bouncing after leaving its state must not advance INPUT1.
  repeat(3) begin
   @(negedge dut.clk_1ms); key[3]=0; tick;
   ck(dut.state===dut.ST_INPUT1,"previous key bounce cannot advance next stage");
   @(negedge dut.clk_1ms); key[3]=1; tick;
  end
  digit(1,2,dut.ST_INPUT2); digit(10,1,dut.ST_INPUT3); digit(15,0,dut.ST_VERIFY);
  tick; ck(dut.state===dut.ST_SUCCESS,"01AF authenticates successfully");
  tick; ck(green===1 && red===0,"PASS LED output");
  ck({h3,h2,h1,h0}==={7'b0001100,7'b0001000,7'b0010010,7'b0010010},"PASS segment pattern");
  result_idle;
  begin_entry;
  digit(0,3,dut.ST_INPUT1); digit(1,2,dut.ST_INPUT2);
  digit(10,1,dut.ST_INPUT3); digit(14,0,dut.ST_VERIFY);
  tick; ck(dut.state===dut.ST_FAIL,"01AE is rejected");
  tick; ck(red===1 && green===0,"FAIL LED output");
  ck({h3,h2,h1,h0}==={7'b0001110,7'b0001000,7'b1111001,7'b1000111},"FAIL segment pattern");
  result_idle;
  begin_entry; digit(7,3,dut.ST_INPUT1); reset_at(4'h7);
  ck(dut.input_PW===0,"mid-entry reset clears partial password");
  begin_entry;
  // Simulation fault injection only: not proof of physical SEU recovery.
  @(negedge dut.clk_1ms); force dut.state=4'hF; #1;
  ck(dut.next_state===dut.ST_ERROR,"illegal state maps to ERROR");
  release dut.state; tick; ck(dut.state===dut.ST_ERROR,"ERROR entered");
  result_idle;
  ck((^dut.blinkseg_0.SEG_32B)!==1'bx,"blink pipeline has known values after reset");
  $display("ALL %0d CHECKS PASSED",checks); $finish;
 end
 initial begin #100000; $fatal(1,"watchdog timeout"); end
endmodule
