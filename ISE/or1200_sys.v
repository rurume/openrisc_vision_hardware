module or1200_sys(
    input clk_i, //48 MHz
    input rst_n,

    // buttons
    input [15:0] SW,
    // uart interface
    input uart_rxd,
    output uart_txd,
    
    // segments
    output [31:0] LEDR,
	
	input openRISC_STALL,
	output [31:0]openRISC_pc,
	
	//For ram top module
	input			RAM_WE,
	input	[15:0] 	RAM_ADDR,
	input	[31:0]	RAM_DATA_I,
	output	[31:0]	RAM_DATA_O,
	//////////////////////////////
	//UART signals	
	output [7:0] print_data_o,
	output tf_push_o,
	//GPIO signals
	output [7:0] GPIO_o,
	input  [1:0] GPIO_i	
);

wire rst = ~rst_n;

	// **************************************************
	// Wires from OR1200 Inst Master to Conmax m0
	// **************************************************
	wire wire_iwb_ack_i;
	wire wire_iwb_cyc_o;
	wire wire_iwb_stb_o;
	wire [31:0] wire_iwb_data_i;
	wire [31:0] wire_iwb_data_o;
	wire [31:0] wire_iwb_addr_o;
	wire [3:0] wire_iwb_sel_o;
	wire wire_iwb_we_o;
	wire wire_iwb_err_i;
	wire wire_iwb_rty_i;
	
	// **************************************************
	// Wires from OR1200 Data Master to Conmax m1
	// **************************************************
	wire wire_dwb_ack_i;
	wire wire_dwb_cyc_o;
	wire wire_dwb_stb_o;
	wire [31:0] wire_dwb_data_i;
	wire [31:0] wire_dwb_data_o;
	wire [31:0] wire_dwb_addr_o;
	wire [3:0] wire_dwb_sel_o;
	wire wire_dwb_we_o;
	wire wire_dwb_err_i;
	wire wire_dwb_rty_i;
	
	// **************************************************
	// Wires from Conmax s0 to onchip_ram0
	// **************************************************
	wire wire_ram0_ack_o;
	wire wire_ram0_cyc_i;
	wire wire_ram0_stb_i;
	wire [31:0] wire_ram0_data_i;
	wire [31:0] wire_ram0_data_o;
	wire [31:0] wire_ram0_addr_i;
	wire [3:0] wire_ram0_sel_i;
	wire wire_ram0_we_i;

	// **************************************************
	// Wires from Conmax s1 to GPIO
	// **************************************************
	wire wire_gpio_ack_o;
	wire wire_gpio_cyc_i;
	wire wire_gpio_stb_i;
	wire [31:0] wire_gpio_data_i;
	wire [31:0] wire_gpio_data_o;
	wire [31:0] wire_gpio_addr_i;
	wire [3:0] wire_gpio_sel_i;
	wire wire_gpio_we_i;
	wire wire_gpio_err_o;
	wire wire_gpio_interrupt;
	
  // **************************************************
	// Wires from Conmax s2 to uart16550
	// **************************************************
	wire wire_uart_ack_o;
	wire wire_uart_cyc_i;
	wire wire_uart_stb_i;
	wire [31:0] wire_uart_data_i;
	wire [31:0] wire_uart_data_o;
	wire [31:0] wire_uart_addr_i;
	wire [3:0] wire_uart_sel_i;
	wire wire_uart_we_i;
	wire wire_uart_interrupt;

