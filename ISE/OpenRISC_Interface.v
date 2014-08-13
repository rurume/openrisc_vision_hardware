module OpenRISC_Interface(
   input            SDK_CLK,
   input            SDK_RSTN,
   
   //SMIMS SDK signals
   output reg           SDK_FIFO_RD,
   input         [15:0] SDK_FIFO_DI,
   input                SDK_FIFO_Empty,

   output reg           SDK_FIFO_WR,
   output reg    [15:0] SDK_FIFO_DO,
   input                SDK_FIFO_Full,
  
   output reg 			SDK_Interrupt,  
   //openRISC signals
   output reg[7:0]  openRISC_RSTN,	   //for 8 openRISC cores
   output reg[7:0]  openRISC_STALL,	   //for 8 openRISC cores
   output reg[7:0]	openRISC_ram_we,   //for 8 openRISC cores
   output reg[15:0] openRISC_ram_addr, //address : 8192 * (4 bytes)
   output 	 [31:0]	openRISC_data_o,
   input     [31:0]	openRISC_data_i,
   
   input     [31:0]	openRISC_pc_0,
   input     [31:0]	openRISC_pc_1,
   input     [31:0]	openRISC_pc_2,
   input     [31:0]	openRISC_pc_3,
   input     [31:0]	openRISC_pc_4,
   input     [31:0]	openRISC_pc_5,
   input     [31:0]	openRISC_pc_6,
   input     [31:0]	openRISC_pc_7,
      
   output 	 [15:0]	core_id,
	//UART data signals
   input 				core0_tf_push_i,
   input		 [7:0] 	core0_print_data_i,
	//TEST
	output	 [5:0]   state_o
);
assign state_o = cur_st;
//UART data 
reg [7:0]	UART_data_q, UART_data_d;

//OpenRISC signals
reg [7:0] 	_openRISC_RSTN;
reg [7:0] 	_openRISC_STALL;
reg [7:0]	_openRISC_ram_we;   
reg [15:0] 	_openRISC_ram_addr; 
reg [31:0]	_openRISC_data_o;

reg [15:0]  dataSize_cnt;
reg 		dataSize_cnt_en;
reg [15:0]  delay_cnt;
reg 		delay_cnt_en;
reg [15:0]  DATA_0,DATA_1;

//SDK signals
reg _SDK_FIFO_RD;
reg _SDK_FIFO_WR;
reg [15:0] _SDK_FIFO_DO;
reg _SDK_Interrupt;

//Reset all flags and control signals
reg CLEAN_SIGNAL;

//Control Signals
reg	[7:0] RESTORE_STALL;
reg 	LATCH_ID;
reg	LATCH_TYPE;
reg	LATCH_ADDR;
reg	LATCH_SIZE;
reg	LATCH_DATA_0;
reg	LATCH_DATA_1;
reg	WRITE_RAM;
reg	READ_RAM;
reg OPENRISC_RESET;
reg OPENRISC_START;

//Flags
reg [15:0] IDFlag;
reg [15:0] TypeFlag;
reg [15:0] AddrFlag;
reg [15:0] SizeFlag;

reg cur_core0_tf_push, _cur_core0_tf_push;

reg [7:0]  Running, _Running;

reg [5:0] cur_st, next_st;
parameter 	st_idle = 0,
				st_ready = 1,
				st_waitFlag = 2,
				st_getID = 3,
				st_cpuStatus = 4,
				st_getType = 5,
				st_getAddr = 6,
				st_getSize = 7,
				st_write_0 = 8,
				st_write_1 = 9,
				st_write_2 = 10,
				st_read_0 = 11,
				st_read_1 = 12,
				st_read_2 = 13,
				st_resetCPU = 14,
				st_startCPU = 15,
				st_clean = 16,
				st_readDelay_0 = 17,
				st_readDelay_1 = 18,
				st_readDelay_2 = 19,
				st_readDelay_3 = 20,
				st_readDelay_4 = 21,
				st_readDelay_5 = 22,
				st_readDelay_6 = 23,
				st_cleanDelay = 24,
				st_uart_print = 25,
				st_interrupt  = 26,
				st_error = 27,
				st_core0_end = 28,
				st_waitAck = 29,
				st_getAck = 30,
				st_AckDelay = 31,
				st_read_3 = 32;	

