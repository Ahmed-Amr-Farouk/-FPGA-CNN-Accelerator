onerror {resume}
quietly WaveActivateNextPane {} 0

# ============================================================
# CNN TOP - Main I/O
# ============================================================
add wave -divider {TOP I/O}
add wave -noupdate /tb_cnn_top/dut/clk
add wave -noupdate /tb_cnn_top/dut/rst_n
add wave -noupdate /tb_cnn_top/dut/start
add wave -noupdate -radix unsigned /tb_cnn_top/dut/pixel_in
add wave -noupdate -radix decimal /tb_cnn_top/dut/weight_in

# ============================================================
# Control / FSM
# ============================================================
add wave -divider {CONTROL / FSM}
add wave -noupdate /tb_cnn_top/dut/pixel_valid
add wave -noupdate /tb_cnn_top/dut/weight_valid
add wave -noupdate /tb_cnn_top/dut/kernel_valid
add wave -noupdate /tb_cnn_top/dut/load_weight
add wave -noupdate /tb_cnn_top/dut/start_conv
add wave -noupdate /tb_cnn_top/dut/window_valid
add wave -noupdate /tb_cnn_top/dut/last_window
add wave -noupdate /tb_cnn_top/dut/conv_done
add wave -noupdate /tb_cnn_top/dut/st_ReLU
add wave -noupdate /tb_cnn_top/dut/last_conv
add wave -noupdate /tb_cnn_top/dut/finish_conv
add wave -noupdate -radix unsigned /tb_cnn_top/dut/u_fsm/current_state
add wave -noupdate -radix unsigned /tb_cnn_top/dut/u_fsm/next_state

# ============================================================
# Kernel / Window Data
# ============================================================
add wave -divider {KERNEL / WINDOW}
add wave -noupdate -radix hex /tb_cnn_top/dut/kernel
add wave -noupdate -radix hex /tb_cnn_top/dut/window_flat

# ============================================================
# Convolution / ReLU Output
# ============================================================
add wave -divider {OUTPUT}
add wave -noupdate -color Cyan -radix decimal /tb_cnn_top/dut/conv_pixels
add wave -noupdate -color Yellow -radix decimal /tb_cnn_top/dut/output_pixels
add wave -noupdate -color {Slate Blue} /tb_cnn_top/dut/output_valid
add wave -noupdate -color Magenta /tb_cnn_top/dut/last_output

TreeUpdate [SetDefaultTree]

configure wave -namecolwidth 180
configure wave -valuecolwidth 120
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
configure wave -timelineunits ns

update
WaveRestoreZoom {0 ns} {5 us}
