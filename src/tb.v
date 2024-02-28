 /*
 Simple testbench for the counter .
 */

 `timescale 1 ns / 1 ns
 
 `include "top.v"

 module tb;

 parameter BW = 14;

 // inputs
 reg rst_i = 1'b1 ;
 reg clk_i = 1'b0 ;
 reg signed [BW-1:0] dac_i;
 wire dac_o;

 //input clk_i , // clock
 //input rst_i , // reset
 //input signed [BW-1:0] dac_i, //input
 //output wire dac_o

 // DUT
 top
 #( BW )
 dac (
 .clk_i ( clk_i ),
 .rst_i ( rst_i ),
 .dac_i (dac_i),
 .dac_o (dac_o)
 );

 // Generate clock
 /* verilator lint_off STMTDLY */
 /* verilator lint_on STMTDLY */

 initial begin
 $dumpfile ( "top_tb.vcd") ;
 $dumpvars ;


 /* verilator lint_on STMTDLY */
 end

 endmodule // counter_tb
