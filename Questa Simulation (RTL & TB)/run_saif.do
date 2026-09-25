vlib work
vlog +incdir+. *.sv

vsim -voptargs=+acc work.tb_cnn_top

do wave.do

# Skip reset / idle
run 75 ns

# Start SAIF capture when active processing starts
power add -r /tb_cnn_top/dut/*

# Active interval: 75 ns -> 10365 ns
run 10290 ns


# Export SAIF
power report -all -bsaif convolution.saif