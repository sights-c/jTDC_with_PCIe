axil//////////////////////////////////////////////////////////////////////////////////
// Company: Xi'an Institute of Optics and Precision Mechanics of CAS 
// Engineer: Riguang-Chen
// 
// Create Date: 2024/08/26 00:30:00
// Design Name: jTDC_PCIe
// Module Name: axi4_interface
// Project Name: jTDC_PCIe
// Target Devices: xc7a200tfbg484-2
// Tool Versions: 2018.3
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
module axi4lite_interface(
    input	wire          sys_clk,
    input	wire          sys_rstn,

    output	wire          writesignal,
    output	wire          readsignal,
    output	reg  [15: 0]  addressbus,
    inout	wire [31: 0]  databus,
    output	wire [31: 0]  statusregister,

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

    input	wire          s_axil_bvalid,
    input	wire [ 1: 0]  s_axil_bresp,
    output	wire          s_axil_bready,

    input	wire [31: 0]  s_axil_araddr,
    input	wire [ 2: 0]  s_axil_arprot,
    input	wire          s_axil_arvalid,
    output	wire          s_axil_arready,

    input	wire [31: 0]  s_axil_rdata,
    input	wire [ 1: 0]  s_axil_rresp,
    output	wire          s_axil_rvalid,
    input	wire          s_axil_rready
);
// ---------- 内部信号 --------------------------------------------------
reg [2:0] state, next_state;
localparam  IDLE    = 3'b000,
            AR_ACK  = 3'b001,
            R_ACK   = 3'b010,
            W_RESP  = 3'b011,
            W_ACK   = 3'b100,
            AW_ACK  = 3'b101;

// ---------- 状态切换（时序逻辑） --------------------------------------------------
always @(posedge axi_aclk or negedge axi_aresetn or negedge sys_rstn) begin
    if(!axi_aresetn || !sys_rstn)
        state <= IDLE;
    else
        state <= next_state;
end

// ---------- 次态判据（组合逻辑） --------------------------------------------------
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

// ---------- moore型输出（组合逻辑） --------------------------------------------------
assign readsignal       = (state == AR_ACK);
assign writesignal      = (state == W_ACK);

assign s_axil_arready   = (state == IDLE);
assign s_axil_rvalid    = (state == R_ACK);
assign s_axil_awready   = (state == IDLE) && (zs_axil_awvalid) && (!s_axil_arvalid);
assign s_axil_wready    = (state == W_ACK);
assign s_axil_bvalid    = (state == W_RESP);

// ---------- 地址寄存（时序逻辑）--------------------------------------------------
always @(posedge axi_aclk or negedge axi_aresetn or negedge sys_rstn) begin
    if(!axi_aresetn || !sys_rstn)
        addressbus <= 16'bz;
    else begin
        if(next_state == AR_ACK)
            addressbus <= s_axil_araddr[15:0];
        else if(next_state == AW_ACK)
            addressbus <= s_axil_awaddr[15:0];
        else if(next_state == IDLE)
            addressbus <= 16'bz;
        else
            addressbus <= addressbus;
    end
end

// ---------- 总线开关（组合逻辑）--------------------------------------------------
always @(*) begin
    if(!axi_aresetn || !sys_rstn) begin
        databus         = 16'bz;
        s_axil_rdata    = 32'bz;
    end else begin
        if(state == R_ACK)
            s_axil_rdata = databus;
        else if(state == W_ACK)
            databus = s_axil_wdata;
        else if(state == IDLE)
            databus = 16'bz;
        else begin
            databus         = databus;
            s_axil_rdata    = s_axil_rdata;
        end
    end
end

endmodule