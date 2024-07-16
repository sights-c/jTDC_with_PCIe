`default_nettype wire
//////////////////////////////////////////////////////////////////////////////////
//                                                                             
//  Company: Xi'an Institute of Optics and Precision Mechanics of CAS
//  Engineer: Ri-Guang Chen                                                     
//                                                                                                                                                         
//  Sample implementation of jTDC using Artix-7 on
//  Alinx ax7203 board with LVDS inputs
//                                                                                                                                                         
//////////////////////////////////////////////////////////////////////////////////

module  jTDC_PCIe #(
	// Basic Setup
	parameter Board_ID 			= 18'h7203,
	parameter fw 				= 8'h22,

	parameter resolution 		= 2,	//readout every second carry step
	parameter bits 				= 96,	//empirical value for resolution=2 on VFB6
	parameter encodedbits 		= 9,	//includes hit bit

	parameter fifocounts 		= 15,	//max event size: (fifocounts+1)*1024-150;

	parameter tdc_channels 		= 32,	//number of tdc channels (max 100, see mapping below)
	parameter scaler_channels 	= 32,	//number of scaler channels

	parameter PCIE_LANES 		= 1,
	parameter AXI_AWIDTH   		= 64,
	parameter AXI_DWIDTH   		= 64,
	parameter AXI_IDWIDTH  		= 4
	)(
	input	logic 					brd_clkp,
	input	logic 					brd_clkn,
	input	logic 					brd_rst_n,

	input	logic 					pcie_refclkp,
	input	logic 					pcie_refclkn,
	input	logic 					pcie_rst_n,
	input   logic [PCIE_LANES-1:0]	pcie_rxp, 
	input   logic [PCIE_LANES-1:0]	pcie_rxn,
    output  logic [PCIE_LANES-1:0]	pcie_txp, 
	output  logic [PCIE_LANES-1:0]	pcie_txn,

	output	logic [3:0] 			USER_LED,
	input	logic					NIM_IN,
	output	logic					NIM_OUT,
	
	input	logic [63:0]			AFE_PIN
);
	genvar i;





	//-----------------------------------------------------------------------------
	//-- IO cards Setup for ax7203 board --------------------------------------------
	//-----------------------------------------------------------------------------

	logic [31:0]	LVDS_IN; 
	mez_lvds_in lvds_a_in (.MEZ(AFE_PIN[63:0]),.data(LVDS_IN));





	//-----------------------------------------------------------------------------
	//-- CLK Setup for ax7203(Artix - 7) ---------------------------------------------------
	//-----------------------------------------------------------------------------

	logic			sys_clk;
	logic			CLKBUS;
	logic			CLK200;
	logic			CLK400;
	IBUFDS sys_clk_ibufgds
    (
    .O	(sys_clk),
    .I	(brd_clkp),
    .IB	(brd_clkn)
    );
	pll_ax7203_400 PLL_TDC (
		.CLK_IN		(sys_clk),
		.CLK1		(CLKBUS), 
		.CLK2		(CLK200),
		.CLK4		(CLK400));





	//---------------------------------------------------------------------------------
	//-- PCIe Setup for ax7203 board
	//---------------------------------------------------------------------------------
	logic   					pcie_refclk;
    logic   					pcie_rst_n_buf;

	logic                       axi_aclk;
	logic                       axi_aresetn;

	logic                       axi_awready;
	logic                       axi_awvalid;
	logic [    AXI_AWIDTH-1:0]  axi_awaddr;
	logic [               7:0]  axi_awlen;
	logic [   AXI_IDWIDTH-1:0]  axi_awid;

	logic                       axi_wready;
	logic                       axi_wvalid;
	logic                       axi_wlast;
	logic [    AXI_DWIDTH-1:0]  axi_wdata;
	logic [(AXI_DWIDTH/8)-1:0]  axi_wstrb;

	logic                       axi_bready;
	logic                       axi_bvalid;
	logic [   AXI_IDWIDTH-1:0]  axi_bid;
	logic [               1:0]  axi_bresp;

	logic                       axi_arready;
	logic                       axi_arvalid;
	logic [    AXI_AWIDTH-1:0]  axi_araddr;
	logic [               7:0]  axi_arlen;
	logic [   AXI_IDWIDTH-1:0]  axi_arid;

	logic                       axi_rready;
	logic                       axi_rvalid;
	logic                       axi_rlast;
	logic [    AXI_DWIDTH-1:0]  axi_rdata;
	logic [   AXI_IDWIDTH-1:0]  axi_rid;
	logic [               1:0]  axi_rresp;

IBUFDS_GTE2 refclk_ibuf (
	.CEB    (1'b0),
	.I      (pcie_refclkp),
	.IB     (pcie_refclkn),
	.O      (pcie_refclk),
	.ODIV2  ()
);

// pcie common reset input buffer ----------------------------------------------
IBUF   pcie_reset_n_ibuf (
	.I      (pcie_rst_n),
	.O      (pcie_rst_n_buf)
);

xdma_0 #(
	)
	xdma_0_inst (
	// board interface
	.sys_clk			    (pcie_refclk),          // input wire sys_clk
	.sys_rst_n			    (pcie_rst_n_buf),           // input wire sys_rst_n
	.user_lnk_up			(USER_LED[0]),			// output wire user_lnk_up

	// msi configuration
	.usr_irq_req			(   1'h0    ),			// input wire [0 : 0] usr_irq_req
	.usr_irq_ack			(           ),          // output wire [0 : 0] usr_irq_ack

	// data channel
	.pci_exp_txp			(pcie_txp),				// output wire [0 : 0] pci_exp_txp
	.pci_exp_txn			(pcie_txn),				// output wire [0 : 0] pci_exp_txn
	.pci_exp_rxp			(pcie_rxp),				// input wire [0 : 0] pci_exp_rxp
	.pci_exp_rxn			(pcie_rxn),				// input wire [0 : 0] pci_exp_rxn

	// axi configuration
	.axi_aclk			    (axi_aclk),			    // output wire axi_aclk
	.axi_aresetn			(axi_aresetn),			// output wire axi_aresetn

	// axi aw interface
	.m_axi_awready		    (axi_awready),			// input wire m_axi_awready
	.m_axi_awid			    (axi_awid),		    	// output wire [3 : 0] m_axi_awid
	.m_axi_awaddr			(axi_awaddr),			// output wire [63 : 0] m_axi_awaddr
	.m_axi_awlen			(axi_awlen),			// output wire [7 : 0] m_axi_awlen
	.m_axi_awvalid		    (axi_awvalid),			// output wire m_axi_awvalid
	.m_axi_awsize			(           ),			// output wire [2 : 0] m_axi_awsize
	.m_axi_awburst			(           ),			// output wire [1 : 0] m_axi_awburst
	.m_axi_awprot			(           ),			// output wire [2 : 0] m_axi_awprot
	.m_axi_awlock			(           ),			// output wire m_axi_awlock
	.m_axi_awcache			(           ),			// output wire [3 : 0] m_axi_awcache

	// axi w interface
	.m_axi_wready			(axi_wready),			// input wire m_axi_wready
	.m_axi_wvalid			(axi_wvalid),			// output wire m_axi_wvalid
	.m_axi_wdata			(axi_wdata),			// output wire [63 : 0] m_axi_wdata
	.m_axi_wlast			(axi_wlast),			// output wire m_axi_wlast
	.m_axi_wstrb			(axi_wstrb),			// output wire [7 : 0] m_axi_wstrb

	// axi b interface
	.m_axi_bvalid			(axi_bvalid),			// input wire m_axi_bvalid
	.m_axi_bready			(axi_bready),			// output wire m_axi_bready
	.m_axi_bid			    (axi_bid),			    // input wire [3 : 0] m_axi_bid
	.m_axi_bresp			(axi_bresp),			// input wire [1 : 0] m_axi_bresp

	// axi ar interface
	.m_axi_arready		    (axi_arready),			// input wire m_axi_arready
	.m_axi_arvalid		    (axi_arvalid),			// output wire m_axi_arvalid
	.m_axi_araddr			(axi_araddr),			// output wire [63 : 0] m_axi_araddr
	.m_axi_arlen			(axi_arlen),			// output wire [7 : 0] m_axi_arlen
	.m_axi_arid			    (axi_arid),		    	// output wire [3 : 0] m_axi_arid
	.m_axi_arsize			(           ),			// output wire [2 : 0] m_axi_arsize
	.m_axi_arburst			(           ),			// output wire [1 : 0] m_axi_arburst
	.m_axi_arprot			(           ),			// output wire [2 : 0] m_axi_arprot
	.m_axi_arlock			(           ),			// output wire m_axi_arlock
	.m_axi_arcache			(           ),			// output wire [3 : 0] m_axi_arcache

	// axi r interface
	.m_axi_rready			(axi_rready),			// output wire m_axi_rready
	.m_axi_rvalid			(axi_rvalid),			// input wire m_axi_rvalid
	.m_axi_rlast			(axi_rlast),			// input wire m_axi_rlast
	.m_axi_rdata			(axi_rdata),			// input wire [63 : 0] m_axi_rdata
	.m_axi_rid			    (axi_rid),		    	// input wire [3 : 0] m_axi_rid
	.m_axi_rresp			(axi_rresp)             // input wire [1 : 0] m_axi_rresp
);





	//---------------------------------------------------------------------------------
	//-- AXI-BUS Setup for ax7203 board (res. addr: h0000, h0004, h0008, h0010, h0014) --
	//---------------------------------------------------------------------------------

	logic [31:0]	statusregister;
	logic [31:0]	databus;
	logic [15:0]	addressbus;
	logic 			readsignal;
	logic 			writesignal;

	assign statusregister [7:0]   = 8'b00000001;	//-- Firmware version
	assign statusregister [13:8]  = 6'b000001;		//-- Firmware type
	//-- For ax7203 boards
	assign statusregister [31:14] = Board_ID;				//-- Board type


	bus_interface_axi BUS_INT (
		.*
	);





	//-----------------------------------------------------------------------------
	//-- AXI Control Register A ---------------------------------------------------
	//-----------------------------------------------------------------------------

	(* KEEP = "true" *) logic [31:0] config_register_A;
	rw_register #(.myaddress(16'h0020)) VME_CONFIG_REGISTER_A ( 
		.databus		(databus),
		.addressbus		(addressbus),
		.readsignal		(readsignal),
		.writesignal	(writesignal),
		.CLK			(CLKBUS),
		.registerbits	(config_register_A)
	);

	logic [4:0]		geoid 				= config_register_A[4:0];
	logic 			dutycycle 			= config_register_A[5];
	logic 			edgechoice 			= config_register_A[6];
	logic 			tdc_trigger_select	= config_register_A[7];
	logic [23:0]	clock_limit 		= config_register_A[31:8];





	//-----------------------------------------------------------------------------
	//-- AXI Control Register B ---------------------------------------------------
	//-----------------------------------------------------------------------------

	(* KEEP = "TRUE" *) logic [31:0] config_register_B;
	rw_register #(.myaddress(16'h0028))	VME_CONFIG_REGISTER_B ( 
		.databus		(databus),
		.addressbus		(addressbus),
		.writesignal	(writesignal),
		.readsignal		(readsignal),
		.CLK			(CLKBUS),
		.registerbits	(config_register_B)
	); 
	
	logic [8:0]	busyshift 				= config_register_B[8:0];
	logic 		stop_counting_on_busy 	= config_register_B[9];
	logic [4:0] busyextend 				= config_register_B[15:11];
	logic [3:0] hightime 				= config_register_B[19:16];
	logic [3:0] deadtime 				= config_register_B[23:20];
	logic [5:0] trigger_on				= config_register_B[29:24];
	logic		disable_external_latch 	= config_register_B[30];
	logic		fake_mode 				= config_register_B[31];





	//-----------------------------------------------------------------------------
	//-- AXI Trigger Register -----------------------------------------------------
	//-----------------------------------------------------------------------------

	logic [7:0]		iFW 	= fw;
	logic [7:0]		iCH 	= tdc_channels;
	logic [7:0]		iBIT 	= encodedbits-1;	//the hit-bit is not pushed into the fifo
	logic [7:0]		iM 		= 8'h34;
	logic [31:0]	trigger_register_wire;

	toggle_register #(.myaddress(16'h0024)) VME_TRIGGER_REGISTER (
		.databus		(databus),
		.addressbus		(addressbus),
		.writesignal	(writesignal),
		.readsignal		(readsignal),
		.CLK			(CLKBUS),
		.info			({iCH,iBIT,iM,iFW}),
		.registerbits	(trigger_register_wire)
	); 

	//cross clock domain
	logic [31:0]	trigger_register;
	always_ff@(posedge CLK200) begin
		trigger_register <= trigger_register_wire;
	end

	//-- toggle bit 0: tdc_reset, make tdc_reset multiple cycles long
	logic 		tdc_reset_start 	= trigger_register[0];
	logic [3:0]	tdc_reset_counter 	= 4'b0000;
	logic		tdc_reset;
	logic		tdc_reset_buffer;
	always_ff@(posedge CLKBUS) begin
		tdc_reset <= tdc_reset_buffer;
		if (tdc_reset_counter == 4'b0000)
		begin
			tdc_reset_buffer <= 1'b0;
			if (tdc_reset_start == 1'b1) tdc_reset_counter <= 4'b1111;
		end else begin
			tdc_reset_buffer <= 1'b1;
			tdc_reset_counter <= tdc_reset_counter - 1;
		end
	end
   
	//-- toggle bit 1: axi_counter_reset
	logic	axi_counter_reset;
 	datapipe #(.data_width(1),.pipe_steps(2)) counter_reset_pipe ( 
		.data		(trigger_register[1]),
		.piped_data	(axi_counter_reset),
		.CLK		(CLK200));  

	//-- toggle bit 2: axi_counter_latch
	logic	axi_counter_latch;
	datapipe #(.data_width(1),.pipe_steps(1)) counter_latch_pipe ( 
		.data		(trigger_register[2]),
		.piped_data	(axi_counter_latch),
		.CLK		(CLK200));

	//-- toggle bit 3: output_reset
	logic	output_reset = trigger_register[3];

	//-- toggle bit 6: generate fake data input for busyshift measurement
	logic	fake_data;
	signal_clipper fake_data_clip (
		.CLK			(CLK200),
		.sig			(trigger_register[6]),
		.clipped_sig	(fake_data)
	);





	//-----------------------------------------------------------------------------
	//-- Enable Register ----------------------------------------------------------
	//-----------------------------------------------------------------------------

	(* KEEP = "TRUE" *) logic [31:0] enable_register;
	rw_register #(.myaddress(16'h2000)) VME_ENABLE_REGISTER ( 
		.databus		(databus),
		.addressbus		(addressbus),
		.writesignal	(writesignal),
		.readsignal		(readsignal),
		.CLK			(CLKBUS),
		.registerbits	(enable_register[31:0])); 





	//-----------------------------------------------------------------------------
	//-- Busy & Latch -------------------------------------------------------------
	//-----------------------------------------------------------------------------

	logic raw_busy;
	logic latch;
	logic busy;
	logic counter_latch;
	logic counter_reset;

	//the leading edge of the "busy & latch" signal is the actual latch, which is used only to latch the input scaler
	//while the "busy & latch" signal is asserted, the input scaler will not count (if stop_counting_on_busy is set)
	leading_edge_extractor LATCH_EXTRACTOR (
		.sig				(NIM_IN), 
		.CLK				(CLK200), 
		.unclipped_extend	(busyextend), 
		.clipped_sig		(latch), 
		.unclipped_sig		(raw_busy)
	);
	always_ff@(posedge CLK200) begin
		busy <= stop_counting_on_busy & raw_busy;
		counter_latch <= axi_counter_latch | (latch & ~disable_external_latch);
		counter_reset <= axi_counter_reset;
	end





	//-----------------------------------------------------------------------------
	//-- Map Inputs To 33 TDC Channels -------------------------------------------
	//-----------------------------------------------------------------------------

	logic [32:0] tdc_enable;
	logic [32:0] tdc_channel;
	
	assign tdc_channel[0] 		= NIM_IN;
	assign tdc_enable[0] 		= 1'b1;

	assign tdc_enable[32:1] 	= enable_register[31:0];
	assign tdc_channel[32:1] 	= (edgechoice == 1'b0) ? LVDS_IN[31:0] : ~LVDS_IN[31:0];





	//-----------------------------------------------------------------------------
	//-- Sampling -----------------------------------------------------------------
	//-----------------------------------------------------------------------------

	logic [32:0] 							tdc_hits;
	logic [tdc_channels-1:0] 				scaler_hits;
	logic [tdc_channels*encodedbits-1:0] 	tdc_data_codes;

	generate
		for (i=0; i < tdc_channels; i=i+1) begin : INPUTSTAGE	
			logic [bits-1:0] sample;
			carry_sampler_artix7 #(.bits(bits),.resolution(resolution)) SAMPLER (
				.d			(~tdc_channel[i]), 
				.q			(sample),
				.CLK		(CLK400));

			logic scaler;
			encode_96bit_pattern #(.encodedbits(encodedbits)) ENCODE (
				.edgechoice	(1'b1), //sending the signal inverted into the chain gives better results
				.d			(sample),
				.enable		(tdc_enable[i]),
				.CLK400		(CLK400),
				.CLK200		(CLK200),
				.code		(tdc_data_codes[(i+1)*encodedbits-1:i*encodedbits]),
				.tdc_hit	(tdc_hits[i]),
				.scaler_hit	(scaler));

			//fake scaler hit for busyshift determination
			logic scaler_buffer;
			if (i==1) begin
				always_ff@(posedge CLK200)
				begin
					if (fake_mode == 1'b1) begin
						scaler_buffer <= fake_data;
					end else begin
						scaler_buffer <= scaler;
					end
				end
			end else begin
				always_ff@(posedge CLK200)
				begin
					scaler_buffer <= scaler;
				end
			end
			assign scaler_hits[i] = scaler_buffer;

		end
	endgenerate

	//unused channels
	assign tdc_hits[32:tdc_channels] = 'b0;





	//-----------------------------------------------------------------------------
	//-- Generate Trigger Outputs -------------------------------------------------
	//-----------------------------------------------------------------------------

	logic [31:0]	trigger_hits;
	logic [7:0]		trigger_first_or;

	//only use LVDS hits (data channels) for trigger output
	assign trigger_hits[31:0] = tdc_hits[32:1];

	generate
		for (i=0; i < 8; i=i+1) begin : TRIGGER_ORHITS
			assign trigger_first_or[i] = |trigger_hits[i*4+3:i*4]; 
		end
	endgenerate

	logic [7:0]		trigger_out_0;
	logic [1:0]		trigger_out_1;
	logic			trigger_out_buf;
	logic			trigger_out;

	always_ff@(posedge CLK200)
	begin
		// generate trigger output signal
		trigger_out_0 <= trigger_first_or;
		trigger_out_1[0] <= |trigger_out_0[ 3: 0];
		trigger_out_1[1] <= |trigger_out_0[ 7: 4];
		trigger_out_buf <= |trigger_out_1[1:0];
		trigger_out <= (trigger_on[0]) ? trigger_out_buf : 1'b0;
	end




	//-----------------------------------------------------------------------------
	//-- jTDC ---------------------------------------------------------------------
	//-----------------------------------------------------------------------------
	
	logic data_fifo_readrequest;
	logic event_fifo_readrequest;
	logic [31:0] data_fifo_value;
	logic [31:0] event_fifo_value;

	jTDC_core #(
		.tdc_channels			(tdc_channels),
		.encodedbits			(encodedbits),
		.fifocounts				(fifocounts)
	) 
	jTDC (
		.tdc_hits				(tdc_hits), 
		.tdc_data_codes			(tdc_data_codes), 
		.tdc_trigger_select		(tdc_trigger_select), 
		.tdc_reset				(tdc_reset), 
		.clock_limit			(clock_limit), 
		.geoid					(geoid), 
		.iBIT					(iBIT), 
		.CLK200					(CLK200),
		.CLKBUS					(CLKBUS), 
		.event_fifo_readrequest	(event_fifo_readrequest),
		.data_fifo_readrequest	(data_fifo_readrequest), 
		.event_fifo_value		(event_fifo_value), 
		.data_fifo_value		(data_fifo_value) );

	readonly_register_with_readtrigger #(.myaddress(16'h8888)) EVENT_FIFO_READOUT (
		.databus				(databus), 
		.addressbus				(addressbus), 
		.readsignal				(readsignal), 
		.readtrigger			(event_fifo_readrequest), 
		.CLK					(CLKBUS), 
		.registerbits			(event_fifo_value));

	readonly_register_with_readtrigger #(.myaddress(16'h4444)) DATA_FIFO_READOUT (
		.databus				(databus), 
		.addressbus				(addressbus), 
		.readsignal				(readsignal), 
		.readtrigger			(data_fifo_readrequest), 
		.CLK					(CLKBUS), 
		.registerbits			(data_fifo_value));





	//-----------------------------------------------------------------------------
	//-- SCALER -------------------------------------------------------------------
	//-----------------------------------------------------------------------------

	generate
		
		if (scaler_channels > 0)
		begin

			//to reduce routing of the global addressbus, I implemented an internal
			//128 addr mux for the input scaler. They will use only one external addr,
			//each read request to the clock_counter_reg resets the scaler_addr and
			//each read request to the input_counter_reg increments the scaler_addr
			//furthermore, the input_counter_reg can be addressed by 128 consecutive
			//addresses (addressbus is masked), so the external readout can be performed
			//as usual, the input scalers just need to be read out in order
			logic 			scaler_readout_addr_reset;
			logic 			scaler_readout_addr_next;
			logic [6:0]		scaler_readout_addr; 
			logic [31:0]	scaler_readout_pipe_addr; 
			logic [31:0]	muxed_counts;
	
			//busyshift
			logic [127:0]	shifted_hits;
			BRAMSHIFT_512 #(
				.shift_bitsize(9),
				.width(4),
				.input_pipe_steps(1),
				.output_pipe_steps(1)
			) 
			BRAM_BUSYSHIFT (
				.d		({'b0,scaler_hits}), 
				.q		(shifted_hits), 
				.CLK	(CLK200), 
				.shift	(busyshift));

			//input counter
			for (i=0; i < 128; i=i+1) begin : INPUT_HITS_COUNTER

				if (i<scaler_channels && i<tdc_channels) begin
				
					//take sample[0] (re-inverted) for dutycycle measurement
					(* KEEP = "true" *) logic dutyline = ~INPUTSTAGE[i].sample[0];

					logic busycount;
					logic busycount_0;
					logic busycount_1;
					logic input_buffer;
					always_ff@(posedge CLK200) begin
						input_buffer <= dutyline;
						busycount_0 <= shifted_hits[i] && ~busy;
						busycount_1 <= busycount_0;
						if (dutycycle == 1'b0) busycount <= busycount_1;
						else busycount <= input_buffer;
					end

					logic [31:0] input_counts;
					dsp_multioption_counter #(.clip_count(0)) INPUT_COUNTER (
						.countClock(CLK200), 
						.count(busycount),
						.reset(counter_reset),
						.countout(input_counts));

					logic [31:0] input_latched_counts;
					datalatch #(.latch_pipe_steps(1)) INPUT_COUNTER_DATALATCH  (
						.CLK(CLK200),
						.latch(counter_latch),
						.data(input_counts),
						.latched_data(input_latched_counts));

					//use the scaler_readout_addr to mux the correct counter to the readout register
					//since the source data is latched, the ucf constraint CROSSCLOCK is giving this mux 50ns to settle
					assign muxed_counts = (scaler_readout_addr == i) ? input_latched_counts : 32'b0;
					
				end 
				
			end


			//reference clock counter (to be able to calculate rates)
			logic [31:0] pureclkcounts;
			dsp_multioption_counter #(.clip_count(0)) PURE_CLOCK_COUNTER (
				.countClock		(CLK200), 
				.count			(!busy), 
				.reset			(counter_reset),  
				.countout		(pureclkcounts));

			logic [31:0] clklatch;
			datalatch #(.latch_pipe_steps(1)) CLOCK_COUNTER_DATALATCH  (
				.CLK			(CLK200),
				.latch			(counter_latch),
				.data			(pureclkcounts),
				.latched_data	(clklatch));

			//read of this register resets the scaler_readout_addr
			readonly_register_with_readtrigger #(.myaddress(16'h0044)) CLOCK_COUNTER_READOUT ( 
				.databus		(databus),
				.addressbus		(addressbus),
				.readsignal		(readsignal),
				.readtrigger	(scaler_readout_addr_reset),
				.CLK			(CLKBUS),
				.registerbits	(clklatch));
			
			//increment scaler_readout_addr on the negedge of next (=read) 
			//to keep the muxed value stable during read
			dsp_multioption_counter #(.clip_count(1),.clip_reset(1)) SCALER_READOUT_ADDR_INC (
				.countClock		(CLKBUS), 
				.count			(~scaler_readout_addr_next), 
				.reset			(scaler_readout_addr_reset),  
				.countout		(scaler_readout_pipe_addr));

			logic [31:0] muxed_counts_pipe;
			always@(posedge CLKBUS) begin
				muxed_counts_pipe <= muxed_counts;
				scaler_readout_addr <= scaler_readout_pipe_addr[6:0];
			end

			//each read of this register increments the scaler_readout_addr
			readonly_register_with_readtrigger #(.myaddress(16'h4000))  INPUT_COUNTER_READOUT ( 
				.databus		(databus),
				.addressbus		({addressbus[15:9],9'b0}), //from these 9 bits only 7 are usable
				.readsignal		(readsignal),
				.readtrigger	(scaler_readout_addr_next),
				.CLK			(CLKBUS),
				.registerbits	(muxed_counts_pipe));

		end
	endgenerate






	//-----------------------------------------------------------------------------
	//-- NIM Outputs --------------------------------------------------------------
	//-----------------------------------------------------------------------------
	
	logic trigger_output;
	output_shaper TRIGGER_SHAPER_0 (
		.d			(trigger_out),
		.hightime	(hightime),
		.deadtime	(deadtime),
		.CLK		(CLK200),
		.pulse		(trigger_output),
		.reset		(output_reset));

	assign NIM_OUT 			= 0;
	assign NIM_OUT 			= trigger_output;

	assign USER_LED[3:1] 	= 3'b111;
	
endmodule