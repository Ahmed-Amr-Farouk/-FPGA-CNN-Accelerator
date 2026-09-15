## Constraints_cnn_top.xdc
## Pin assignment for cnn_top module on the PYNQ-Z2 board (XC7Z020-1CLG400C)
##
## Widths taken from cnn_config.vh:
##  - DATA_WIDTH   = 8  -> pixel_in[7:0], weight_in[7:0]
##  - OUTPUT_WIDTH = 2*DATA_WIDTH + clog2(KERNEL_SIZE*KERNEL_SIZE)
##                 = 2*8 + clog2(9) = 16 + 4 = 20 -> output_pixels[19:0]
##
## output_pixels (20 bits) doesn't fit on a single Pmod/Arduino digital
## bank, so it is split across the full Arduino shield digital I/O:
##   output_pixels[13:0]  -> ar[0]..ar[13]   (14 pins)
##   output_pixels[19:14] -> a[0]..a[5]      (6 pins, used as digital I/O)

## ------------------------------------------------------------------
## Clock (206 MHz) -> clk
## ------------------------------------------------------------------
set_property -dict { PACKAGE_PIN H16   IOSTANDARD LVCMOS33 } [get_ports { clk }]; #IO_L13P_T2_MRCC_35 Sch=sysclk
create_clock -add -name sys_clk_pin -period 4.854 -waveform {0 2.427} [get_ports { clk }];
## ------------------------------------------------------------------
## Control inputs -> Push Buttons
## ------------------------------------------------------------------
set_property -dict { PACKAGE_PIN D19   IOSTANDARD LVCMOS33 } [get_ports { rst_n }];        #btn[0] Sch=btn[0]  (active-low reset)
set_property -dict { PACKAGE_PIN D20   IOSTANDARD LVCMOS33 } [get_ports { start }];         #btn[1] Sch=btn[1]
##set_property -dict { PACKAGE_PIN L20   IOSTANDARD LVCMOS33 } [get_ports { weight_valid }];  #btn[2] Sch=btn[2]

## ------------------------------------------------------------------
## Status outputs -> LEDs
## ------------------------------------------------------------------
set_property -dict { PACKAGE_PIN R14   IOSTANDARD LVCMOS33 } [get_ports { output_valid }]; #led[0]
set_property -dict { PACKAGE_PIN P14   IOSTANDARD LVCMOS33 } [get_ports { last_output }];   #led[1]
set_property -dict { PACKAGE_PIN N16   IOSTANDARD LVCMOS33 } [get_ports { kernel_valid }];  #led[2]
set_property -dict { PACKAGE_PIN M14   IOSTANDARD LVCMOS33 } [get_ports { window_valid }];  #led[3]

## ------------------------------------------------------------------
## pixel_in [7:0] -> Pmod JA  (ASSUMES DATA_WIDTH = 8 -- confirm!)
## ------------------------------------------------------------------
set_property -dict { PACKAGE_PIN Y18   IOSTANDARD LVCMOS33 } [get_ports { pixel_in[0] }]; #JA1_P
set_property -dict { PACKAGE_PIN Y19   IOSTANDARD LVCMOS33 } [get_ports { pixel_in[1] }]; #JA1_N
set_property -dict { PACKAGE_PIN Y16   IOSTANDARD LVCMOS33 } [get_ports { pixel_in[2] }]; #JA2_P
set_property -dict { PACKAGE_PIN Y17   IOSTANDARD LVCMOS33 } [get_ports { pixel_in[3] }]; #JA2_N
set_property -dict { PACKAGE_PIN U18   IOSTANDARD LVCMOS33 } [get_ports { pixel_in[4] }]; #JA3_P
set_property -dict { PACKAGE_PIN U19   IOSTANDARD LVCMOS33 } [get_ports { pixel_in[5] }]; #JA3_N
set_property -dict { PACKAGE_PIN W18   IOSTANDARD LVCMOS33 } [get_ports { pixel_in[6] }]; #JA4_P
set_property -dict { PACKAGE_PIN W19   IOSTANDARD LVCMOS33 } [get_ports { pixel_in[7] }]; #JA4_N

