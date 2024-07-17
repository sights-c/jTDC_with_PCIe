// -------------------------------------------------------------------------
// ----                                                                 ----
// ---- Engineer: Ri-Guang Chen                                         ----
// ---- Company : Xi'an Institute of Optics and Precision Mechanics     ----
// ----                                                                 ----
// ---- Target Devices: Ailinx ax7203 Analog Front-End                  ----
// ---- Description   : axi-lite interface for xdma                     ----
// ----                                                                 ----
// -------------------------------------------------------------------------
// ----                                                                 ----
// ---- Copyright (C) 2024 Ri-Guang Chen                                ----
// ----                                                                 ----
// ---- This program is free software; you can redistribute it and/or   ----
// ---- modify it under the terms of the GNU General Public License as  ----
// ---- published by the Free Software Foundation; either version 3 of  ----
// ---- the License, or (at your option) any later version.             ----
// ----                                                                 ----
// ---- This program is distributed in the hope that it will be useful, ----
// ---- but WITHOUT ANY WARRANTY; without even the implied warranty of  ----
// ---- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the    ----
// ---- GNU General Public License for more details.                    ----
// ----                                                                 ----
// ---- You should have received a copy of the GNU General Public       ----
// ---- License along with this program; if not, see                    ----
// ---- <http://www.gnu.org/licenses>.                                  ----
// ----                                                                 ----
// -------------------------------------------------------------------------
module bus_interface_axi (
    // Internal interface
    input	wire	[31:0]	statusregister,
    inout	wire	[31:0]	databus,
    output  reg     [15:0]	addressbus,
    output	reg 			readsignal,
    output	reg 			writesignal,
    // AXI configuration
    input	wire			axi_aclk,
    input	wire			axi_aresetn,
    // AXI-MM AW interface
    output	wire			axil_awready,
    input	wire			axil_awvalid,
    input	wire	[31:0]	axil_awaddr,
    input	wire	[ 2:0]	axil_awprot,
    // AXI-MM W  interface
    output	wire			axil_wready,
    input	wire			axil_wvalid,
    input	wire	[31:0]	axil_wdata,
    input	wire	[ 3:0]	axil_wstrb,
    // AXI-MM B  interface
    input	wire			axil_bready,
    output	wire			axil_bvalid,
    output	wire	[1:0]	axil_bresp,
    // AXI-MM AR interface
    output	wire			axil_arready,
    input	wire			axil_arvalid,
    input	wire	[31:0]	axil_araddr,
    input	wire	[ 2:0]	axil_arprot,
    // AXI-MM R  interface
    input	wire			axil_rready,
    output	wire			axil_rvalid,
    output	reg     [31:0]	axil_rdata,
    output	wire	[ 1:0]	axil_rresp 
);

// Read Channels --------------------------------------------------
     reg    [31:0]  test_register;
enum reg    [ 0:0]  { R_IDLE, R_BUSY }  r_state =   R_IDLE;

assign axil_arready    = (r_state == R_IDLE);
assign axil_rvalid     = (r_state == R_BUSY);
assign axil_rresp      = '0;

// Read finite-state machine --------------------------------------------------
always_ff @( posedge axi_aclk) begin
    if(!axi_aresetn) begin
        r_state <= R_IDLE;
        test_register <= 32'h0000_7203;
    end else begin
        case(r_state)
        R_IDLE:
            if( w_state == W_IDLE) begin
                r_state <= R_BUSY;
            end
        R_BUSY:
            if(axil_rready) begin
                r_state <= R_IDLE;
            end
        default:
            r_state <= R_IDLE;
        endcase
    end
end

// Write channels --------------------------------------------------
enum    [1:0]   { W_IDLE, W_BUSY, W_RESP }  w_state =   W_IDLE;

assign axil_awready    = (r_state == R_IDLE);
assign axil_wready     = (w_state == W_BUSY);
assign axil_bvalid     = (w_state == W_RESP);
assign axil_bresp      = '0;

// Write finite-state machine --------------------------------------------------
always_ff @( posedge axi_aclk) begin
    if(!axi_aresetn) begin
        w_state  <= W_IDLE;
    end else begin
        case(w_state)
        W_IDLE:
            if(axil_awvalid) begin
                w_state <= W_BUSY;
            end
        W_BUSY:
            if(axil_wvalid) begin
                w_state <= W_RESP;
            end
        W_RESP:
            if(axil_bready) begin
                w_state <= W_IDLE;
            end
        default:
            w_state <= W_IDLE;
        endcase
    end
end
  
// Internal Bus --------------------------------------------------



reg [15:0] addressbus_last;
always_comb begin
    if (w_state == W_IDLE && r_state == R_IDLE && axil_awvalid) begin
        addressbus   = axil_awaddr[31:16];
        writesignal  = '0;
        readsignal   = '0;
        axil_rdata   = '0;
    end else if (w_state == W_IDLE && r_state == R_IDLE && axil_arvalid) begin
        addressbus   = axil_araddr[31:16];
        writesignal  = '0;
        case (axil_araddr)
            32'h0000_0010:  begin
                axil_rdata  = statusregister;
                readsignal   = '0;
            end
            32'h7203_0000:  begin
                axil_rdata  = test_register;
                readsignal   = '0;
            end
                  default:  begin
                axil_rdata  = databus;
                readsignal   = '1;
            end
        endcase
    end else if (r_state == R_BUSY || w_state == W_BUSY) begin
        addressbus   = addressbus_last;
        writesignal  = (w_state == W_BUSY) && (r_state != R_BUSY);
        readsignal   = (w_state != W_BUSY) && (r_state == R_BUSY);
        axil_rdata   = (w_state != W_BUSY) && (r_state == R_BUSY) ? databus : '0;
    end else begin
        addressbus   = 'z;
        writesignal  = 'z;
        readsignal   = 'z;
        axil_rdata   = '0;
    end
end

always_ff @( posedge axi_aclk ) begin
    addressbus_last = addressbus;
end

assign  databus =   (w_state == W_BUSY && axil_wvalid && axil_awaddr == 32'h7203_0000) ? test_register :
                    (w_state == W_BUSY && axil_wvalid) ? axil_wdata :
                    'z;

endmodule
