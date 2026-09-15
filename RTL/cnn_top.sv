`include "cnn_config.vh"
module cnn_top (
    input  wire clk,
    input  wire rst_n,
    input  wire start,
    input  wire signed [`DATA_WIDTH-1:0] weight_in,
    input wire  [`DATA_WIDTH-1:0] pixel_in,

    output wire signed [`OUTPUT_WIDTH-1:0] output_pixels,
    output wire output_valid,
    output wire last_output,
    output wire kernel_valid,
    output wire window_valid
);

    wire pixel_valid;
    wire start_conv ;
    wire load_weight;
    wire last_window;
    wire st_ReLU    ;
    wire conv_done  ;
    wire last_conv  ;
    wire finish_conv  ;

    wire signed [`OUTPUT_WIDTH-1:0] conv_pixels;

    wire signed [(`KERNEL_SIZE*`KERNEL_SIZE*`DATA_WIDTH)-1:0] kernel;
    wire [`KERNEL_SIZE*`KERNEL_SIZE*`DATA_WIDTH-1:0] window_flat;



    reg_kernel u_reg_kernel (
        .clk          (clk),
        .rst_n        (rst_n),
        .weight_valid (weight_valid),
        .weight_in    (weight_in),
        .kernel       (kernel),
        .kernel_valid (kernel_valid)
    );

    control_fsm u_fsm (
        .clk          (clk),
        .rst_n        (rst_n),
        .start        (start),
        .window_valid (window_valid),
        .last_window  (last_window),
        .kernel_valid (kernel_valid),
        .conv_done    (conv_done),
        .ReLU_done    (last_output),
        .pixel_valid  (pixel_valid),
        .weight_valid (weight_valid),
        .start_conv   (start_conv),
        .load_weight  (load_weight),
        .last         (last_conv)  ,
        .st_ReLU      (st_ReLU)
    );

    line_buff u_line_buff (
        .clk          (clk),
        .rst_n        (rst_n),
        .pixel_valid  (pixel_valid),
        .pixel_in     (pixel_in),
        .window_valid (window_valid),
        .last_window  (last_window),
        .window_flat  (window_flat)
    );

    PE_Array u_pe_array (
        .window        (window_flat),
        .kernel        (kernel),
        .load_weights  (load_weight),
        .start         (start_conv),
        .last_conv     (last_conv),
        .clk           (clk),
        .rst_n         (rst_n),
        .output_pixels (conv_pixels),
        .done          (conv_done),
        .finish_conv   (finish_conv)
    );

    ReLU u_ReLU (
        .st_ReLU     (st_ReLU),
        .last        (finish_conv),
        .conv_pixels (conv_pixels) ,
        .ReLU_pixels (output_pixels),
        .ReLU_done   (output_valid),
        .ReLU_last   (last_output)
    ); 

endmodule