`timescale 1 ns / 1 ns
 
 //`include "filter_FIR.v"

 module tt_um_delta_sigma
  #(
 parameter BW = 14 // optional parameter
 ) (
 // define I /O ’ s of the module
 input clk_i , // clock
 input rst_i , // reset
 input signed [BW-1:0] dac_i, //input
 output wire dac_o
 );

 //wire rst_i;
 //wire clk_i;
 //wire signed [BW-1:0] filter_s;
 wire signed[BW-1:0] filter_to_dac_s;

 filter_FIR
 #(BW)
 filter_dut (
 .clk_i (clk_i),
 .rst_i (rst_i),
 .filter_i (dac_i),
 .filter_o (filter_to_dac_s)
 );
 
 dac_sigma_delta
 #( BW )
 sigma_delta_dut (
 .clk_i ( clk_i ),
 .rst_i ( rst_i ),
 .dac_i (filter_to_dac_s),
 .dac_o (dac_o)
 );

 endmodule // top
 
  module dac_sigma_delta
 #(
 parameter BW = 8 // optional parameter
 ) (
 // define I /O ’ s of the module
 input clk_i , // clock
 input rst_i , // reset
 input signed [BW-1:0] dac_i, //input
 output wire dac_o
 ) ;

 // start the module implementation
 localparam BW_diff = 2;
 localparam BW_2 = BW + BW_diff;        //set the internally used bitwidth to BW + 2 to deal with overflow
 
 wire signed [BW_2-1:0] delta_in; //input into the delta
 wire signed [BW_2-1:0] delta_1;  //adder 1 output
 wire signed [BW_2-1:0] sigma_1;  //accumulator 1 output
 wire signed [BW_2-1:0] adc;      //ADC value to be subtracted from the input at the adder stage
 wire signed [BW_2-1:0] val_min;  //lowest number to be represented
 wire signed [BW_2-1:0] val_max;  //highest number to be represented

 reg signed [BW_2-1:0] int1_reg; //register for the integrator
 reg dac_reg; //output register for the DAC

 // assign the counter value to the output

 assign delta_in = {{2{dac_i[BW-1]}}, dac_i}; //padding the input to the internally used bit-width, while keeping the sign bits for s's complement
 assign dac_o = dac_reg;
 //assign val_max = $signed({{(BW_diff + 1){1'b0}},{(BW-1){1'b1}}});
 //assign val_min = $signed({{(BW_diff + 1){1'b1}},{(BW-1){1'b0}}});
 assign val_min = -(2**(BW-1)); //assigning the lowest value in 2's complement
 assign val_max = (2**(BW-1)-1);
 assign adc = (dac_o == 1'b0) ? val_max : val_min; //assign either the max or min value as ADC output 
 assign delta_1 = delta_in + $signed(adc);            //subracting the adc output from the input
 assign sigma_1 = int1_reg + delta_1;


 always @ ( posedge clk_i ) begin
 // gets active always when a positive edge of the clock signal occours
 
  if ( rst_i == 1'b1 ) begin
   // if reset is enabled, all registers are set to 0
   int1_reg <= {BW_2 {1'b0}};
   dac_reg <= 1'b0;
  end else begin
   int1_reg <= sigma_1;
   dac_reg <= sigma_1[BW_2-1]; //use the sign bit to set the dac output register to either 1 or 0
  end //if(rst_i == 1'b1 )
 end //always

 endmodule // counter
 
  module filter_FIR
 #(
 parameter BW = 14// optional parameter
 ) (
 // define I /O ’ s of the module
 input clk_i , // clock
 input rst_i , // reset
 input signed [BW-1:0] filter_i, //input
 output wire signed [ BW-1:0] filter_o
 );

 // start the module implementation
 //the module can be set to implement a moving average or a more general FIR filter
 reg signed [BW-1:0] d0, d1, d2, d3, d4, d5, d6, d7, d8;   //shift register
 //reg signed [2*BW-1:0] mul0, mul1, mul2, mul3, mul4, mul5, mul6, mul7, mul8;   
 //wire signed [BW-1:0] b0, b1, b2, b3, b4, b5, b6, b7, b8;
 reg signed [2*BW-1:0] sum;
 wire signed [2*BW-1:0] sum_shift;

 // assign values to the filter constants
 //assign b0 = $signed(8'b00000001);
 //assign b1 = $signed(8'b00000001);
 //assign b2 = $signed(8'b00000001);
 //assign b3 = $signed(8'b00000001);
 //assign b4 = $signed(8'b00000001);
 //assign b5 = $signed(8'b00000001);
 //assign b6 = $signed(8'b00000001);
 //assign b7 = $signed(8'b00000001);

 
 always @ ( posedge clk_i ) begin
 // gets active always when a positive edge of the clock signal occours
 if ( rst_i == 1'b1 ) begin // if reset is enabled
  //set all registers to 0 when reset is enabled
  d0 <= { BW {1'b0 }};
  d1 <= { BW {1'b0 }};
  d2 <= { BW {1'b0 }};
  d3 <= { BW {1'b0 }};
  d4 <= { BW {1'b0 }};
  d5 <= { BW {1'b0 }};
  d6 <= { BW {1'b0 }};
  d7 <= { BW {1'b0 }};
  d8 <= { BW {1'b0 }};
  end else begin
  //shifting the values from one register to the next, forming a shift register 
  d0 <= filter_i; //the input value is assigned to the first register, every clock cycle
  d1 <= d0;
  d2 <= d1;
  d3 <= d2;
  d4 <= d3;
  d5 <= d4;
  d6 <= d5;
  d7 <= d6;
  d8 <= d7;
  end
 end
 
 //optional section to turn the moving average filter into a more general FIR filter
 // always @ ( posedge clk_i ) begin
 // gets active always when a positive edge of the clock signal occours
 //if ( rst_i == 1'b1 ) begin
 // if reset is enabled
 // mul0 <= {2*BW {1'b0}};
 // mul1 <= {2*BW {1'b0}};
 // mul2 <= {2*BW {1'b0}};
 // mul3 <= {2*BW {1'b0}};
 // mul4 <= {2*BW {1'b0}};
 // mul5 <= {2*BW {1'b0}};
 // mul6 <= {2*BW {1'b0}};
 // mul7 <= {2*BW {1'b0}};

 // end else begin
  //multiply the register values with the filter constants
 // mul0 <= d0*b0;
 // mul1 <= d1*b1;
 // mul2 <= d2*b2;
 // mul3 <= d3*b3;
 // mul4 <= d4*b4;
 // mul5 <= d5*b5;
 // mul6 <= d6*b6;
 // mul7 <= d7*b7;

  //end
 //end

  always @ ( posedge clk_i ) begin
  // gets active always when a positive edge of the clock signal occours
  if (rst_i == 1'b1) begin
   sum <= {2*BW {1'b0}};
   end else begin
   //sum <= mul0 + mul1 + mul2 + mul3 + mul4 + mul5 + mul6 + mul7;
   //since all the samples saved in the registered are equally weighted, the summing up of samples can be optimized to:
   sum <= sum + d0 - d8; //the input sample is added to the sum while the last sample in the shift register is subtracted
   end
  end
  
 assign sum_shift = sum >>> (3); //shifting the sum of the sample values by 3, which equals a division by 8
 assign filter_o = sum_shift[BW-1:0]; //truncating the sum vector to bit width BW and assigning the shifted sum to the filter output
  
 endmodule //filter
 
 
