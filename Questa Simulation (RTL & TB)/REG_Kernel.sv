`include "cnn_config.vh"
module reg_kernel (
    input wire clk,
    input wire rst_n,
    input wire weight_valid,
    input  wire signed [`DATA_WIDTH-1:0] weight_in,
    output reg signed [(`KERNEL_SIZE*`KERNEL_SIZE*`DATA_WIDTH)-1:0] kernel,
    output reg kernel_valid
);
reg [$clog2(`KERNEL_SIZE*`KERNEL_SIZE)-1:0] count;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        kernel<= 'b0;
        count<= 'b0;
        kernel_valid <=1'b0;
    end
    else begin
        if (weight_valid) begin
            kernel_valid <= 1'b0;
            kernel[count*`DATA_WIDTH +: `DATA_WIDTH] <= weight_in;
            if (count ==`KERNEL_SIZE*`KERNEL_SIZE-1) begin
                count <= 'b0;
                kernel_valid <= 1'b1;
            end
            else begin
                count <= count + 1'b1;
            end
        end
        else begin
        count<= 'b0;
        kernel_valid <=1'b0;
        end
    end
end
endmodule