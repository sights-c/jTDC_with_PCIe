//////////////////////////////////////////////////////////////////////////////////
// Company: Xi'an Institute of Optics and Precision Mechanics of CAS 
// Engineer: Riguang-Chen
// 
// Create Date: 2024/08/26 00:30:00
// Design Name: jTDC_PCIe
// Module Name: axi4_interface
// Project Name: jTDC_PCIe
// Target Devices: xc7a200tfbg484-2
// Tool Versions: 2023.1
// Description:
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
`default_nettype none
module axi4lite_interface #(
    parameter base_addr = 16'h7203
)(
    input	wire          sys_rstn,

    output	wire          writesignal,
    output	wire          readsignal,
    output	reg  [15: 0]  addressbus,
    inout   wire [31: 0]  databus,

    input	wire          axi_aclk,
    input	wire          axi_aresetn,
        
    input	wire [31: 0]  s_axil_awaddr,
    input	wire [ 2: 0]  s_axil_awprot,
    input	wire          s_axil_awvalid,
    output	wire          s_axil_awready,

    input	wire [31: 0]  s_axil_wdata,
    input	wire [ 3: 0]  s_axil_wstrb,
    input	wire          s_axil_wvalid,
    output	wire          s_axil_wready,

    output	wire          s_axil_bvalid,
    output	wire [ 1: 0]  s_axil_bresp,
    input	wire          s_axil_bready,

    input	wire [31: 0]  s_axil_araddr,
    input	wire [ 2: 0]  s_axil_arprot,
    input	wire          s_axil_arvalid,
    output	wire          s_axil_arready,

    output	wire [31: 0]  s_axil_rdata,
    output	wire [ 1: 0]  s_axil_rresp,
    output	wire          s_axil_rvalid,
    input	wire          s_axil_rready
);
// ---------- state machine --------------------------------------------------
reg [2:0] state, next_state;
localparam  IDLE    = 3'b000,
            AR_ACK  = 3'b001,
            R_ACK   = 3'b010,
            W_RESP  = 3'b011,
            W_ACK   = 3'b100,
            AW_ACK  = 3'b101;

always @(posedge axi_aclk or negedge axi_aresetn or negedge sys_rstn) begin
    if(!axi_aresetn || !sys_rstn)
        state <= IDLE;
    else
        state <= next_state;
end

always @(*) begin
    case (state)
        IDLE    :   next_state  =   (s_axil_arready && s_axil_arvalid) ? AR_ACK : 
                                    (s_axil_awready && s_axil_awvalid) ? AW_ACK : IDLE;
        AR_ACK  :   next_state  =   R_ACK;
        R_ACK   :   next_state  =   (s_axil_rready ) ? IDLE : R_ACK;
        AW_ACK  :   next_state  =   (s_axil_wvalid) ? W_ACK: AW_ACK;
        W_ACK   :   next_state  =   W_RESP;
        W_RESP  :   next_state  =   (s_axil_bready ) ? IDLE : W_RESP;     
        default :   next_state  =   IDLE;
    endcase
end

// ---------- output --------------------------------------------------
assign readsignal       = (state == AR_ACK);
assign writesignal      = (state == W_ACK);

assign s_axil_arready   = (state == IDLE);
assign s_axil_rvalid    = (state == R_ACK);
assign s_axil_awready   = (state == IDLE) && (!s_axil_arvalid);
assign s_axil_wready    = (state == W_ACK);
assign s_axil_bvalid    = (state == W_RESP);

assign s_axil_rresp     = 2'b0;
assign s_axil_bresp     = 2'b0;

// ---------- address buffer --------------------------------------------------
always @(posedge axi_aclk or negedge axi_aresetn or negedge sys_rstn) begin
    if(!axi_aresetn || !sys_rstn)
        addressbus <= 16'b0;
    else begin
        case (next_state)
            IDLE:       addressbus <= 16'b0;
            AR_ACK:     addressbus <= (s_axil_araddr[31:16] == base_addr) ? s_axil_araddr[15:0] : 16'b0;
            AW_ACK:     addressbus <= (s_axil_awaddr[31:16] == base_addr) ? s_axil_awaddr[15:0] : 16'b0;
            default:    addressbus <= addressbus;
        endcase
    end
end

// ---------- bus switch --------------------------------------------------
reg [31:0] wdata_reg;
always @(posedge axi_aclk or negedge axi_aresetn or negedge sys_rstn) begin
    if(!axi_aresetn || !sys_rstn)
        wdata_reg <= 32'b0;
    else if(s_axil_wvalid)
        wdata_reg <= s_axil_wdata;
    else
        wdata_reg <= wdata_reg;
end

assign s_axil_rdata = databus;
assign databus      = (writesignal)? wdata_reg : 32'bz;

endmodule