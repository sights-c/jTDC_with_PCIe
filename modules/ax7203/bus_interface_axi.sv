module bus_interface_axi #(
    parameter AXI_AWIDTH   = 64,
    parameter AXI_DWIDTH   = 64,
    parameter AXI_IDWIDTH  = 4
) (
    // Internal interface
    input   logic [             31:0]   statusregister,
    inout   logic [             31:0]   databus,
    output  logic [             15:0]   addressbus,
    output  logic						readsignal,
    output  logic						writesignal,
    // AXI configuration
    input   logic						axi_aclk,
    input   logic						axi_aresetn,
    // AXI-MM AW interface
    output  logic						axi_awready,
    input   logic						axi_awvalid,
    input   logic [    AXI_AWIDTH-1:0]	axi_awaddr,
    input   logic [               7:0]	axi_awlen,
    input   logic [   AXI_IDWIDTH-1:0]	axi_awid,
    // AXI-MM W  interface
    output  logic						axi_wready,
    input   logic						axi_wvalid,
    input   logic						axi_wlast,
    input   logic [    AXI_DWIDTH-1:0]	axi_wdata,
    input   logic [(AXI_DWIDTH/8)-1:0]	axi_wstrb,
    // AXI-MM B  interface
    input   logic						axi_bready,
    output  logic						axi_bvalid,
    output  logic [   AXI_IDWIDTH-1:0]	axi_bid,
    output  logic [               1:0]	axi_bresp,
    // AXI-MM AR interface
    output  logic						axi_arready,
    input   logic						axi_arvalid,
    input   logic [    AXI_AWIDTH-1:0]	axi_araddr,
    input   logic [               7:0]	axi_arlen,
    input   logic [   AXI_IDWIDTH-1:0]	axi_arid,
    // AXI-MM R  interface
    input   logic                       axi_rready,
    output  logic                       axi_rvalid,
    output  logic                       axi_rlast,
    output  logic [    AXI_DWIDTH-1:0]  axi_rdata,
    output  logic [   AXI_IDWIDTH-1:0]  axi_rid,
    output  logic [               1:0]  axi_rresp 
);

// Read Channels --------------------------------------------------
enum logic [0:0]    { R_IDLE, R_BUSY }  r_state =   R_IDLE;

logic   [AXI_IDWIDTH-1:0]   rid     = '0;
logic   [7:0]               rcount  = '0;

assign axi_arready    = (r_state == R_IDLE);
assign axi_rvalid     = (r_state == R_BUSY);
assign axi_rlast      = (r_state == R_BUSY && rcount == 8'd0);
assign axi_rid        = rid;
assign axi_rresp      = '0;

// Read finite-state machine --------------------------------------------------
always_ff @( posedge axi_aclk) begin : fsm_read
    if(!axi_aresetn) begin
        r_state <= R_IDLE;
        rid     <= '0;
        rcount  <= '0;
    end else begin
        case(r_state)
        R_IDLE:
            if(axi_arvalid) begin
                r_state <= R_BUSY;
                rid     <= axi_arid;
                rcount  <= axi_arlen;
            end
        R_BUSY:
            if(axi_rready) begin
                if(rcount == 'b0)
                    r_state <= R_IDLE;
                rcount <= rcount - 8'd1;
            end
        default:
            r_state <= R_IDLE;
        endcase
    end
end

// Read data --------------------------------------------------


// Write channels --------------------------------------------------
enum logic [1:0]    { W_IDLE, W_BUSY, W_RESP }  w_state =   W_IDLE;

logic   [AXI_IDWIDTH-1:0]   wid         = '0;
logic   [7:0]               wcount      = '0;

assign axi_awready    = (w_state == W_IDLE);
assign axi_wready     = (w_state == W_BUSY);
assign axi_bvalid     = (w_state == W_RESP);
assign axi_bid        = wid;
assign axi_bresp      = '0;

// Write finite-state machine --------------------------------------------------
always_ff @( posedge axi_aclk) begin : fsm_write
    if(!axi_aresetn) begin
        w_state  <= W_IDLE;
        wid      <= '0;
        wcount   <= '0;
    end else begin
        case(w_state)
        W_IDLE:
            if(axi_awvalid) begin
                w_state     <= W_BUSY;
                wid         <= axi_awid;
                wcount      <= axi_awlen;
            end
        W_BUSY:
            if(axi_wvalid) begin
                if(wcount == 'b0 || axi_wlast)
                    w_state <= W_RESP;
                wcount <= wcount - 'b1;
            end
        W_RESP:
            if(axi_bready) begin
                w_state <= W_IDLE;
            end
        default:
            w_state <= W_IDLE;
        endcase
    end
end
    
function automatic int log2(input int x);
    int xtmp = x, y = 0;
    while (xtmp != 0) begin
        y ++;
        xtmp >>= 1;
    end
    return (y==0) ? 0 : (y-1);
endfunction

endmodule
