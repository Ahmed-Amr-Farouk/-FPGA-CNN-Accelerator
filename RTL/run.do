vlib work
vlog +incdir+ *.*v
vsim -voptargs=+acc work.tb_cnn_top
do wave.do
# Reset / idle
run 45 ns

# Start collecting switching activity
power add /tb_cnn_top/*

# Active convolution only
run 155625 ns

# Generate SAIF
power report -all -bsaif convolution.saif

# quit -sim