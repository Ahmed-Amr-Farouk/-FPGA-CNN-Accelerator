onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tb_cnn_top/dut/clk
add wave -noupdate /tb_cnn_top/dut/rst_n
add wave -noupdate /tb_cnn_top/dut/start
add wave -noupdate /tb_cnn_top/dut/weight_valid
add wave -noupdate /tb_cnn_top/dut/weight_in
add wave -noupdate -color Yellow /tb_cnn_top/dut/output_pixels
add wave -noupdate -color {Slate Blue} /tb_cnn_top/dut/output_valid
add wave -noupdate -color Magenta /tb_cnn_top/dut/last_output
add wave -noupdate -color {Orange Red} /tb_cnn_top/dut/window_valid
add wave -noupdate /tb_cnn_top/dut/pixel_valid
add wave -noupdate /tb_cnn_top/dut/load_kernel
add wave -noupdate /tb_cnn_top/dut/start_op
add wave -noupdate /tb_cnn_top/dut/load_weight
add wave -noupdate /tb_cnn_top/dut/kernel
add wave -noupdate /tb_cnn_top/dut/window_flat
add wave -noupdate /tb_cnn_top/dut/finish_flush
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {41035000 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 150
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ps
update
WaveRestoreZoom {40964858 ps} {40985095 ps}
