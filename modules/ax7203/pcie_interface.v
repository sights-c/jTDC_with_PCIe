module pcie_interface #(
    parameter base_addr = 16'h7203,
    parameter lanes = 4
)(
    input   wire                i_pcie_refclkp,
    input   wire                i_pcie_refclkn,
    input   wire [lanes-1:0]    i_pci_exp_rxn,
    input   wire [lanes-1:0]    i_pci_exp_rxp,
    output  wire [lanes-1:0]    o_pci_exp_txn,
    output  wire [lanes-1:0]    o_pci_exp_txp,
    input   wire                i_pcie_rstn,
    output  wire                user_lnk_up,

    output	wire                writesignal,
    output	wire                readsignal,
    output	reg  [15: 0]        addressbus,
    output  wire                busclk,
    inout   wire [31: 0]        databus
);

// --------------------------------------------------
wire            axi_aclk;
wire            axi_aresetn;

wire	[31: 0] axil_awaddr;
wire	[2 : 0] axil_awprot;
wire	        axil_awvalid;
wire	        axil_awready;

wire	[31: 0] axil_wdata;
wire	[3 : 0] axil_wstrb;
wire	        axil_wvalid;
wire	        axil_wready;

wire	        axil_bvalid;
wire	[1 : 0] axil_bresp;
wire	        axil_bready;

wire	[31: 0] axil_araddr;
wire	[2 : 0] axil_arprot;
wire	        axil_arvalid;
wire	        axil_arready;

wire	[31: 0] axil_rdata;
wire    [1 : 0] axil_rresp;
wire	        axil_rvalid;
wire	        axil_rready;

// buffers ----------------------------------------------
wire pcie_refclk;
wire pcie_rstn;

IBUFDS_GTE2 pcie_refclk_ibuf (
    .I( i_pcie_refclkp ),
    .IB( i_pcie_refclkn ),
    .CEB( 'b0 ),
    .ODIV2(  ),
    .O  ( pcie_refclk )
);

IBUF   pcie_rstn_ibuf (
    .I( i_pcie_rstn ),
    .O( pcie_rstn )
);

BUFG busclk_BUFG (
    .I( axi_aclk ),
    .O( busclk )
);

// ---------- state machine --------------------------------------------------
reg [2:0] state, next_state;
localparam  IDLE    = 3'b000,
            AR_ACK  = 3'b001,
            R_ACK   = 3'b010,
            W_RESP  = 3'b011,
            W_ACK   = 3'b100,
            AW_ACK  = 3'b101;

always @(posedge axi_aclk or negedge axi_aresetn) begin
    if(!axi_aresetn)
        state <= IDLE;
    else
        state <= next_state;
end

always @(*) begin
    case (state)
        IDLE    :   next_state  =   (axil_arready && axil_arvalid) ? AR_ACK : 
                                    (axil_awready && axil_awvalid) ? AW_ACK : IDLE;
        AR_ACK  :   next_state  =   R_ACK;
        R_ACK   :   next_state  =   (axil_rready ) ? IDLE : R_ACK;
        AW_ACK  :   next_state  =   (axil_wvalid) ? W_ACK: AW_ACK;
        W_ACK   :   next_state  =   W_RESP;
        W_RESP  :   next_state  =   (axil_bready ) ? IDLE : W_RESP;     
        default :   next_state  =   IDLE;
    endcase
end

// ---------- output --------------------------------------------------
assign readsignal       = (state == AR_ACK);
assign writesignal      = (state == W_ACK);

assign axil_arready   = (state == IDLE);
assign axil_rvalid    = (state == R_ACK);
assign axil_awready   = (state == IDLE) && (!axil_arvalid);
assign axil_wready    = (state == W_ACK);
assign axil_bvalid    = (state == W_RESP);

assign axil_rresp     = 2'b0;
assign axil_bresp     = 2'b0;

// ---------- address buffer --------------------------------------------------
always @(posedge axi_aclk or negedge axi_aresetn) begin
    if(!axi_aresetn)
        addressbus <= 16'b0;
    else begin
        case (next_state)
            IDLE:       addressbus <= 16'b0;
            AR_ACK:     addressbus <= (axil_araddr[31:16] == base_addr) ? axil_araddr[15:0] : 16'b0;
            AW_ACK:     addressbus <= (axil_awaddr[31:16] == base_addr) ? axil_awaddr[15:0] : 16'b0;
            default:    addressbus <= addressbus;
        endcase
    end
end

// ---------- bus switch --------------------------------------------------
reg [31:0] wdata_reg;
always @(posedge axi_aclk or negedge axi_aresetn) begin
    if(!axi_aresetn)
        wdata_reg <= 32'b0;
    else if(axil_wvalid)
        wdata_reg <= axil_wdata;
    else
        wdata_reg <= wdata_reg;
end

assign axil_rdata = databus;
assign databus    = (writesignal)? wdata_reg : 32'bz;

// ---------- xdma --------------------------------------------------
xdma_0 xdma_0_inst (
    .sys_clk(pcie_refclk),
    .sys_rst_n(pcie_rstn),
    .user_lnk_up(user_lnk_up),

    .pci_exp_txp(o_pci_exp_txp),
    .pci_exp_txn(o_pci_exp_txn),
    .pci_exp_rxp(i_pci_exp_rxp),
    .pci_exp_rxn(i_pci_exp_rxn),

    .axi_aclk(axi_aclk),
    .axi_aresetn(axi_aresetn),

    .usr_irq_req('b0),
    .usr_irq_ack(),

    .m_axil_awaddr(axil_awaddr),
    .m_axil_awprot(axil_awprot),
    .m_axil_awvalid(axil_awvalid),
    .m_axil_awready(axil_awready),

    .m_axil_wdata(axil_wdata),
    .m_axil_wstrb(axil_wstrb),
    .m_axil_wvalid(axil_wvalid),
    .m_axil_wready(axil_wready),

    .m_axil_bvalid(axil_bvalid),
    .m_axil_bresp(axil_bresp),
    .m_axil_bready(axil_bready),

    .m_axil_araddr(axil_araddr),
    .m_axil_arprot(axil_arprot),
    .m_axil_arvalid(axil_arvalid),
    .m_axil_arready(axil_arready),

    .m_axil_rdata(axil_rdata),
    .m_axil_rresp(axil_rresp),
    .m_axil_rvalid(axil_rvalid),
    .m_axil_rready(axil_rready),

    .m_axi_awready('b0),
    .m_axi_awid(),
    .m_axi_awaddr(),
    .m_axi_awlen(),
    .m_axi_awsize(),
    .m_axi_awburst(),
    .m_axi_awprot(),
    .m_axi_awvalid(),
    .m_axi_awlock(),
    .m_axi_awcache(),

    .m_axi_arready('b0),
    .m_axi_arid(),
    .m_axi_araddr(),
    .m_axi_arlen(),
    .m_axi_arsize(),
    .m_axi_arburst(),
    .m_axi_arprot(),
    .m_axi_arvalid(),
    .m_axi_arlock(),
    .m_axi_arcache(),

    .m_axi_wready('b0),
    .m_axi_wdata(),
    .m_axi_wstrb(),
    .m_axi_wlast(),
    .m_axi_wvalid(),

    .m_axi_bid('b0),
    .m_axi_bresp('b0),
    .m_axi_bvalid('b0),
    .m_axi_bready(),
    
    .m_axi_rid('b0),
    .m_axi_rdata('b0),
    .m_axi_rresp('b0),
    .m_axi_rlast('b0),
    .m_axi_rvalid('b0),
    .m_axi_rready()
);

endmodule