## ------------------------------------------------------------------
## weight_in [7:0] -> Pmod JB  (ASSUMES DATA_WIDTH = 8 -- confirm!)
## ------------------------------------------------------------------
set_property -dict { PACKAGE_PIN W14   IOSTANDARD LVCMOS33 } [get_ports { weight_in[0] }]; #JB1_P
set_property -dict { PACKAGE_PIN Y14   IOSTANDARD LVCMOS33 } [get_ports { weight_in[1] }]; #JB1_N
set_property -dict { PACKAGE_PIN T11   IOSTANDARD LVCMOS33 } [get_ports { weight_in[2] }]; #JB2_P
set_property -dict { PACKAGE_PIN T10   IOSTANDARD LVCMOS33 } [get_ports { weight_in[3] }]; #JB2_N
set_property -dict { PACKAGE_PIN V16   IOSTANDARD LVCMOS33 } [get_ports { weight_in[4] }]; #JB3_P
set_property -dict { PACKAGE_PIN W16   IOSTANDARD LVCMOS33 } [get_ports { weight_in[5] }]; #JB3_N
set_property -dict { PACKAGE_PIN V12   IOSTANDARD LVCMOS33 } [get_ports { weight_in[6] }]; #JB4_P
set_property -dict { PACKAGE_PIN W13   IOSTANDARD LVCMOS33 } [get_ports { weight_in[7] }]; #JB4_N

## ------------------------------------------------------------------
## output_pixels [19:0] -> full Arduino shield digital I/O
## (OUTPUT_WIDTH = 20, confirmed from cnn_config.vh)
## ------------------------------------------------------------------
set_property -dict { PACKAGE_PIN T14   IOSTANDARD LVCMOS33 } [get_ports { output_pixels[0] }];  #ar[0]
set_property -dict { PACKAGE_PIN U12   IOSTANDARD LVCMOS33 } [get_ports { output_pixels[1] }];  #ar[1]
set_property -dict { PACKAGE_PIN U13   IOSTANDARD LVCMOS33 } [get_ports { output_pixels[2] }];  #ar[2]
set_property -dict { PACKAGE_PIN V13   IOSTANDARD LVCMOS33 } [get_ports { output_pixels[3] }];  #ar[3]
set_property -dict { PACKAGE_PIN V15   IOSTANDARD LVCMOS33 } [get_ports { output_pixels[4] }];  #ar[4]
set_property -dict { PACKAGE_PIN T15   IOSTANDARD LVCMOS33 } [get_ports { output_pixels[5] }];  #ar[5]
set_property -dict { PACKAGE_PIN R16   IOSTANDARD LVCMOS33 } [get_ports { output_pixels[6] }];  #ar[6]
set_property -dict { PACKAGE_PIN U17   IOSTANDARD LVCMOS33 } [get_ports { output_pixels[7] }];  #ar[7]
set_property -dict { PACKAGE_PIN V17   IOSTANDARD LVCMOS33 } [get_ports { output_pixels[8] }];  #ar[8]
set_property -dict { PACKAGE_PIN V18   IOSTANDARD LVCMOS33 } [get_ports { output_pixels[9] }];  #ar[9]
set_property -dict { PACKAGE_PIN T16   IOSTANDARD LVCMOS33 } [get_ports { output_pixels[10] }]; #ar[10]
set_property -dict { PACKAGE_PIN R17   IOSTANDARD LVCMOS33 } [get_ports { output_pixels[11] }]; #ar[11]
set_property -dict { PACKAGE_PIN P18   IOSTANDARD LVCMOS33 } [get_ports { output_pixels[12] }]; #ar[12]
set_property -dict { PACKAGE_PIN N17   IOSTANDARD LVCMOS33 } [get_ports { output_pixels[13] }]; #ar[13]
set_property -dict { PACKAGE_PIN Y11   IOSTANDARD LVCMOS33 } [get_ports { output_pixels[14] }]; #a[0]
set_property -dict { PACKAGE_PIN Y12   IOSTANDARD LVCMOS33 } [get_ports { output_pixels[15] }]; #a[1]
set_property -dict { PACKAGE_PIN W11   IOSTANDARD LVCMOS33 } [get_ports { output_pixels[16] }]; #a[2]
set_property -dict { PACKAGE_PIN V11   IOSTANDARD LVCMOS33 } [get_ports { output_pixels[17] }]; #a[3]
set_property -dict { PACKAGE_PIN T5    IOSTANDARD LVCMOS33 } [get_ports { output_pixels[18] }]; #a[4]
set_property -dict { PACKAGE_PIN U10   IOSTANDARD LVCMOS33 } [get_ports { output_pixels[19] }]; #a[5]