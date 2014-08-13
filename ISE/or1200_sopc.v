//small sopc with openrisc
//`include "or1200_defines.v"
module or1200_sopc
	(
		////////////////////	Clock Input	 	////////////////////	 
		CLOCK_48,						//	On Board 48 MHz
		////////////////////////////////////////////////////////////
		rst_n,						
		////////////////////	DPDT Switch		////////////////////
		SW,								//	Toggle Switch[17:0]
		////////////////////////	LED		////////////////////////
		LEDR,							//	LED Red[17:0]
		////////////////////////	UART	////////////////////////
		UART_TXD,						//	UART Transmitter
		UART_RXD,						//	UART Receiver
		
		openRISC_STALL,
		openRISC_pc,
		//For ram top module
		RAM_WE,
		RAM_ADDR,
		RAM_DATA_I,
		RAM_DATA_O,
		///////////////////////////////////////////
		//UART data signals
		tf_push_o,
		print_data_o,
		//GPIO signals
		GPIO_o,
		GPIO_i
	);
//GPIO signals
input  [1:0] GPIO_i;
output [7:0] GPIO_o;
//UART data signals
output tf_push_o;
output [7:0] print_data_o;
////////////////////////	Clock Input	 	////////////////////////
input			CLOCK_48;					//	On Board 48 MHz
////////////////////////////////////////////////////////////////////
input			rst_n;					
////////////////////////	DPDT Switch		////////////////////////
input	[17:0]	SW;						//	Toggle Switch[17:0]
////////////////////////////	LED		////////////////////////////
output	[17:0]	LEDR;					//	LED Red[17:0]
////////////////////////////	UART	////////////////////////////
output			UART_TXD;				//	UART Transmitter
input				UART_RXD;				//	UART Receiver

input 			openRISC_STALL;
output  [31:0]	openRISC_pc;
//For ram top module
input 			RAM_WE;
input	[15:0]	RAM_ADDR;
input	[31:0]	RAM_DATA_I;
output	[31:0]	RAM_DATA_O;


wire CPU_RESET;
Reset_Delay	delay1 (.iRST(rst_n),.iCLK(CLOCK_48),.oRESET(CPU_RESET));
 
or1200_sys or1200(
    .clk_i(CLOCK_48), 
    .rst_n(CPU_RESET),

    // buttons
    .SW(SW[15:0]),

    // segments
    .LEDR(LEDR[17:0]),
    
    // uart interface
    .uart_rxd(UART_RXD),
    .uart_txd(UART_TXD),
	
	.openRISC_STALL(openRISC_STALL),
	.openRISC_pc(openRISC_pc),
	
	//For ram top module
	.RAM_WE(RAM_WE),
	.RAM_ADDR(RAM_ADDR),
	.RAM_DATA_I(RAM_DATA_I),
	.RAM_DATA_O(RAM_DATA_O),
	//////////////////////////////////
	//UART signals	
	.print_data_o(print_data_o),
	.tf_push_o(tf_push_o),
	//GPIO signals
	.GPIO_o(GPIO_o),
	.GPIO_i(GPIO_i)
);

endmodule
