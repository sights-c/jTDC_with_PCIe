# --------------------------------------------------
# NET - IOSTANDARD
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]

# SPI Configure Setting
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]
set_property CONFIG_MODE SPIx4 [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 50 [current_design]

# # --------------------------------------------------
# set_property -dict { PACKAGE_PIN T6 IOSTANDARD LVCMOS15     } [get_ports i_sys_rstn];
# set_property -dict { PACKAGE_PIN R4 IOSTANDARD DIFF_SSTL15  } [get_ports i_sys_clkp];
# create_clock -name sys_clk -period 5 [get_ports i_sys_clkp];

# --------------------------------------------------
# pcie 
set_property -dict { PACKAGE_PIN J20 IOSTANDARD LVCMOS18 PULLUP true} [get_ports i_pcie_rstn]

set_property PACKAGE_PIN F10  [get_ports i_pcie_refclkp ]
create_clock -name pcie_refclk -period 10 [get_ports i_pcie_refclkp]

set_property PACKAGE_PIN D5   [get_ports o_pci_exp_txp[0]]
set_property PACKAGE_PIN B4   [get_ports o_pci_exp_txp[1]]
set_property PACKAGE_PIN B6   [get_ports o_pci_exp_txp[2]]
set_property PACKAGE_PIN D7   [get_ports o_pci_exp_txp[3]]

set_property PACKAGE_PIN D11  [get_ports i_pci_exp_rxp[0]]
set_property PACKAGE_PIN B8   [get_ports i_pci_exp_rxp[1]]
set_property PACKAGE_PIN B10  [get_ports i_pci_exp_rxp[2]]
set_property PACKAGE_PIN D9   [get_ports i_pci_exp_rxp[3]]

# --------------------------------------------------
# LED pins output
set_property -dict { PACKAGE_PIN B13  IOSTANDARD LVCMOS15 } [get_ports user_led[0] ]
set_property -dict { PACKAGE_PIN C13  IOSTANDARD LVCMOS15 } [get_ports user_led[1] ]
set_property -dict { PACKAGE_PIN D14  IOSTANDARD LVCMOS15 } [get_ports user_led[2] ]
set_property -dict { PACKAGE_PIN D15  IOSTANDARD LVCMOS15 } [get_ports user_led[3] ]

# ---------------------------------------------------
# pulse input
set_property -dict { PACKAGE_PIN P16 } [get_ports MEZ[0]];
set_property -dict { PACKAGE_PIN P15 } [get_ports MEZ[2]];
set_property -dict { PACKAGE_PIN N17 } [get_ports MEZ[4]];
set_property -dict { PACKAGE_PIN T16 } [get_ports MEZ[6]];
set_property -dict { PACKAGE_PIN U17 } [get_ports MEZ[8]];
set_property -dict { PACKAGE_PIN P19 } [get_ports MEZ[10]];
set_property -dict { PACKAGE_PIN V18 } [get_ports MEZ[12]];
set_property -dict { PACKAGE_PIN U20 } [get_ports MEZ[14]];
set_property -dict { PACKAGE_PIN AA9 } [get_ports MEZ[16]];
set_property -dict { PACKAGE_PIN AA10 } [get_ports MEZ[18]];
set_property -dict { PACKAGE_PIN V10 } [get_ports MEZ[20]];
set_property -dict { PACKAGE_PIN Y11 } [get_ports MEZ[22]];
set_property -dict { PACKAGE_PIN W11 } [get_ports MEZ[24]];
set_property -dict { PACKAGE_PIN AA15 } [get_ports MEZ[26]];
set_property -dict { PACKAGE_PIN Y16 } [get_ports MEZ[28]];
set_property -dict { PACKAGE_PIN AB16 } [get_ports MEZ[30]];
set_property -dict { PACKAGE_PIN W14 } [get_ports MEZ[32]];
set_property -dict { PACKAGE_PIN W15 } [get_ports MEZ[34]];
set_property -dict { PACKAGE_PIN V17 } [get_ports MEZ[36]];
set_property -dict { PACKAGE_PIN U15 } [get_ports MEZ[38]];
set_property -dict { PACKAGE_PIN AB21 } [get_ports MEZ[40]];
set_property -dict { PACKAGE_PIN AA20 } [get_ports MEZ[42]];
set_property -dict { PACKAGE_PIN AA19 } [get_ports MEZ[44]];
set_property -dict { PACKAGE_PIN AA18 } [get_ports MEZ[46]];
set_property -dict { PACKAGE_PIN W21 } [get_ports MEZ[48]];
set_property -dict { PACKAGE_PIN T21 } [get_ports MEZ[50]];
set_property -dict { PACKAGE_PIN Y21 } [get_ports MEZ[52]];
set_property -dict { PACKAGE_PIN W19 } [get_ports MEZ[54]];
set_property -dict { PACKAGE_PIN Y18 } [get_ports MEZ[56]];
set_property -dict { PACKAGE_PIN U22 } [get_ports MEZ[58]];
set_property -dict { PACKAGE_PIN R18 } [get_ports MEZ[60]];
set_property -dict { PACKAGE_PIN P14 } [get_ports MEZ[62]];

# ---------------------------------------------------
# nim input
set_property -dict { PACKAGE_PIN N14  IOSTANDARD LVCMOS25 } [get_ports NIM_IN[0] ];
set_property -dict { PACKAGE_PIN N13  IOSTANDARD LVCMOS25 } [get_ports NIM_IN[1] ];
set_property -dict { PACKAGE_PIN T20  IOSTANDARD LVCMOS25 } [get_ports NIM_IN[2] ];
set_property -dict { PACKAGE_PIN Y17  IOSTANDARD LVCMOS25 } [get_ports NIM_IN[3] ];

# TIMESPEC
set_max_delay 30 -datapath_only -from [get_ports MEZ[*]]
set_max_delay 30 -through [get_nets config_register_A[*]]
set_max_delay 30 -through [get_nets config_register_B[*]]
set_max_delay 30 -through [get_nets enable_register[*]]
set_max_delay 30 -through [get_nets jTDC/tdc_out[*]]

set_max_delay 30 -from [get_cells jTDC/tdc_slicecounts_current_reg[*]]
set_max_delay 30 -from [get_cells jTDC/tdc_slicecounts_stop_reg[*]]

set_max_delay 35 -from [get_cells jTDC/tdc_this_clockcounter_reg[*]]
set_max_delay 35 -from [get_cells jTDC/tdc_first_clockcounter_reg[*]]

set_max_delay 10 -to [get_cells jTDC/eventsize_too_big_reg]

# CROSSCLK
set_max_delay 50 -datapath_only -from [get_cells INPUT_HITS_COUNTER[*].INPUT_COUNTER_DATALATCH/latched_data_reg[*]]

set_max_delay 50 -through [get_nets INPUT_HITS_COUNTER[*].dutyline]