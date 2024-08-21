##system
set_property -dict {PACKAGE_PIN Y9 IOSTANDARD LVCMOS33} [get_ports sys_clk]
set_property -dict {PACKAGE_PIN T18 IOSTANDARD LVCMOS33} [get_ports sys_rst]

##spi
set_property -dict {PACKAGE_PIN Y11 IOSTANDARD LVCMOS33} [get_ports cs_n]
set_property -dict {PACKAGE_PIN AA9 IOSTANDARD LVCMOS33} [get_ports mosi]
set_property -dict {PACKAGE_PIN Y10 IOSTANDARD LVCMOS33} [get_ports sck]
set_property -dict {PACKAGE_PIN AA11 IOSTANDARD LVCMOS33} [get_ports miso]

## uart
set_property -dict {PACKAGE_PIN W12 IOSTANDARD LVCMOS33} [get_ports rx]
set_property -dict {PACKAGE_PIN W11 IOSTANDARD LVCMOS33} [get_ports tx]

##keys
set_property -dict {PACKAGE_PIN N15 IOSTANDARD LVCMOS33} [get_ports {key[3]}]
set_property -dict {PACKAGE_PIN P16 IOSTANDARD LVCMOS33} [get_ports {key[2]}]
set_property -dict {PACKAGE_PIN R18 IOSTANDARD LVCMOS33} [get_ports {key[1]}]
set_property -dict {PACKAGE_PIN R16 IOSTANDARD LVCMOS33} [get_ports {key[0]}]

## ila

set_property C_CLK_INPUT_FREQ_HZ 300000000 [get_debug_cores dbg_hub]
set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
connect_debug_port dbg_hub/clk [get_nets ila_clk]