always@*begin
	_cur_core0_tf_push = core0_tf_push_i;
	UART_data_d = UART_data_q;

	next_st = cur_st;
	_SDK_FIFO_RD = 1'b0;
	_SDK_FIFO_WR = 1'b0;
	_SDK_FIFO_DO = 16'd0;
	_SDK_Interrupt = 1'b0;
	
	LATCH_ID = 1'b0;
	LATCH_TYPE = 1'b0;
	LATCH_ADDR = 1'b0;
	LATCH_SIZE = 1'b0;
	LATCH_DATA_0 = 1'b0;
	LATCH_DATA_1 = 1'b0;
	
	WRITE_RAM = 1'b0;
	READ_RAM = 1'b0;
	OPENRISC_RESET = 1'b0;
	OPENRISC_START = 1'b0;
	
	CLEAN_SIGNAL = 1'b0;
	RESTORE_STALL = 8'b0;
	
	dataSize_cnt_en = 1'b0;
	delay_cnt_en = 1'b0;
	case(cur_st)
		st_idle: begin
			if(~SDK_FIFO_Empty) begin
				next_st = st_ready;
			end
			else if(cur_core0_tf_push && (~core0_tf_push_i)) begin 
				UART_data_d = core0_print_data_i;
				next_st = st_uart_print;
			end
			else if(openRISC_STALL[0] && Running[0]) begin
				UART_data_d = 8'hff;
				next_st = st_core0_end;
			end
			else begin
				next_st = st_idle;
			end
		end
		st_core0_end: begin
			if(SDK_FIFO_Full) begin
					next_st = st_core0_end;
			end
			else begin
				next_st = st_interrupt;
				_SDK_FIFO_WR = 1'b1;
				_SDK_FIFO_DO = {8'b0111_1111, UART_data_q};
			end
		end
		st_uart_print: begin
			if(SDK_FIFO_Full) begin
					next_st = st_uart_print;
			end
			else begin
				next_st = st_interrupt;
				_SDK_FIFO_WR = 1'b1;
				_SDK_FIFO_DO = {8'b1000_0000, UART_data_q};
			end
		end
		st_interrupt: begin			
			_SDK_Interrupt = 1'b1;
			next_st = st_waitAck;
		end
		st_waitAck: begin
			if(~SDK_FIFO_Empty) begin
				_SDK_FIFO_RD = 1'b1;
				next_st = st_AckDelay;
			end
			else begin				
				next_st = st_waitAck;
			end
		end
		st_AckDelay: begin
			next_st = st_getAck;
		end
		st_getAck: begin
			if(SDK_FIFO_DI == {8'hff, UART_data_q}) begin
				RESTORE_STALL[0] = 1'b1;
				next_st = st_idle;
			end
			else begin
				next_st = st_error;
			end
		end
		st_error: begin
			next_st = st_error;
		end
		st_ready: begin
			delay_cnt_en = 1'b1;
			if(delay_cnt > 16'd20) begin //Guarantee flag datas is in the FIFO buffer
				_SDK_FIFO_RD = 1'b1;
				next_st = st_readDelay_0;
			end
			else next_st = st_ready;
		end
		st_readDelay_0: begin
			next_st = st_waitFlag;
		end
		st_waitFlag: begin
			if(SDK_FIFO_DI == 16'hfff0) begin
				next_st = st_readDelay_1;
				_SDK_FIFO_RD = 1'b1;
			end	
			else 
				next_st = st_idle;
		end
		st_readDelay_1: begin
			next_st = st_getID;
		end
		st_getID: begin
			LATCH_ID = 1'b1;
			next_st = st_cpuStatus;
		end
		st_cpuStatus: begin
			case(core_id[3:0])
				4'd0: begin
						if((openRISC_STALL[0] == 1'b1) ) begin
							next_st = st_readDelay_2;
							_SDK_FIFO_RD = 1'b1;
						end	
						else 
							next_st = st_cpuStatus;
				end
				4'd1: begin
						if((openRISC_STALL[1] == 1'b1) ) begin
							next_st = st_readDelay_2;
							_SDK_FIFO_RD = 1'b1;
						end	
						else 
							next_st = st_cpuStatus;
				end
				4'd2: begin
						if((openRISC_STALL[2] == 1'b1) ) begin
							next_st = st_readDelay_2;
							_SDK_FIFO_RD = 1'b1;
						end	
						else 
							next_st = st_cpuStatus;
				end
				4'd3: begin
						if((openRISC_STALL[3] == 1'b1) ) begin
							next_st = st_readDelay_2;
							_SDK_FIFO_RD = 1'b1;
						end	
						else 
							next_st = st_cpuStatus;
				end
				4'd4: begin
						if((openRISC_STALL[4] == 1'b1) ) begin
							next_st = st_readDelay_2;
							_SDK_FIFO_RD = 1'b1;
						end	
						else 
							next_st = st_cpuStatus;
				end
				4'd5: begin
						if((openRISC_STALL[5] == 1'b1) ) begin
							next_st = st_readDelay_2;
							_SDK_FIFO_RD = 1'b1;
						end	
						else 
							next_st = st_cpuStatus;
				end
				4'd6: begin
						if((openRISC_STALL[6] == 1'b1) ) begin
							next_st = st_readDelay_2;
							_SDK_FIFO_RD = 1'b1;
						end	
						else 
							next_st = st_cpuStatus;
				end
				4'd7: begin
						if((openRISC_STALL[7] == 1'b1) ) begin
							next_st = st_readDelay_2;
							_SDK_FIFO_RD = 1'b1;
						end	
						else 
							next_st = st_cpuStatus;
				end
			    default: next_st = st_cpuStatus;
			endcase
		end
		st_readDelay_2: begin
					next_st = st_getType;
		end
		st_getType: begin
					LATCH_TYPE = 1'b1;
					case(SDK_FIFO_DI)
						16'hfff1: begin 
								next_st = st_readDelay_3;
								_SDK_FIFO_RD = 1'b1;
						end	
						16'hfff2: begin 
							next_st = st_readDelay_3;
							_SDK_FIFO_RD = 1'b1;
						end	
						16'hfff3: begin 
							next_st = st_resetCPU;	
						end		
						default: next_st = cur_st;
					endcase
				
		end
		st_readDelay_3: begin
					next_st = st_getAddr;
		end
		st_getAddr: begin
					_SDK_FIFO_RD = 1'b1;
					LATCH_ADDR = 1'b1;	
					next_st = st_readDelay_4;
		end
		st_readDelay_4: begin
					next_st = st_getSize;
		end
		st_getSize: begin
				LATCH_SIZE = 1'b1;
				if(TypeFlag == 16'hfff1) begin
					next_st = st_readDelay_5;
					_SDK_FIFO_RD = 1'b1;
				end	
				else if(TypeFlag == 16'hfff2) begin
					next_st = st_read_0;
				end	
				else next_st = cur_st;		
		end
		st_readDelay_5: begin
				next_st = st_write_0;
		end
		st_write_0: begin
				if(~SDK_FIFO_Empty) begin
					next_st = st_readDelay_6;
					_SDK_FIFO_RD = 1'b1;
					LATCH_DATA_0 = 1'b1;
					dataSize_cnt_en = 1'b1;
				end
				else next_st = st_write_0;	
		end
		st_readDelay_6: begin
				next_st = st_write_1;
		end
		st_write_1: begin
				next_st = st_write_2;
				LATCH_DATA_1 = 1'b1;
				dataSize_cnt_en = 1'b1;
				WRITE_RAM = 1'b1;	
		end
		st_write_2: begin
				if(dataSize_cnt < SizeFlag) begin
					if(~SDK_FIFO_Empty) begin
						next_st = st_readDelay_5;
						_SDK_FIFO_RD = 1'b1;
					end
					else next_st = st_write_2;
				end
				else begin
					next_st = st_clean;
				end
		end
		st_read_0: begin
				if(delay_cnt > 16'd5) begin 
					next_st = st_read_1;
					dataSize_cnt_en = 1'b1;
				end
				else begin
					next_st = st_read_0;
					delay_cnt_en = 1'b1;
				end					
		end
		st_read_1: begin
				if(SDK_FIFO_Full) begin
					next_st = st_read_1;
				end
				else begin
					next_st = st_read_2;
					_SDK_FIFO_WR = 1'b1;
					_SDK_FIFO_DO = openRISC_data_i[31:16];
					dataSize_cnt_en = 1'b1;
				end
		end
		st_read_2: begin
				if(SDK_FIFO_Full) begin
					next_st = st_read_2;
				end
				else if(dataSize_cnt < SizeFlag) begin
					next_st = st_read_0;
					_SDK_FIFO_WR = 1'b1;
					_SDK_FIFO_DO = openRISC_data_i[15:0];
				end
				else begin
					//next_st = st_read_3;
					next_st = st_clean;
					_SDK_FIFO_WR = 1'b1;
					_SDK_FIFO_DO = openRISC_data_i[15:0];
				end
		end
		/*st_read_3: begin
			_SDK_Interrupt = 1'b1;
			next_st = st_clean;
		end*/
		st_resetCPU: begin
				OPENRISC_RESET = 1'b1;
				next_st = st_startCPU;
		end
		st_startCPU: begin
				delay_cnt_en = 1'b1;
				OPENRISC_START = 1'b1;
				if(delay_cnt > 16'd30)
					next_st = st_clean;
				else
					next_st = st_startCPU;
				
		end
		st_clean: begin
				next_st = st_cleanDelay;
				CLEAN_SIGNAL = 1'b1;				
		end
		st_cleanDelay: begin				
				next_st = st_idle;
		end
		
	endcase	
end

//SDK and state signals 
always@(posedge SDK_CLK or negedge SDK_RSTN)begin
	if(~SDK_RSTN) begin
		cur_st <= st_idle;	
		SDK_FIFO_RD <= 1'b0;
		SDK_FIFO_WR <= 1'b0;
		SDK_FIFO_DO <= 16'd0;
		SDK_Interrupt <= 1'b0; 
	end
	else begin
		cur_st <= next_st;
		SDK_FIFO_RD <= _SDK_FIFO_RD;
		SDK_FIFO_WR <= _SDK_FIFO_WR;
		SDK_FIFO_DO <= _SDK_FIFO_DO;
		SDK_Interrupt <= _SDK_Interrupt; 
	end
end

//OpenRISC Signals
always@* begin
	_Running = Running;
	_openRISC_STALL[0] = (openRISC_pc_0 == 32'd4) ? 1'b1 : ((cur_st == st_uart_print) ? 1'b1 : openRISC_STALL[0]);
	if (cur_st == st_core0_end) _Running[0] = 1'b0;	
	
	if (core_id[3:0]==4'd0)
	begin
		if (OPENRISC_START)	begin 
			_openRISC_STALL[0] = 1'b0;
			_Running[0] = 1'b1;
		end		
	end
	if(RESTORE_STALL[0] && (openRISC_pc_0 != 32'd4)) begin
		_openRISC_STALL[0] = 1'b0;
	end
	
	if (core_id[3:0]==4'd1)
	begin
		if (OPENRISC_START)	begin
			_openRISC_STALL[1] = 1'b0;
			_Running[1] = 1'b1;
		end
		else 					_openRISC_STALL[1] = (!openRISC_pc_1)? 1'b1 : openRISC_STALL[1];
	end
	else 						_openRISC_STALL[1] = (!openRISC_pc_1)? 1'b1 : openRISC_STALL[1];
	
	if (core_id[3:0]==4'd2)
	begin
		if (OPENRISC_START)	begin
			_openRISC_STALL[2] = 1'b0;
			_Running[2] = 1'b1;
		end
		else 					_openRISC_STALL[2] = (!openRISC_pc_2)? 1'b1 : openRISC_STALL[2];
	end
	else 						_openRISC_STALL[2] = (!openRISC_pc_2)? 1'b1 : openRISC_STALL[2];
	
	if (core_id[3:0]==4'd3)
	begin
		if (OPENRISC_START)	begin
			_openRISC_STALL[3] = 1'b0;
			_Running[3] = 1'b1;
		end
		else 					_openRISC_STALL[3] = (!openRISC_pc_3)? 1'b1 : openRISC_STALL[3];
	end
	else 						_openRISC_STALL[3] = (!openRISC_pc_3)? 1'b1 : openRISC_STALL[3];
	
				
	if (core_id[3:0]==4'd4)
	begin
		if (OPENRISC_START)	begin
			_openRISC_STALL[4] = 1'b0;
			_Running[4] = 1'b1;
		end
		else 					_openRISC_STALL[4] = (!openRISC_pc_4)? 1'b1 : openRISC_STALL[4];
	end
	else 						_openRISC_STALL[4] = (!openRISC_pc_4)? 1'b1 : openRISC_STALL[4];
	
	if (core_id[3:0]==4'd5)
	begin
		if (OPENRISC_START)	begin
			_openRISC_STALL[5] = 1'b0;
			_Running[5] = 1'b1;
		end
		else 					_openRISC_STALL[5] = (!openRISC_pc_5)? 1'b1 : openRISC_STALL[5];
	end
	else 						_openRISC_STALL[5] = (!openRISC_pc_5)? 1'b1 : openRISC_STALL[5];
	
	if (core_id[3:0]==4'd6)
	begin
		if (OPENRISC_START)	begin
			_openRISC_STALL[6] = 1'b0;
			_Running[6] = 1'b1;
		end
		else 					_openRISC_STALL[6] = (!openRISC_pc_6)? 1'b1 : openRISC_STALL[6];
	end
	else 						_openRISC_STALL[6] = (!openRISC_pc_6)? 1'b1 : openRISC_STALL[6];
	
	if (core_id[3:0]==4'd7)
	begin
		if (OPENRISC_START)	begin
			_openRISC_STALL[7] = 1'b0;
			_Running[7] = 1'b1;
		end
		else 					_openRISC_STALL[7] = (!openRISC_pc_7)? 1'b1 : openRISC_STALL[7];
	end
	else 						_openRISC_STALL[7] = (!openRISC_pc_7)? 1'b1 : openRISC_STALL[7];
	
	
	_openRISC_RSTN[0] = ((OPENRISC_RESET == 1'b1) && (core_id[3:0] == 4'd0)) ? 1'b0: 1'b1;
	_openRISC_RSTN[1] = ((OPENRISC_RESET == 1'b1) && (core_id[3:0] == 4'd1)) ? 1'b0: 1'b1;
	_openRISC_RSTN[2] = ((OPENRISC_RESET == 1'b1) && (core_id[3:0] == 4'd2)) ? 1'b0: 1'b1;
	_openRISC_RSTN[3] = ((OPENRISC_RESET == 1'b1) && (core_id[3:0] == 4'd3)) ? 1'b0: 1'b1;
	_openRISC_RSTN[4] = ((OPENRISC_RESET == 1'b1) && (core_id[3:0] == 4'd4)) ? 1'b0: 1'b1;
	_openRISC_RSTN[5] = ((OPENRISC_RESET == 1'b1) && (core_id[3:0] == 4'd5)) ? 1'b0: 1'b1;
	_openRISC_RSTN[6] = ((OPENRISC_RESET == 1'b1) && (core_id[3:0] == 4'd6)) ? 1'b0: 1'b1;
	_openRISC_RSTN[7] = ((OPENRISC_RESET == 1'b1) && (core_id[3:0] == 4'd7)) ? 1'b0: 1'b1;
	
	
	
	
	_openRISC_ram_we[0] = ( (WRITE_RAM == 1'b1) && (core_id[3:0] == 4'd0) ) ? 1'b1: 1'b0;
	_openRISC_ram_we[1] = ( (WRITE_RAM == 1'b1) && (core_id[3:0] == 4'd1) ) ? 1'b1: 1'b0;
	_openRISC_ram_we[2] = ( (WRITE_RAM == 1'b1) && (core_id[3:0] == 4'd2) ) ? 1'b1: 1'b0;
	_openRISC_ram_we[3] = ( (WRITE_RAM == 1'b1) && (core_id[3:0] == 4'd3) ) ? 1'b1: 1'b0;
	_openRISC_ram_we[4] = ( (WRITE_RAM == 1'b1) && (core_id[3:0] == 4'd4) ) ? 1'b1: 1'b0;
	_openRISC_ram_we[5] = ( (WRITE_RAM == 1'b1) && (core_id[3:0] == 4'd5) ) ? 1'b1: 1'b0;
	_openRISC_ram_we[6] = ( (WRITE_RAM == 1'b1) && (core_id[3:0] == 4'd6) ) ? 1'b1: 1'b0;
	_openRISC_ram_we[7] = ( (WRITE_RAM == 1'b1) && (core_id[3:0] == 4'd7) ) ? 1'b1: 1'b0;
	
	
	_openRISC_ram_addr = AddrFlag + (dataSize_cnt >> 2);
end

always@(posedge SDK_CLK or negedge SDK_RSTN)begin
	if(~SDK_RSTN) begin
		cur_core0_tf_push <= 1'b0;
		UART_data_q <= 8'b0;
		Running <= 8'b0000_0000;
		openRISC_STALL <= 8'b1111_1111;
		openRISC_RSTN <= 8'b1111_1111;
		openRISC_ram_we <= 8'b0000_0000;
		openRISC_ram_addr <= 16'd0;
	end
	else begin
		cur_core0_tf_push <= _cur_core0_tf_push;
		UART_data_q <= UART_data_d;
		Running <= _Running;
		openRISC_STALL <= _openRISC_STALL;
		openRISC_RSTN <= _openRISC_RSTN;
		openRISC_ram_we <= _openRISC_ram_we;
		openRISC_ram_addr <= _openRISC_ram_addr;
	end
end


always@(posedge SDK_CLK or negedge SDK_RSTN)begin
	if(~SDK_RSTN) dataSize_cnt <= 16'd0;	
	else if(CLEAN_SIGNAL) dataSize_cnt <= 16'd0;	
	else if(dataSize_cnt_en) dataSize_cnt <= dataSize_cnt + 16'd2; 
end

always@(posedge SDK_CLK or negedge SDK_RSTN)begin
	if(~SDK_RSTN) delay_cnt <= 16'd0;		
	else if(delay_cnt_en) delay_cnt <= delay_cnt + 16'd1;
	else delay_cnt <= 16'd0;	
end

//Combine two 16'bits data to one 32'bits data
assign openRISC_data_o = {DATA_0, DATA_1};

always@(posedge SDK_CLK or negedge SDK_RSTN)begin
	if(~SDK_RSTN) DATA_0 <= 16'd0;	
	else if(CLEAN_SIGNAL) DATA_0 <= 16'd0;	
	else if(LATCH_DATA_0) DATA_0 <=  SDK_FIFO_DI; 
end

always@(posedge SDK_CLK or negedge SDK_RSTN)begin
	if(~SDK_RSTN) DATA_1 <= 16'd0;	
	else if(CLEAN_SIGNAL) DATA_1 <= 16'd0;	
	else if(LATCH_DATA_1) DATA_1 <=  SDK_FIFO_DI; 
end

//Latch Flags
always@(posedge SDK_CLK or negedge SDK_RSTN)begin
	if(~SDK_RSTN) IDFlag <= 16'd0;	
	else if(CLEAN_SIGNAL) IDFlag <= 16'd0;	
	else if(LATCH_ID) IDFlag <= SDK_FIFO_DI; 
end

always@(posedge SDK_CLK or negedge SDK_RSTN)begin
	if(~SDK_RSTN) TypeFlag <= 16'd0;	
	else if(CLEAN_SIGNAL) TypeFlag <= 16'd0;	
	else if(LATCH_TYPE) TypeFlag <= SDK_FIFO_DI; 
end

always@(posedge SDK_CLK or negedge SDK_RSTN)begin
	if(~SDK_RSTN) AddrFlag <= 16'd0;	
	else if(CLEAN_SIGNAL) AddrFlag <= 16'd0;	
	else if(LATCH_ADDR) AddrFlag <= SDK_FIFO_DI; 
end

always@(posedge SDK_CLK or negedge SDK_RSTN)begin
	if(~SDK_RSTN) SizeFlag <= 16'd0;	
	else if(CLEAN_SIGNAL) SizeFlag <= 16'd0;	
	else if(LATCH_SIZE) SizeFlag <= SDK_FIFO_DI; 
end

assign core_id = IDFlag;
  
endmodule