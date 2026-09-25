`include "cnn_config.vh"
module ReLU (
    input wire st_ReLU,
    input wire last   ,
    input wire signed [`OUTPUT_WIDTH-1:0] conv_pixels ,
    output reg signed [`OUTPUT_WIDTH-1:0] ReLU_pixels,
    output reg ReLU_done,
    output ReLU_last
);
    always @(*) begin
        if (st_ReLU) begin
            ReLU_done   = 1'b1 ;
            if (conv_pixels [`OUTPUT_WIDTH-1]) begin
                ReLU_pixels = 'b0 ;
            end
            else begin
                ReLU_pixels = conv_pixels ;
            end
        end
        else begin
            ReLU_pixels = 'b0  ;
            ReLU_done   = 1'b0 ;
        end
    end

    assign ReLU_last = ReLU_done & last;
endmodule