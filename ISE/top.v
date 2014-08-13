module top(
	//SMIMS SDK signals
	input                SDK_CLK,		//48MHz
	input                SDK_RSTN,
	input 		[7:0]  SDK_FIFO_CH,
	output          	   SDK_FIFO_RD,
	input         [15:0] SDK_FIFO_DI,
	input                SDK_FIFO_Empty,
	input 			   SDK_FIFO_AlmostEmpty,
	output        	   SDK_FIFO_WR,
	output        [15:0] SDK_FIFO_DO,
	input                SDK_FIFO_Full,
	input 			   SDK_FIFO_AlmostFull,  
	output  			   SDK_Interrupt,

	//UART signals, but not be used now
	input 					core0_UART_RXD,
	output					core0_UART_TXD,

	//GPIO signals
	output		[7:0]			GPIO_o,	//mapping to gpio pin on the board
	output		[7:0]			LED,		//mapping to LED on the board
	input       [1:0]       GPIO_i	//mapping to button on the board
 );
wire [5:0] state;
  
assign LED[0] = GPIO_o[0];
assign LED[1] = GPIO_o[1];
assign LED[2] = GPIO_o[2];
assign LED[3] = GPIO_o[3];
assign LED[4] = GPIO_o[4];
assign LED[5] = GPIO_o[5];
assign LED[6] = GPIO_o[6];
assign LED[7] = GPIO_o[7];
 
 //assign LED = {3'b0, state};  //Using LED to debug 

 //UART signals
 wire core0_tf_push_o;
 wire [7:0] core0_print_data_o;
 
 //openRISC signas
 wire [15:0] core_id;
 wire  [7:0]  openRISC_RSTN;          
 wire  [7:0]  openRISC_STALL;        
 wire  [7:0]  openRISC_ram_we;
 wire  [15:0] openRISC_ram_addr;
 wire  [31:0] openRISC_data_o;
 reg   [31:0] openRISC_data_i,_openRISC_data_i;

 wire  [31:0] openRISC_pc_0;
 wire  [31:0] openRISC_pc_1;
 wire  [31:0] openRISC_pc_2;
 wire  [31:0] openRISC_pc_3;
 wire  [31:0] openRISC_pc_4;
 wire  [31:0] openRISC_pc_5;
 wire  [31:0] openRISC_pc_6;
 wire  [31:0] openRISC_pc_7;
 
 wire  [31:0] openRISC_RAM_DATA_O_0, openRISC_RAM_DATA_O_1, openRISC_RAM_DATA_O_2, openRISC_RAM_DATA_O_3;
 wire  [31:0] openRISC_RAM_DATA_O_4, openRISC_RAM_DATA_O_5, openRISC_RAM_DATA_O_6, openRISC_RAM_DATA_O_7;
  
always@(posedge SDK_CLK or negedge SDK_RSTN)
begin
	if(~SDK_RSTN)
		openRISC_data_i <= 32'd0;
	else 
		openRISC_data_i <= _openRISC_data_i;
end
 
always@* begin
	case(core_id[3:0])
		4'd0:	_openRISC_data_i = openRISC_RAM_DATA_O_0;
		4'd1:   _openRISC_data_i = openRISC_RAM_DATA_O_1; 
		4'd2:   _openRISC_data_i = openRISC_RAM_DATA_O_2;
		4'd3:   _openRISC_data_i = openRISC_RAM_DATA_O_3;
		4'd4:	_openRISC_data_i = openRISC_RAM_DATA_O_4;
		4'd5:   _openRISC_data_i = openRISC_RAM_DATA_O_5; 
		4'd6:   _openRISC_data_i = openRISC_RAM_DATA_O_6;
		4'd7:   _openRISC_data_i = openRISC_RAM_DATA_O_7;
		default: _openRISC_data_i = openRISC_RAM_DATA_O_0;
	endcase	
end
 
OpenRISC_Interface OR_Interface0(
	.SDK_CLK(SDK_CLK),							//This clk must be the same with core0's clk. (48MHz)
	.SDK_RSTN(SDK_RSTN),
	
	//UART data signals
   .core0_tf_push_i(core0_tf_push_o),
	.core0_print_data_i(core0_print_data_o),
	
   //SMIMS SDK signals
	.SDK_FIFO_RD(SDK_FIFO_RD),
   .SDK_FIFO_DI(SDK_FIFO_DI),
   .SDK_FIFO_Empty(SDK_FIFO_Empty),
   .SDK_FIFO_WR(SDK_FIFO_WR),
   .SDK_FIFO_DO(SDK_FIFO_DO),
   .SDK_FIFO_Full(SDK_FIFO_Full), 
   .SDK_Interrupt(SDK_Interrupt),  
   
   //openRISC signals
   .openRISC_RSTN(openRISC_RSTN),
	.openRISC_STALL(openRISC_STALL),
	.openRISC_ram_we(openRISC_ram_we),
	.openRISC_ram_addr(openRISC_ram_addr),	
	.openRISC_data_o(openRISC_data_o),
	.openRISC_data_i(openRISC_data_i),
	.core_id(core_id),
	
	//each core's pc
	.openRISC_pc_0(openRISC_pc_0),
	.openRISC_pc_1(openRISC_pc_1),
	.openRISC_pc_2(openRISC_pc_2),
	.openRISC_pc_3(openRISC_pc_3),
	.openRISC_pc_4(openRISC_pc_4),
	.openRISC_pc_5(openRISC_pc_5),
	.openRISC_pc_6(openRISC_pc_6),
	.openRISC_pc_7(openRISC_pc_7),
	
	//For DEBUG
	.state_o(state)
);
 

