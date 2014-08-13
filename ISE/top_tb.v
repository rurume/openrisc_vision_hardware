`timescale 1ns/100ps
`define CLK_PERIOD 20

module top_tb();
  reg clk, rst;
  reg [1:0] button;
  
  initial begin
    clk = 1'b0;
    forever #(`CLK_PERIOD/2) clk  = ~clk;
  end
  
  initial begin
    rst = 1'b1;
	 button = 2'd3;
    #(`CLK_PERIOD) rst = 1'b0;
    #(5*`CLK_PERIOD) rst = 1'b1;
	 #(20*`CLK_PERIOD)  button = 2'd2;
	 #(20*`CLK_PERIOD)  button = 2'd3;
//    #(999999999*`CLK_PERIOD) 
//    $stop;
  end
  
  top top(
    .SDK_CLK(clk),
    .SDK_RSTN(rst),
	 .GPIO_i(button)
  );
  

  



endmodule