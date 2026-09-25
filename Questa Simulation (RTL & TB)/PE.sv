`include "cnn_config.vh"
module PE (
    input  wire clk,
    input  wire rst_n,
    input  wire unsigned [`DATA_WIDTH-1:0] A,
    input  wire signed   [`DATA_WIDTH-1:0] B,
    input  wire start,
    output reg  signed   [(2*`DATA_WIDTH-1):0] C
);

    wire signed [`DATA_WIDTH:0] A_signed;
    
    (* use_dsp = "yes" *)
    wire signed [(2*`DATA_WIDTH):0] product_comb;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            C <= {(2*`DATA_WIDTH){1'b0}};
        else if (start)
            C <= product_comb;
    end

    assign A_signed = {1'b0, A};
    assign product_comb = A_signed * B;

endmodule