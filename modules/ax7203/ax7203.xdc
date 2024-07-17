# --------------------------------------------------
# SPI Configure Setting
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design] 
set_property CONFIG_MODE SPIx4 [current_design] 
set_property BITSTREAM.CONFIG.CONFIGRATE 50 [current_design] 

# --------------------------------------------------
set_property PACKAGE_PIN    T6              [get_ports brd_rst_n];
set_property IOSTANDARD     LVCMOS15        [get_ports brd_rst_n];

set_property PACKAGE_PIN    R4              [get_ports { brd_clk_p }];
set_property IOSTANDARD     DIFF_SSTL15     [get_ports brd_clk_p]
create_clock -name sys_clk -period 5 [get_ports {brd_clk_p}]

# --------------------------------------------------
# pcie 
set_property PACKAGE_PIN    J20             [get_ports pcie_rst_n];
set_property IOSTANDARD     LVCMOS18        [get_ports pcie_rst_n];
set_property PULLUP         true            [get_ports pcie_rst_n];

set_property PACKAGE_PIN F10  [get_ports { pcie_refclkp }]; 

set_property PACKAGE_PIN D5    [get_ports { pcie_txp[0] }];
#set_property PACKAGE_PIN B4   [get_ports { pcie_txp[1] }];
#set_property PACKAGE_PIN B6   [get_ports { pcie_txp[2] }];
#set_property PACKAGE_PIN D7   [get_ports { pcie_txp[3] }];

set_property PACKAGE_PIN D11   [get_ports { pcie_rxp[0] }];
#set_property PACKAGE_PIN B8   [get_ports { pcie_rxp[1] }];
#set_property PACKAGE_PIN B10  [get_ports { pcie_rxp[2] }];
#set_property PACKAGE_PIN D9   [get_ports { pcie_rxp[3] }];

# --------------------------------------------------
# LED pins output
set_property -dict { PACKAGE_PIN B13  IOSTANDARD LVCMOS15 } [get_ports { user_led[0] }];
set_property -dict { PACKAGE_PIN C13  IOSTANDARD LVCMOS15 } [get_ports { user_led[1] }];
set_property -dict { PACKAGE_PIN D14  IOSTANDARD LVCMOS15 } [get_ports { user_led[2] }];
set_property -dict { PACKAGE_PIN D15  IOSTANDARD LVCMOS15 } [get_ports { user_led[3] }];