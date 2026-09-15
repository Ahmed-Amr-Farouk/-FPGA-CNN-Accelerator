`include "cnn_config.vh"
module PE (
    input  wire                                clk,
    input  wire                                rst_n,
    input  wire unsigned [`DATA_WIDTH-1:0]     A,
    input  wire signed   [`DATA_WIDTH-1:0]     B,
    input  wire                                start,
    output reg  signed   [(2*`DATA_WIDTH-1):0] C
);

    // ------------------------------------------------------------
    // Native multiply -> Vivado infers a DSP48 slice here instead
    // of a LUT-based shift-add tree. A_reg is unsigned, so we
    // zero-extend it by one bit to make it a valid non-negative
    // "signed" operand for the signed multiply; the result is
    // mathematically identical to the old magnitude+sign-fix method.
    // ------------------------------------------------------------
    wire signed [`DATA_WIDTH:0] A_ext;
    assign A_ext = {1'b0, A};
    (* use_dsp = "yes" *)

    wire signed [(2*`DATA_WIDTH-1):0] product_comb;
    assign product_comb = A_ext * B;

    

    // ------------------------------------------------------------
    // Stage 2: Output register (unchanged behavior)
    // ------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            C <= {(2*`DATA_WIDTH){1'b0}};
        else if (start)
            C <= product_comb;
    end

endmodule