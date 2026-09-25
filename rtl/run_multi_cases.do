vlib work
vlog +incdir+. *.sv

vsim -voptargs=+acc work.tb_cnn_top

do wave.do

# Run all test cases
run -all