/** core 0 **/
	or1200_sopc	or1200_sopc_inst_0
	(
		.CLOCK_48(SDK_CLK),						
		.rst_n(openRISC_RSTN[0]),	
		
		.openRISC_STALL(openRISC_STALL[0]),
		.openRISC_pc(openRISC_pc_0),
		//For ram top module
		.RAM_WE(openRISC_ram_we[0]),
		.RAM_ADDR(openRISC_ram_addr),
		.RAM_DATA_I(openRISC_data_o),
		.RAM_DATA_O(openRISC_RAM_DATA_O_0),
		.UART_TXD(core0_UART_TXD),
		.UART_RXD(core0_UART_RXD),
		//UART data signals
		.print_data_o(core0_print_data_o),
		.tf_push_o(core0_tf_push_o),
		//GPIO	
		.GPIO_o(GPIO_o),
		.GPIO_i(GPIO_i)
	);
//The following is for multi-core version.
//But haven't implemented.

/** core 1 **/
//	or1200_sopc	or1200_sopc_inst_1
//	(
//		.CLOCK_50(SDK_CLK),						
//		.rst_n(openRISC_RSTN[1]),					
//		
//		
//		.openRISC_STALL(openRISC_STALL[1]),
//		.openRISC_pc(openRISC_pc_1),
//		//For ram top module
//		.RAM_WE(openRISC_ram_we[1]),
//		.RAM_ADDR(openRISC_ram_addr),
//		.RAM_DATA_I(openRISC_data_o),
//		.RAM_DATA_O(openRISC_RAM_DATA_O_1)
//	);
//	
/** core 2 **/
//
//	or1200_sopc	or1200_sopc_inst_2
//	(
//		.CLOCK_50(SDK_CLK),						
//		.rst_n(openRISC_RSTN[2]),	
//		
//		.openRISC_STALL(openRISC_STALL[2]),
//		.openRISC_pc(openRISC_pc_2),
//		//For ram top module
//		.RAM_WE(openRISC_ram_we[2]),
//		.RAM_ADDR(openRISC_ram_addr),
//		.RAM_DATA_I(openRISC_data_o),
//		.RAM_DATA_O(openRISC_RAM_DATA_O_2)
//	);
	
/** core 3 **/
//	or1200_sopc	or1200_sopc_inst_3
//	(
//		.CLOCK_50(SDK_CLK),						
//		.rst_n(openRISC_RSTN[3]),	
//		
//		.openRISC_STALL(openRISC_STALL[3]),
//		.openRISC_pc(openRISC_pc_3),
//		//For ram top module
//		.RAM_WE(openRISC_ram_we[3]),
//		.RAM_ADDR(openRISC_ram_addr),
//		.RAM_DATA_I(openRISC_data_o),
//		.RAM_DATA_O(openRISC_RAM_DATA_O_3)
//	);
//		
///** core 4 **/
//	or1200_sopc	or1200_sopc_inst_4
//	(
//		.CLOCK_50(SDK_CLK),						
//		.rst_n(openRISC_RSTN[4]),	
//		
//		.openRISC_STALL(openRISC_STALL[4]),
//		.openRISC_pc(openRISC_pc_4),
//		//For ram top module
//		.RAM_WE(openRISC_ram_we[4]),
//		.RAM_ADDR(openRISC_ram_addr),
//		.RAM_DATA_I(openRISC_data_o),
//		.RAM_DATA_O(openRISC_RAM_DATA_O_4)
//	);  
//	
///** core 5 **/
//	or1200_sopc	or1200_sopc_inst_5
//	(
//		.CLOCK_50(SDK_CLK),						
//		.rst_n(openRISC_RSTN[5]),	
//		
//		.openRISC_STALL(openRISC_STALL[5]),
//		.openRISC_pc(openRISC_pc_5),
//		//For ram top module
//		.RAM_WE(openRISC_ram_we[5]),
//		.RAM_ADDR(openRISC_ram_addr),
//		.RAM_DATA_I(openRISC_data_o),
//		.RAM_DATA_O(openRISC_RAM_DATA_O_5)
//	);	
//
///** core 6 **/
//	or1200_sopc	or1200_sopc_inst_6
//	(
//		.CLOCK_50(SDK_CLK),						
//		.rst_n(openRISC_RSTN[6]),	
//		
//		.openRISC_STALL(openRISC_STALL[6]),
//		.openRISC_pc(openRISC_pc_6),
//		//For ram top module
//		.RAM_WE(openRISC_ram_we[6]),
//		.RAM_ADDR(openRISC_ram_addr),
//		.RAM_DATA_I(openRISC_data_o),
//		.RAM_DATA_O(openRISC_RAM_DATA_O_6)
//	);	
// 
// /** core 7 **/
//	or1200_sopc	or1200_sopc_inst_7
//	(
//		.CLOCK_50(SDK_CLK),						
//		.rst_n(openRISC_RSTN[7]),	
//		
//		.openRISC_STALL(openRISC_STALL[7]),
//		.openRISC_pc(openRISC_pc_7),
//		//For ram top module
//		.RAM_WE(openRISC_ram_we[7]),
//		.RAM_ADDR(openRISC_ram_addr),
//		.RAM_DATA_I(openRISC_data_o),
//		.RAM_DATA_O(openRISC_RAM_DATA_O_7)
//	);
endmodule
