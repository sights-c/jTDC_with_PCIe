`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Xi'an Institute of Optics and Precision Mechanics of CAS 
// Engineer: Riguang-Chen
// 
// Create Date: 2024/08/23 21:48:00
// Design Name: jTDC_PCIe
// Module Name: jTDC_PCIe
// Project Name: jTDC_PCIe
// Target Devices: xc7a200tfbg484-2
// Tool Versions: 2018.3
// Description: A transplatation of jTDC into AX7203 board
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Revision 0.02 - Instantiation of xdma
// Revision 0.03 - Instantiation of axi-interface
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module jTDC_PCIe(
    // System
    input wire i_sys_clk_p,
    input wire i_sys_clk_n,
    input wire i_sys_rstn,
    output wire CLK200,
    output wire CLK400,
    output wire user_lnk_up,

    // PCIe
    input wire i_pcie_rstn,
    input wire i_pcie_refclkp, i_pcie_refclkn,
    input wire i_pcie_rxp, i_pcie_rxn,
    output wire o_pcie_txp, o_pcie_txn
);

// ---------- setup registers --------------------------------------------------
wire [31:0] statusregister;
assign statusregister [7:0]   = 8'b00000001;      //-- Firmware version
assign statusregister [13:8]  = 6'b000001;        //-- Firmware type
assign statusregister [19:14] = 6'b0;             //-- Board type Mezzanine_A
assign statusregister [25:20] = 6'b0;             //-- Board type Mezzanine_B
assign statusregister [31:26] = 6'b0;             //-- Board type Mezzanine_C

// ---------- Board IO --------------------------------------------------
IBUFDS   sys_clk_n_ibuf (
    .I               ( i_sys_clk_p       ),
    .IB              ( i_sys_clk_n       ),
    .O               ( sys_clk         )
);

IBUFDS   sys_reset_n_ibuf (
    .I               ( i_sys_rstn       ),
    .O               ( sys_rstn        )
);

// ---------- pll --------------------------------------------------
  wire locked;
  wire clkfbout;
  wire clkfbout_buf;
PLLE2_BASE #(
  .BANDWIDTH("HIGH"),  // OPTIMIZED, HIGH, LOW
  .CLKFBOUT_MULT(4),        // Multiply value for all CLKOUT, (2-64)
  .CLKFBOUT_PHASE(0.0),     // Phase offset in degrees of CLKFB, (-360.000-360.000).
  .CLKIN1_PERIOD(5.0),      // Input clock period in ns to ps resolution (i.e. 33.333 is 30 MHz).

  // CLKOUT0_DIVIDE - CLKOUT5_DIVIDE: Divide amount for each CLKOUT (1-128)
  .CLKOUT0_DIVIDE(4),
  .CLKOUT1_DIVIDE(2),

  // CLKOUT0_DUTY_CYCLE - CLKOUT5_DUTY_CYCLE: Duty cycle for each CLKOUT (0.001-0.999).
  .CLKOUT0_DUTY_CYCLE(0.5),
  .CLKOUT1_DUTY_CYCLE(0.5),

  // CLKOUT0_PHASE - CLKOUT5_PHASE: Phase offset for each CLKOUT (-360.000-360.000).
  .CLKOUT0_PHASE(0.0),
  .CLKOUT1_PHASE(0.0),

  .DIVCLK_DIVIDE(1),        // Master division value, (1-56)
  .REF_JITTER1(0.001),        // Reference input jitter in UI, (0.000-0.999).
  .STARTUP_WAIT("FALSE")    // Delay DONE until PLL Locks, ("TRUE"/"FALSE")
)
PLLE2_BASE_inst (
  // Clock Outputs: 1-bit (each) output: User configurable clock outputs
  .CLKOUT0(clkout0),   // 1-bit output: CLKOUT0
  .CLKOUT1(clkout1),   // 1-bit output: CLKOUT1

  // Feedback Clocks: 1-bit (each) output: Clock feedback ports
  .CLKFBOUT(clkfbout), // 1-bit output: Feedback clock
  .LOCKED(locked),     // 1-bit output: LOCK
  .CLKIN1(sys_clk),     // 1-bit input: Input clock

  // Control Ports: 1-bit (each) input: PLL control ports
  // .PWRDWN(),     // 1-bit input: Power-down
  // .RST(),           // 1-bit input: Reset

  // Feedback Clocks: 1-bit (each) input: Clock feedback ports
  .CLKFBIN(clkfbout_buf)    // 1-bit input: Feedback clock
);

// output buffer
BUFG clkf_buf (
  .O (clkfbout_buf),
  .I (clkfbout));

BUFG CLKOUT0_buf (
  .O   (CLK200),
  .I   (clkout0));

BUFG CLKOUT1_buf (
  .O   (CLK400),
  .I   (clkout1));

// ---------- PCIe IO --------------------------------------------------
wire pcie_refclk;
wire pcie_rstn;

// PCIe ref clock input buffer
IBUFDS_GTE2 refclk_ibuf (
    .CEB             ( 1'b0              ),
    .I               ( i_pcie_refclkp    ),
    .IB              ( i_pcie_refclkn    ),
    .O               ( pcie_refclk       ),
    .ODIV2           (                   )
);

// PCIe reset input buffer
IBUF   sys_reset_n_ibuf (
    .I               ( i_pcie_rstn       ),
    .O               ( pcie_rstn         )
);

// ---------- PCIe Interuptions --------------------------------------------------
reg [7:0] usr_irq_req;
wire [7:0] usr_irq_ack;

always @(posedge sys_clk or negedge sys_rstn) begin
    if(!sys_rstn) begin
        usr_irq_req <= 8'b0;
    end else begin
        usr_irq_req <= 8'b0;
    end
end

// ---------- AXI4 bus --------------------------------------------------
wire axi_aclk;                                            // output wire axi_aclk
wire axi_aresetn;                                      // output wire axi_aresetn

wire axi_awready;                                  // input wire m_axi_awready
wire axi_wready;                                    // input wire m_axi_wready
wire axi_bid;                                          // input wire [3 : 0] m_axi_bid
wire axi_bresp;                                      // input wire [1 : 0] m_axi_bresp
wire axi_bvalid;                                    // input wire m_axi_bvalid
wire axi_arready;                                  // input wire m_axi_arready
wire axi_rid;                                          // input wire [3 : 0] m_axi_rid
wire axi_rdata;                                      // input wire [63 : 0] m_axi_rdata
wire axi_rresp;                                      // input wire [1 : 0] m_axi_rresp
wire axi_rlast;                                      // input wire m_axi_rlast
wire axi_rvalid;                                    // input wire m_axi_rvalid
wire axi_awid;                                        // output wire [3 : 0] m_axi_awid
wire axi_awaddr;                                    // output wire [63 : 0] m_axi_awaddr
wire axi_awlen;                                      // output wire [7 : 0] m_axi_awlen
wire axi_awsize;                                    // output wire [2 : 0] m_axi_awsize
wire axi_awburst;                                  // output wire [1 : 0] m_axi_awburst
wire axi_awprot;                                    // output wire [2 : 0] m_axi_awprot
wire axi_awvalid;                                  // output wire m_axi_awvalid
wire axi_awlock;                                    // output wire m_axi_awlock
wire axi_awcache;                                  // output wire [3 : 0] m_axi_awcache
wire axi_wdata;                                      // output wire [63 : 0] m_axi_wdata
wire axi_wstrb;                                      // output wire [7 : 0] m_axi_wstrb
wire axi_wlast;                                      // output wire m_axi_wlast
wire axi_wvalid;                                    // output wire m_axi_wvalid
wire axi_bready;                                    // output wire m_axi_bready
wire axi_arid;                                        // output wire [3 : 0] m_axi_arid
wire axi_araddr;                                    // output wire [63 : 0] m_axi_araddr
wire axi_arlen;                                      // output wire [7 : 0] m_axi_arlen
wire axi_arsize;                                    // output wire [2 : 0] m_axi_arsize
wire axi_arburst;                                  // output wire [1 : 0] m_axi_arburst
wire axi_arprot;                                    // output wire [2 : 0] m_axi_arprot
wire axi_arvalid;                                  // output wire m_axi_arvalid
wire axi_arlock;                                    // output wire m_axi_arlock
wire axi_arcache;                                  // output wire [3 : 0] m_axi_arcache
wire axi_rready ;                                   // output wire m_axi_rready

// ---------- XMDA Instantiation --------------------------------------------------
xdma_0 jTDC_PCIe_xdma (
  .sys_clk(pcie_refclk),                                              // input wire sys_clk
  .sys_rst_n(pcie_rstn),                                          // input wire sys_rst_n
  .user_lnk_up(o_user_lnk_up),                                      // output wire user_lnk_up
  
  .pci_exp_txp(o_pci_exp_txp),                                      // output wire [0 : 0] pci_exp_txp
  .pci_exp_txn(o_pci_exp_txn),                                      // output wire [0 : 0] pci_exp_txn
  .pci_exp_rxp(i_pci_exp_rxp),                                      // input wire [0 : 0] pci_exp_rxp
  .pci_exp_rxn(i_pci_exp_rxn),                                      // input wire [0 : 0] pci_exp_rxn
  
  .axi_aclk(axi_aclk),                                            // output wire axi_aclk
  .axi_aresetn(axi_aresetn),                                      // output wire axi_aresetn
  
  .usr_irq_req(usr_irq_req),                                      // input wire [7 : 0] usr_irq_req
  .usr_irq_ack(usr_irq_ack),                                      // output wire [7 : 0] usr_irq_ack
  
  .m_axi_awready(axi_awready),                                  // input wire m_axi_awready
  .m_axi_wready(axi_wready),                                    // input wire m_axi_wready
  .m_axi_bid(axi_bid),                                          // input wire [3 : 0] m_axi_bid
  .m_axi_bresp(axi_bresp),                                      // input wire [1 : 0] m_axi_bresp
  .m_axi_bvalid(axi_bvalid),                                    // input wire m_axi_bvalid
  .m_axi_arready(axi_arready),                                  // input wire m_axi_arready
  .m_axi_rid(axi_rid),                                          // input wire [3 : 0] m_axi_rid
  .m_axi_rdata(axi_rdata),                                      // input wire [63 : 0] m_axi_rdata
  .m_axi_rresp(axi_rresp),                                      // input wire [1 : 0] m_axi_rresp
  .m_axi_rlast(axi_rlast),                                      // input wire m_axi_rlast
  .m_axi_rvalid(axi_rvalid),                                    // input wire m_axi_rvalid
  .m_axi_awid(axi_awid),                                        // output wire [3 : 0] m_axi_awid
  .m_axi_awaddr(axi_awaddr),                                    // output wire [63 : 0] m_axi_awaddr
  .m_axi_awlen(axi_awlen),                                      // output wire [7 : 0] m_axi_awlen
  .m_axi_awsize(axi_awsize),                                    // output wire [2 : 0] m_axi_awsize
  .m_axi_awburst(axi_awburst),                                  // output wire [1 : 0] m_axi_awburst
  .m_axi_awprot(axi_awprot),                                    // output wire [2 : 0] m_axi_awprot
  .m_axi_awvalid(axi_awvalid),                                  // output wire m_axi_awvalid
  .m_axi_awlock(axi_awlock),                                    // output wire m_axi_awlock
  .m_axi_awcache(axi_awcache),                                  // output wire [3 : 0] m_axi_awcache
  .m_axi_wdata(axi_wdata),                                      // output wire [63 : 0] m_axi_wdata
  .m_axi_wstrb(axi_wstrb),                                      // output wire [7 : 0] m_axi_wstrb
  .m_axi_wlast(axi_wlast),                                      // output wire m_axi_wlast
  .m_axi_wvalid(axi_wvalid),                                    // output wire m_axi_wvalid
  .m_axi_bready(axi_bready),                                    // output wire m_axi_bready
  .m_axi_arid(axi_arid),                                        // output wire [3 : 0] m_axi_arid
  .m_axi_araddr(axi_araddr),                                    // output wire [63 : 0] m_axi_araddr
  .m_axi_arlen(axi_arlen),                                      // output wire [7 : 0] m_axi_arlen
  .m_axi_arsize(axi_arsize),                                    // output wire [2 : 0] m_axi_arsize
  .m_axi_arburst(axi_arburst),                                  // output wire [1 : 0] m_axi_arburst
  .m_axi_arprot(axi_arprot),                                    // output wire [2 : 0] m_axi_arprot
  .m_axi_arvalid(axi_arvalid),                                  // output wire m_axi_arvalid
  .m_axi_arlock(axi_arlock),                                    // output wire m_axi_arlock
  .m_axi_arcache(axi_arcache),                                  // output wire [3 : 0] m_axi_arcache
  .m_axi_rready(axi_rready),                                    // output wire m_axi_rready
  
//   .cfg_mgmt_addr(cfg_mgmt_addr),                                  // input wire [18 : 0] cfg_mgmt_addr
//   .cfg_mgmt_write(cfg_mgmt_write),                                // input wire cfg_mgmt_write
//   .cfg_mgmt_write_data(cfg_mgmt_write_data),                      // input wire [31 : 0] cfg_mgmt_write_data
//   .cfg_mgmt_byte_enable(cfg_mgmt_byte_enable),                    // input wire [3 : 0] cfg_mgmt_byte_enable
//   .cfg_mgmt_read(cfg_mgmt_read),                                  // input wire cfg_mgmt_read
//   .cfg_mgmt_read_data(cfg_mgmt_read_data),                        // output wire [31 : 0] cfg_mgmt_read_data
//   .cfg_mgmt_read_write_done(cfg_mgmt_read_write_done),            // output wire cfg_mgmt_read_write_done
//   .cfg_mgmt_type1_cfg_reg_access(cfg_mgmt_type1_cfg_reg_access)  // input wire cfg_mgmt_type1_cfg_reg_access
);

// ---------- jTDC internal bus --------------------------------------------------
wire [31:0] D_INT;
wire [15:0] A_INT;
wire READ_INT;
wire WRITE_INT;
wire DTACK_INT;
wire CLKBUS;
wire writesignal;
wire readsignal;
wire [15:0] addressbus;
wire [31:0] databus;

// ---------- axi4_interface instatiation --------------------------------------------------
axi4_interface axi4_interface_inst(
  .sys_clk(sys_clk),
  .sys_rstn(sys_rstn),

  .CLKBUS(CLKBUS),
  .writesignal(writesignal),
  .readsignal(readsignal),
  .addressbus(addressbus),
  .databus(databus),

  .axi_aclk(axi_aclk),
  .axi_aresetn(axi_aresetn),
  
  .s_axi_awready(axi_awready),
  .s_axi_wready(axi_wready),
  .s_axi_bid(axi_bid),
  .s_axi_bresp(axi_bresp),
  .s_axi_bvalid(axi_bvalid),
  .s_axi_arready(axi_arready),
  .s_axi_rid(axi_rid),
  .s_axi_rdata(axi_rdata),
  .s_axi_rresp(axi_rresp),
  .s_axi_rlast(axi_rlast),
  .s_axi_rvalid(axi_rvalid),
  .s_axi_awid(axi_awid),
  .s_axi_awaddr(axi_awaddr),
  .s_axi_awlen(axi_awlen),
  .s_axi_awsize(axi_awsize),
  .s_axi_awburst(axi_awburst),
  .s_axi_awprot(axi_awprot),
  .s_axi_awvalid(axi_awvalid),
  .s_axi_awlock(axi_awlock),
  .s_axi_awcache(axi_awcache),
  .s_axi_wdata(axi_wdata),
  .s_axi_wstrb(axi_wstrb),
  .s_axi_wlast(axi_wlast),
  .s_axi_wvalid(axi_wvalid),
  .s_axi_bready(axi_bready),
  .s_axi_arid(axi_arid),
  .s_axi_araddr(axi_araddr),
  .s_axi_arlen(axi_arlen),
  .s_axi_arsize(axi_arsize),
  .s_axi_arburst(axi_arburst),
  .s_axi_arprot(axi_arprot),
  .s_axi_arvalid(axi_arvalid),
  .s_axi_arlock(axi_arlock),
  .s_axi_arcache(axi_arcache),
  .s_axi_rready(axi_rready)
);

// ---------- axi4_interface instatiation --------------------------------------------------
bus_interface_vfb6 BUS_INT (
  .board_databus(D_INT),
  .board_address(A_INT),
  .board_read(READ_INT),
  .board_write(WRITE_INT),
  .board_dtack(DTACK_INT),
  .CLK(CLKBUS),
  .statusregister(statusregister),
  .internal_databus(databus),
  .internal_address(addressbus),
  .internal_read(readsignal),
  .internal_write(writesignal)
);

endmodule