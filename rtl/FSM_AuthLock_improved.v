`timescale 1ns/1ps
// v1: minimal simulation/reset repair, not a security hardening revision.
   /*
        FSM_AuthLock: Finite State Machine for 4-digit password authentication
        Features:
           - FSM based 1kHz CLK
           - Error state implemented for unexpected situation
           - Detailed comments
   */
   module FSM_AuthLock_improved #(
 parameter CLK_HALF_CYCLES = 25000,
 parameter RESULT_TICKS = 3000,
 parameter BLINK_TICKS = 250
)( 
      input      wire   [0:0]   CLK_50,
      input      wire   [0:0]   SW_17, // Reset (Active-High)
      input      wire   [3:0]   SW,
      input      wire   [3:0]   KEY,
      output   wire   [6:0]   HEX_3, HEX_2, HEX_1, HEX_0,
      output   reg   [0:0]   LEDR_0, LEDG_7 // Active-High
   );
        // State definitions
        parameter ST_INIT = 4'b1010;
         parameter   ST_IDLE       = 4'b0000;
        parameter   ST_INPUT0    = 4'b0001;
        parameter   ST_INPUT1    = 4'b0010;
        parameter   ST_INPUT2    = 4'b0011;
        parameter   ST_INPUT3    = 4'b0100;
        parameter   ST_VERIFY    = 4'b0101;
        parameter   ST_SUCCESS    = 4'b0110;
        parameter   ST_FAIL       = 4'b0111;
        parameter   ST_STOP       = 4'b1000;
        parameter   ST_ERROR       = 4'b1001;
        // Embedded password
        parameter   PW = 16'h01AF;
        // Internal registers
        reg   [3:0]      state, next_state;
        reg   [31:0]   input_hex;   // Connected to output port for four 7-segment displays
        reg   [11:0]   count_ST_STOP, count_ST_ERROR;
        reg   [15:0]   input_PW;   // 16-bit memory for sequential 4-bit input by SW
        reg   [3:0]      initial_sw;   // Compared with current input for state transition
        // Wires
        wire      [0:0]      clk_1ms, rst;
        assign   rst = SW_17; //It becomes asynchronous RST
        wire      [31:0]   blinkseg_to_seg7;
        // Segment outputs
        SEG7_improved seg7_3(.B(input_hex[31:24]), .HEX(HEX_3));
        SEG7_improved seg7_2(.B(input_hex[23:16]), .HEX(HEX_2));
        SEG7_improved seg7_1(.B(input_hex[15:8] ), .HEX(HEX_1));
        SEG7_improved seg7_0(.B(input_hex[7:0] ), .HEX(HEX_0));
        // 1ms clock generator
        CNT_1ms_improved #(.HALF_CYCLES(CLK_HALF_CYCLES)) cnt_1ms(
 .RST(rst),
           .CLK_50   (CLK_50         ),
           .CLK_1ms   (clk_1ms         )
        );
      // Blinking input segment generator
      BlinkSEG_improved #(.N(BLINK_TICKS)) blinkseg_0(
 .RST(rst),
         .STATE   (state         ),      // The order includes a important data meaning
         .SW      (SW            ),
         .INPUT_PW(input_PW      ),
         .CLK_1ms   (clk_1ms         ),
         .SEG_32B   (blinkseg_to_seg7   )
      );
        // FSM: 1.State transition
        always @(posedge clk_1ms, posedge rst) begin
           if(rst)
              state   <=   ST_INIT;
           else
              state <= next_state;
        end
        // FSM: 2.Next-state combinational logic
        always @* begin
           case (state)
 ST_INIT: next_state = ST_IDLE;
            ST_IDLE      : next_state = (initial_sw != SW) ? ST_INPUT0 : ST_IDLE; //
            ST_INPUT0   : next_state = (!KEY[3] ? ST_INPUT1 : ST_INPUT0); // Triggered by KEY
            ST_INPUT1   : next_state = (!KEY[2] ? ST_INPUT2 : ST_INPUT1);
            ST_INPUT2   : next_state = (!KEY[1] ? ST_INPUT3 : ST_INPUT2);
            ST_INPUT3   : next_state = (!KEY[0] ? ST_VERIFY : ST_INPUT3);
            ST_VERIFY   : next_state = (input_PW == PW) ? ST_SUCCESS : ST_FAIL;
            ST_SUCCESS   : next_state = ST_STOP;
            ST_FAIL      : next_state = ST_STOP;
            ST_STOP      : next_state = (count_ST_STOP >= (RESULT_TICKS - 1)) ? ST_IDLE : ST_STOP; //
            ST_ERROR      : next_state = (count_ST_ERROR >= (RESULT_TICKS - 1)) ? ST_IDLE : ST_ERROR;
            default      : next_state = ST_ERROR; // Prevent unintended latch synthesis
         endcase
      end
       // FSM: 3.Output logic
       always @(posedge clk_1ms or posedge rst) begin
 if (rst) begin
   LEDG_7 <= 1'b0; LEDR_0 <= 1'b0;
   count_ST_STOP <= 0; count_ST_ERROR <= 0;
   input_PW <= 0; input_hex <= 32'h10101010;
   initial_sw <= 0;
 end else begin
          case (state)
             ST_INIT, ST_IDLE: begin
 if (state == ST_INIT) initial_sw <= SW;
                // Reset regs
                LEDG_7         <= 1'b0;
                LEDR_0         <= 1'b0;
                count_ST_STOP   <= 12'd0; // Safe reset for a case RST operated
                count_ST_ERROR   <= 12'd0;
                input_PW         <= 16'h0000;
                  input_hex     <= 32'h10101010; // Displays '----'
               end
               // Write 4-bit inputs in a memory from MSB to LSB
               ST_INPUT0: begin
                  input_PW[15:12]<= SW;
                  input_hex      <= blinkseg_to_seg7;
                  initial_sw      <= SW; // It contributes to detect a SW change in the IDLE
               end
               ST_INPUT1: begin
                  input_PW[11:8]   <= SW;
                  input_hex      <= blinkseg_to_seg7;
                  initial_sw      <= SW;
               end
               ST_INPUT2: begin
                  input_PW[7:4]   <= SW;
                  input_hex      <= blinkseg_to_seg7;
                  initial_sw      <= SW;
               end
               ST_INPUT3: begin
                  input_PW[3:0]   <= SW;
                  input_hex      <= blinkseg_to_seg7;
                  initial_sw      <= SW;
               end
               ST_SUCCESS: begin
                  input_hex   <= 32'h11121313; // Displays 'PASS'
                  LEDG_7      <= 1'b1;
               end
               ST_FAIL: begin
                  input_hex   <= 32'h14121516; // Displays 'FAIL'
                  LEDR_0      <= 1'b1;
               end
               ST_STOP: begin
                  // 3s counter
                  if(count_ST_STOP >= (RESULT_TICKS - 1))
                     count_ST_STOP   <= 12'd0;
                  else begin
                     count_ST_STOP   <= count_ST_STOP + 12'd1;
                     initial_sw      <= SW;
                  end
               end
               ST_ERROR: begin
                  input_hex   <= 32'hFFFFFFFF;   // Displays 'XXXX'
                  // 3s counter
                  if(count_ST_ERROR >= (RESULT_TICKS - 1))
                     count_ST_ERROR   <= 12'd0;
                  else begin
                     count_ST_ERROR <= count_ST_ERROR + 12'd1;
                     initial_sw      <= SW;
                  end
               end
              default: begin // For ST_VERIFY or unexpected situation
                 LEDG_7      <= 1'b0; // Safe reset before ST_SUCCESS or ST_FAIL
                 LEDR_0      <= 1'b0;
              end
           endcase
        end
   end // reset/normal operation
endmodule
   // ---------- Module dividing line -----------
   /*
        BlinkSEG: Blinking 7-segment generator(4 digits)
        Features:
        - Blink cycle is 2N (Displays input for N ms and nothing for N ms, subsequently)
        - Input signal 'STATE' cause a 4-digit 7-segment output pattern
   */
   module BlinkSEG_improved #(parameter N = 250)(
      input wire RST,
 input      wire   [3:0]      STATE,   //Key component of this module
      input      wire   [3:0]      SW,      //Input by user using SW3 ~ SW0
      input      wire   [15:0]   INPUT_PW,//Memorized input by user
      input      wire   [0:0]      CLK_1ms,
      output   reg   [31:0]   SEG_32B
   );
        reg    [11:0] count;
        reg    [7:0] sw;
        wire [31:0] input_pw_32b;    //Extend 16-bit INPUT_PW to 32-bit
        assign input_pw_32b = {
           4'h0, INPUT_PW[15:12],    //input_pw_32b[31:24] = ST_INPUT0 input
           4'h0, INPUT_PW[11:8],    //input_pw_32b[23:16] = ST_INPUT1 input
           4'h0, INPUT_PW[7:4],       //input_pw_32b[15:8] = ST_INPUT2 input
           4'h0, INPUT_PW[3:0]       //input_pw_32b[7:0]    = ST_INPUT3 input
        };
      always @(posedge CLK_1ms or posedge RST) begin
 if (RST) begin count <= 0; sw <= 8'h17; SEG_32B <= 32'h10101010; end
 else begin // original blinking pipeline retained
         // Output pattern logic
         case(STATE)
            4'd1: SEG_32B <= {sw, 8'h10, 8'h10, 8'h10};               // '(sw)---'
            4'd2: SEG_32B <= {input_pw_32b[31:24],   sw, 8'h10, 8'h10};// '@(sw)--'
            4'd3: SEG_32B <= {input_pw_32b[31:16],   sw, 8'h10};         // '@@(sw)-'
            4'd4: SEG_32B <= {input_pw_32b[31:8], sw};               // '@@@(sw)'
            default: SEG_32B <= input_pw_32b; // But if the codes works well, this case
         endcase
           // Blinking logic
           if (count >= 2*N - 1) begin   // Displays nothing for 0.25s, where N = 250
              sw    <= 8'h17;
              count <= 12'd0;
           end
           else if (count >= N - 1) begin// Displays sw(input) for 0.25s
              sw    <= {4'h0, SW};
              count <= count + 1;
           end
           else
              count <= count + 1;
        end
   end // reset/normal operation
endmodule
   // ---------- Module dividing line -----------
   /*
        CNT_1ms: Clock divider from 50MHz to 1kHz (1ms pulse)
   */
   module CNT_1ms_improved #(parameter HALF_CYCLES = 25000) (
      input wire RST,
 input wire    [0:0]       CLK_50,
      output reg   [0:0]       CLK_1ms
   );
        reg [15:0] count_1ms;
        always @(posedge CLK_50 or posedge RST) begin
 if (RST) begin count_1ms <= 0; CLK_1ms <= 0; end
 else begin
           if (count_1ms >= (HALF_CYCLES - 1)) begin
              CLK_1ms   <= ~CLK_1ms;
              count_1ms <= 16'd0;
           end else
              count_1ms <= count_1ms + 1;
        end
   end // reset/normal operation
endmodule
   // ---------- Module dividing line -----------
   /*
        SEG7: 7-segment decoder
        Features:
        - Supports hex numbers(0–F) and characters used in 'PASS', 'FAIL', '----', 'XXXX'
        - Based on Active-Low 7-segment display
   */
   module SEG7_improved (
      input wire [7:0] B,
      output reg [6:0] HEX
   );
        always @(*) begin
           case(B)
              8'd0 : HEX = 7'b1000000;
              8'd1 : HEX = 7'b1111001;
              8'd2 : HEX = 7'b0100100;
              8'd3 : HEX = 7'b0110000;
              8'd4 : HEX = 7'b0011001;
              8'd5 : HEX = 7'b0010010;
              8'd6 : HEX = 7'b0000010;
              8'd7 : HEX = 7'b1111000;
              8'd8 : HEX = 7'b0000000;
              8'd9 : HEX = 7'b0010000;
              8'd10 : HEX = 7'b0001000;
              8'd11 : HEX = 7'b0000011;
              8'd12 : HEX = 7'b1000110;
              8'd13 : HEX = 7'b0100001;
              8'd14 : HEX = 7'b0000110;
              8'd15 : HEX = 7'b0001110;
              8'h10 : HEX = 7'b0111111; // '-'
              8'h11 : HEX = 7'b0001100; // 'P'
              8'h12 : HEX = 7'b0001000; // 'A'
              8'h13 : HEX = 7'b0010010; // 'S'
              8'h14 : HEX = 7'b0001110; // 'F'
              8'h15 : HEX = 7'b1111001; // 'I'
              8'h16 : HEX = 7'b1000111; // 'L'
              8'h17   : HEX = 7'b1111111; // (nothing)
              default: HEX = 7'b0001001;// 'X'
           endcase
        end
   endmodule