or1200_top u_or1200(
  // System
  .clk_i(clk_i), 
  .rst_i(rst), 
  .pic_ints_i({18'b0,wire_uart_interrupt,wire_gpio_interrupt}), 
  .clmode_i(2'b00),
  //added
  //pc of each core
  .openRISC_pc(openRISC_pc),
  // Instruction WISHBONE INTERFACE
  .iwb_clk_i(clk_i), 
  .iwb_rst_i(rst), 
  .iwb_ack_i(wire_iwb_ack_i), 
  .iwb_err_i(wire_iwb_err_i), 
  .iwb_rty_i(wire_iwb_rty_i), 
  .iwb_dat_i(wire_iwb_data_i),
  .iwb_cyc_o(wire_iwb_cyc_o), 
  .iwb_adr_o(wire_iwb_addr_o), 
  .iwb_stb_o(wire_iwb_stb_o), 
  .iwb_we_o(wire_iwb_we_o), 
  .iwb_sel_o(wire_iwb_sel_o), 
  .iwb_dat_o(wire_iwb_data_o),
`ifdef OR1200_WB_CAB
  .iwb_cab_o(),
`endif
//`ifdef OR1200_WB_B3
//  iwb_cti_o(), 
//  iwb_bte_o(),
//`endif
  // Data WISHBONE INTERFACE
  .dwb_clk_i(clk_i), 
  .dwb_rst_i(rst), 
  .dwb_ack_i(wire_dwb_ack_i), 
  .dwb_err_i(wire_dwb_err_i), 
  .dwb_rty_i(wire_dwb_rty_i), 
  .dwb_dat_i(wire_dwb_data_i),
  .dwb_cyc_o(wire_dwb_cyc_o), 
  .dwb_adr_o(wire_dwb_addr_o), 
  .dwb_stb_o(wire_dwb_stb_o), 
  .dwb_we_o(wire_dwb_we_o), 
  .dwb_sel_o(wire_dwb_sel_o), 
  .dwb_dat_o(wire_dwb_data_o),
`ifdef OR1200_WB_CAB
  .dwb_cab_o(),
`endif
//`ifdef OR1200_WB_B3
//  dwb_cti_o(), 
//  dwb_bte_o(),
//`endif

  // External Debug Interface
  .dbg_stall_i(openRISC_STALL), 
  .dbg_ewt_i(1'b0),  
  .dbg_lss_o(), 
  .dbg_is_o(), 
  .dbg_wp_o(), 
  .dbg_bp_o(),
  .dbg_stb_i(1'b0), 
  .dbg_we_i(1'b0),
  .dbg_adr_i(0), 
  .dbg_dat_i(0), 
  .dbg_dat_o(), 
  .dbg_ack_o(),
  
//`ifdef OR1200_BIST
//  // RAM BIST
//  mbist_si_i(), 
//  mbist_so_o(), 
//  mbist_ctrl_i(),
//`endif
  // Power Management
  .pm_cpustall_i(0),
  .pm_clksd_o(), 
  .pm_dc_gate_o(), 
  .pm_ic_gate_o(), 
  .pm_dmmu_gate_o(), 
  .pm_immu_gate_o(), 
  .pm_tt_gate_o(), 
  .pm_cpu_gate_o(), 
  .pm_wakeup_o(), 
  .pm_lvolt_o()
);

wb_conmax_top u_wb(
  .clk_i(clk_i), 
  .rst_i(rst),

  // Master 0 Interface
  .m0_data_i(wire_iwb_data_o), 
  .m0_data_o(wire_iwb_data_i), 
  .m0_addr_i(wire_iwb_addr_o), 
  .m0_sel_i(wire_iwb_sel_o), 
  .m0_we_i(wire_iwb_we_o), 
  .m0_cyc_i(wire_iwb_cyc_o),
  .m0_stb_i(wire_iwb_stb_o), 
  .m0_ack_o(wire_iwb_ack_i), 
  .m0_err_o(wire_iwb_err_i), 
  .m0_rty_o(wire_iwb_rty_i), 
//  .m0_cab_i(),

  // Master 1 Interface
  .m1_data_i(wire_dwb_data_o), 
  .m1_data_o(wire_dwb_data_i), 
  .m1_addr_i(wire_dwb_addr_o), 
  .m1_sel_i(wire_dwb_sel_o), 
  .m1_we_i(wire_dwb_we_o), 
  .m1_cyc_i(wire_dwb_cyc_o),
  .m1_stb_i(wire_dwb_stb_o), 
  .m1_ack_o(wire_dwb_ack_i), 
  .m1_err_o(wire_dwb_err_i), 
  .m1_rty_o(wire_dwb_rty_i), 
//  .m0_cab_i(),

  // Slave 0 Interface
  .s0_data_i(wire_ram0_data_o), 
  .s0_data_o(wire_ram0_data_i), 
  .s0_addr_o(wire_ram0_addr_i), 
  .s0_sel_o(wire_ram0_sel_i), 
  .s0_we_o(wire_ram0_we_i), 
  .s0_cyc_o(wire_ram0_cyc_i),
  .s0_stb_o(wire_ram0_stb_i), 
  .s0_ack_i(wire_ram0_ack_o), 
  .s0_err_i(0), 
  .s0_rty_i(0), 
  //.s0_cab_o(),

  // Slave 1 Interface
  .s1_data_i(wire_gpio_data_o), 
  .s1_data_o(wire_gpio_data_i), 
  .s1_addr_o(wire_gpio_addr_i), 
  .s1_sel_o(wire_gpio_sel_i), 
  .s1_we_o(wire_gpio_we_i), 
  .s1_cyc_o(wire_gpio_cyc_i),
  .s1_stb_o(wire_gpio_stb_i), 
  .s1_ack_i(wire_gpio_ack_o), 
  .s1_err_i(wire_gpio_err_o), 
  .s1_rty_i(0), 
  //.s1_cab_o(),
 
  // Slave 2 Interface
  .s2_data_i(wire_uart_data_o), 
  .s2_data_o(wire_uart_data_i), 
  .s2_addr_o(wire_uart_addr_i), 
  .s2_sel_o(wire_uart_sel_i), 
  .s2_we_o(wire_uart_we_i), 
  .s2_cyc_o(wire_uart_cyc_i),
  .s2_stb_o(wire_uart_stb_i), 
  .s2_ack_i(wire_uart_ack_o), 
  .s2_err_i(0), 
  .s2_rty_i(0)//, 
  //.s0_cab_o(),
  
  );
  
ram0_top u_ram0(
    .clk_i(clk_i),
    .rst_i(rst),
    
    .wb_stb_i(wire_ram0_stb_i),
    .wb_cyc_i(wire_ram0_cyc_i),
    .wb_ack_o(wire_ram0_ack_o),
    .wb_addr_i(wire_ram0_addr_i),
    .wb_sel_i(wire_ram0_sel_i),
    .wb_we_i(wire_ram0_we_i),
    .wb_data_i(wire_ram0_data_i),
    .wb_data_o(wire_ram0_data_o),
	
	//For controlling
	.openRISC_STALL(openRISC_STALL),	
	.RAM_WE(RAM_WE),
	.RAM_ADDR(RAM_ADDR),
	.RAM_DATA_I(RAM_DATA_I),
	.RAM_DATA_O(RAM_DATA_O),
	//GPIO signals
	.GPIO_o(GPIO_o),
	.GPIO_i(GPIO_i)
  );

gpio_top u_gpio(
	// WISHBONE Interface
	.wb_clk_i(clk_i), 
	.wb_rst_i(rst), 
	.wb_cyc_i(wire_gpio_cyc_i), 
	.wb_adr_i(wire_gpio_addr_i), 
	.wb_dat_i(wire_gpio_data_i), 
	.wb_sel_i(wire_gpio_sel_i), 
	.wb_we_i(wire_gpio_we_i), 
	.wb_stb_i(wire_gpio_stb_i),
	.wb_dat_o(wire_gpio_data_o), 
	.wb_ack_o(wire_gpio_ack_o), 
	.wb_err_o(wire_gpio_err_o), 
	.wb_inta_o(wire_gpio_interrupt),

//`ifdef GPIO_AUX_IMPLEMENT
//	// Auxiliary inputs interface
//	.aux_i(),
//`endif //  GPIO_AUX_IMPLEMENT

	// External GPIO Interface
	.ext_pad_i({16'b0,SW}), 
	.ext_pad_o(LEDR), 
	.ext_padoe_o()//,
//`ifdef GPIO_CLKPAD
//  .clk_pad_i()
//`endif
);


uart_top u_uart(
	//UART signals
  .print_data_o(print_data_o),
  .tf_push_o(tf_push_o),
  ///////////////////////////////////////
  .wb_clk_i(clk_i), 
  
  // Wishbone signals
  .wb_rst_i(rst), 
  .wb_adr_i(wire_uart_addr_i[4:0]), 
  .wb_dat_i(wire_uart_data_i), 
  .wb_dat_o(wire_uart_data_o), 
  .wb_we_i(wire_uart_we_i), 
  .wb_stb_i(wire_uart_stb_i), 
  .wb_cyc_i(wire_uart_cyc_i), 
  .wb_ack_o(wire_uart_ack_o), 
  .wb_sel_i(wire_uart_sel_i),
  .int_o(wire_uart_interrupt), // interrupt request

  // UART  signals
  // serial input/output
  .stx_pad_o(uart_txd), 
  .srx_pad_i(uart_rxd),

  // modem signals
  .rts_pad_o(), 
  .cts_pad_i(1'b0), 
  .dtr_pad_o(), 
  .dsr_pad_i(1'b0), 
  .ri_pad_i(1'b0), 
  .dcd_pad_i(1'b0)//,
//`ifdef UART_HAS_BAUDRATE_OUTPUT
//  .baud_o()
//`endif
  );

endmodule
