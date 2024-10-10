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
    input   wire i_sys_clk_p,
    input   wire i_sys_clk_n,
    input   wire i_sys_rstn,
    output  wire CLK200,
    output  wire CLK400,
    output  wire user_lnk_up,

    // PCIe
    input   wire i_pcie_rstn,
    input   wire i_pcie_refclkp, i_pcie_refclkn,
    input   wire i_pcie_rxp, i_pcie_rxn,
    output  wire o_pcie_txp, o_pcie_txn
);

// ---------- setup registers --------------------------------------------------
wire [31:0] statusregister;
assign statusregister [ 7: 0] = 8'b00000001;      //-- Firmware version
assign statusregister [13: 8] = 6'b000001;        //-- Firmware type
assign statusregister [19:14] = 6'b0;             //-- Board type Mezzanine_A
assign statusregister [25:20] = 6'b0;             //-- Board type Mezzanine_B
assign statusregister [31:26] = 6'b0;             //-- Board type Mezzanine_C

// ---------- Board IO --------------------------------------------------
IBUFDS   sys_clk_n_ibuf (
    .I  ( i_sys_clk_p  ),
    .IB ( i_sys_clk_n  ),
    .O  ( sys_clk      )
);

IBUFDS   sys_reset_n_ibuf (
    .I  ( i_sys_rstn   ),
    .O  ( sys_rstn     )
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
    .CEB    ( 1'b0              ),
    .I      ( i_pcie_refclkp    ),
    .IB     ( i_pcie_refclkn    ),
    .O      ( pcie_refclk       ),
    .ODIV2  (                   )
);

// PCIe reset input buffer
IBUF   sys_reset_n_ibuf (
    .I  ( i_pcie_rstn       ),
    .O  ( pcie_rstn         )
);

// ---------- PCIe Interuptions --------------------------------------------------
reg   [7:0] usr_irq_req;
wire  [7:0] usr_irq_ack;

always @(posedge sys_clk or negedge sys_rstn) begin
    if(!sys_rstn) begin
        usr_irq_req <= 8'b0;
    end else begin
        usr_irq_req <= 8'b0;
    end
end

// ---------- AXI4Lite bus --------------------------------------------------
wire          axi_aclk;             // output wire axi_aclk
wire          axi_aresetn;          // output wire axi_aresetn

wire [31: 0]  axil_awaddr;          // output wire [31 : 0] m_axil_awaddr
wire [ 2: 0]  axil_awprot;          // output wire [2 : 0] m_axil_awprot
wire          axil_awvalid;         // output wire m_axil_awvalid
wire          axil_awready;         // input wire m_axil_awready
wire [31: 0]  axil_wdata;           // output wire [31 : 0] m_axil_wdata
wire [ 3: 0]  axil_wstrb;           // output wire [3 : 0] m_axil_wstrb
wire          axil_wvalid;          // output wire m_axil_wvalid
wire          axil_wready;          // input wire m_axil_wready
wire          axil_bvalid;          // input wire m_axil_bvalid
wire [ 1: 0]  axil_bresp;           // input wire [1 : 0] m_axil_bresp
wire          axil_bready;          // output wire m_axil_bready
wire [31: 0]  axil_araddr;          // output wire [31 : 0] m_axil_araddr
wire [ 2: 0]  axil_arprot;          // output wire [2 : 0] m_axil_arprot
wire          axil_arvalid;         // output wire m_axil_arvalid
wire          axil_arready;         // input wire m_axil_arready
wire [31: 0]  axil_rdata;           // input wire [31 : 0] m_axil_rdata
wire [ 1: 0]  axil_rresp;           // input wire [1 : 0] m_axil_rresp
wire          axil_rvalid;          // input wire m_axil_rvalid
wire          axil_rready;          // output wire m_axil_rready

// ---------- XMDA Instantiation --------------------------------------------------
xdma_0 jTDC_PCIe_xdma (
  .sys_clk(pcie_refclk),            // input wire sys_clk
  .sys_rst_n(pcie_rstn),            // input wire sys_rst_n
  .user_lnk_up(o_user_lnk_up),      // output wire user_lnk_up
  
  .pci_exp_txp(o_pci_exp_txp),      // output wire [0 : 0] pci_exp_txp
  .pci_exp_txn(o_pci_exp_txn),      // output wire [0 : 0] pci_exp_txn
  .pci_exp_rxp(i_pci_exp_rxp),      // input wire [0 : 0] pci_exp_rxp
  .pci_exp_rxn(i_pci_exp_rxn),      // input wire [0 : 0] pci_exp_rxn
  
  .axi_aclk(axi_aclk),              // output wire axi_aclk
  .axi_aresetn(axi_aresetn),        // output wire axi_aresetn
  
  .usr_irq_req(usr_irq_req),        // input wire [7 : 0] usr_irq_req
  .usr_irq_ack(usr_irq_ack),        // output wire [7 : 0] usr_irq_ack

  .m_axil_awaddr(axil_awaddr),      // output wire [31 : 0] m_axil_awaddr
  .m_axil_awprot(axil_awprot),      // output wire [2 : 0] m_axil_awprot
  .m_axil_awvalid(axil_awvalid),    // output wire m_axil_awvalid
  .m_axil_awready(axil_awready),    // input wire m_axil_awready

  .m_axil_wdata(axil_wdata),        // output wire [31 : 0] m_axil_wdata
  .m_axil_wstrb(axil_wstrb),        // output wire [3 : 0] m_axil_wstrb
  .m_axil_wvalid(axil_wvalid),      // output wire m_axil_wvalid
  .m_axil_wready(axil_wready),      // input wire m_axil_wready

  .m_axil_bvalid(axil_bvalid),      // input wire m_axil_bvalid
  .m_axil_bresp(axil_bresp),        // input wire [1 : 0] m_axil_bresp
  .m_axil_bready(axil_bready),      // output wire m_axil_bready

  .m_axil_araddr(axil_araddr),      // output wire [31 : 0] m_axil_araddr
  .m_axil_arprot(axil_arprot),      // output wire [2 : 0] m_axil_arprot
  .m_axil_arvalid(axil_arvalid),    // output wire m_axil_arvalid
  .m_axil_arready(axil_arready),    // input wire m_axil_arready

  .m_axil_rdata(axil_rdata),        // input wire [31 : 0] m_axil_rdata
  .m_axil_rresp(axil_rresp),        // input wire [1 : 0] m_axil_rresp
  .m_axil_rvalid(axil_rvalid),      // input wire m_axil_rvalid
  .m_axil_rready(axil_rready),      // output wire m_axil_rready
);

// ---------- jTDC internal bus --------------------------------------------------
wire          CLKBUS;
wire          writesignal;
wire          readsignal;
wire [15: 0]  addressbus;
wire [31: 0]  databus;

// ---------- axi4_interface instatiation --------------------------------------------------
axi4lite_interface axi4lite_interface_inst(
  .sys_clk(sys_clk),
  .sys_rstn(sys_rstn),

  .statusregister(statusregister),
  .writesignal(writesignal),
  .readsignal(readsignal),
  .addressbus(addressbus),
  .databus(databus),

  .axi_aclk(axi_aclk),
  .axi_aresetn(axi_aresetn),
  
  .s_axil_awaddr(axil_awaddr),
  .s_axil_awprot(axil_awprot),
  .s_axil_awvalid(axil_awvalid),
  .s_axil_awready(axil_awready),
  .s_axil_wdata(axil_wdata),
  .s_axil_wstrb(axil_wstrb),
  .s_axil_wvalid(axil_wvalid),
  .s_axil_wready(axil_wready),
  .s_axil_bvalid(axil_bvalid),
  .s_axil_bresp(axil_bresp),
  .s_axil_bready(axil_bready),
  .s_axil_araddr(axil_araddr),
  .s_axil_arprot(axil_arprot),
  .s_axil_arvalid(axil_arvalid),
  .s_axil_arready(axil_arready),
  .s_axil_rdata(axil_rdata),
  .s_axil_rresp(axil_rresp),
  .s_axil_rvalid(axil_rvalid),
  .s_axil_rready(axil_rready),
);
endmodule