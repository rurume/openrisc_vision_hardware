//`include "gpio_test.v"
`include "ram_defines.v"

module ram0_top(
		//Wishbone interface
		input clk_i,
		input rst_i,
		
		input wb_stb_i,
		input wb_cyc_i,
		output reg wb_ack_o,
		input [31:0] wb_addr_i,
		input [3:0] wb_sel_i,
		input wb_we_i,
		input [31:0] wb_data_i,
		output [31:0] wb_data_o,
		//FIFO write to ram
		input 			openRISC_STALL,	
		input			RAM_WE,
		input	[15:0]	RAM_ADDR,
		input	[31:0]	RAM_DATA_I,
		output	[31:0]	RAM_DATA_O,
		//GPIO signals
		output [7:0] GPIO_o,		//LED
		input [1:0] GPIO_i		//Button
	);
	wire [31:0] ram_out_normal;
	wire [31:0] ram_out_GPIO;

	// request signal
	wire request;
	
	// inputs to ram
`ifdef RAM_65536
	wire [15:0] ram_address;
`endif
`ifdef RAM_8192
	wire [12:0] ram_address;
`endif

	wire [31:0] ram_data;
	wire [3:0] ram_byteena;
	wire ram_wren;
	
	// request signal's rising edge
	reg request_delay;
	wire request_rising_edge;

	// ack signal
	reg ram_ack;
	
	// get request signal
	assign request = wb_stb_i & wb_cyc_i;
	
	// select data to on-chip ram only when request = '1'
	// otherwise wren will be '0', so that no data will be
	// written into onchip ram by mistake.
	assign ram_data    = (openRISC_STALL==1'b1)?  RAM_DATA_I
						:(request == 1'b1)? (wb_data_i & {{8{ram_byteena[3]}},{8{ram_byteena[2]}},{8{ram_byteena[1]}},{8{ram_byteena[0]}}}):32'b0;  //xilinx
	
	assign ram_byteena = (openRISC_STALL==1'b1)? 4'b1111 
						:(request == 1'b1)? wb_sel_i:4'b0;
	
	assign ram_wren    = (openRISC_STALL==1'b1)? RAM_WE
						:(request == 1'b1)? wb_we_i:1'b0;
`ifdef RAM_65536
	assign ram_address = (openRISC_STALL==1'b1)?	RAM_ADDR 
						:(request == 1'b1)? wb_addr_i[17:2]:16'b0;
						
	assign 	RAM_DATA_O = (ram_address == 16'hffff) ? ram_out_GPIO : ram_out_normal; //16'hffff is for our GPIO
	assign 	wb_data_o  = (ram_address == 16'hffff) ? ram_out_GPIO : ram_out_normal;	//16'hffff is for our GPIO
`endif

`ifdef RAM_8192
	assign ram_address = (openRISC_STALL==1'b1)?	RAM_ADDR[12:0] 
						:(request == 1'b1)? wb_addr_i[14:2]:13'b0;
						
	assign 	RAM_DATA_O = (ram_address == 13'h1fff) ? ram_out_GPIO : ram_out_normal; //13'h1fff is for our GPIO
	assign 	wb_data_o  = (ram_address == 13'h1fff) ? ram_out_GPIO : ram_out_normal;	//13'h1fff is for our GPIO
`endif
	
	// [17:2] of 32-bit address input is connected to ram0,
	// for the reason of 4 byte alignment of OR1200 processor.
	// 8-bit char or 16-bit short int accesses are accomplished
	// with the help of wb_sel_i (byteena) signal.
	
//Mapping address 65535 / 8191 for GPIO	
simple_gpio simple_gpio(
	.clk(clk_i),
	.rst(rst_i),	
	.wea(ram_wren),
	.addr(ram_address),
	.din(ram_data),
	.dout(ram_out_GPIO),
	.GPIO_o(GPIO_o),
	.GPIO_i({14'b1111_1111_1111_11, GPIO_i})
);	

`ifdef RAM_8192
//xilinx ram
xilinx_ram_8192 u_ram0(
	.clka(clk_i),
	.rsta(rst_i),
	.wea(ram_wren),
	.addra(ram_address),
	.dina(ram_data),
	.douta(ram_out_normal)
);
`endif

`ifdef RAM_65536
//xilinx ram
xilinx_ram_65536 u_ram0(
	.clka(clk_i),
	.rsta(rst_i),
	.wea(ram_wren),
	.addra(ram_address),
	.dina(ram_data),
	.douta(ram_out_normal)
);
`endif
	
	// get the rising edge of request signal
	always @ (posedge clk_i)
	begin
		if(rst_i == 1) 
			request_delay <= 0;
		else 
			request_delay <= request;
	end 
	
	assign request_rising_edge = (request_delay ^ request) & request;

	// generate a 1 cycle acknowledgement for each request rising edge
	always @ (posedge clk_i)
	begin
		if (rst_i == 1)
			ram_ack <= 0;
		else if (request_rising_edge == 1)
			ram_ack <= 1;
		else
			ram_ack <= 0;
	end 

	// register wb_ack output, because onchip ram0 uses registered output
	always @ (posedge clk_i)
	begin
		if (rst_i == 1)
			wb_ack_o <= 0;
		else 
			wb_ack_o <= ram_ack;
	end 
endmodule

