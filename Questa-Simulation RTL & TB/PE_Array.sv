`include "cnn_config.vh"

module PE_Array (
    input  wire unsigned [`FLATTENED_SIZE-1:0] window,
    input  wire signed   [`FLATTENED_SIZE-1:0] kernel,
    input  wire load_weights,
    input  wire start,
    input  wire last_conv,
    input  wire clk,
    input  wire rst_n,
    output reg  signed [`OUTPUT_WIDTH -1:0] output_pixels,
    output reg  done,
    output reg  finish_conv
);

    function integer adder_nodes(input integer init_count, input integer lvl);
        adder_nodes = (init_count + ((1 << lvl) - 1)) >> lvl;
    endfunction

    localparam MID_COUNT  = adder_nodes(`N_PE, `MID_LEVEL);

    reg unsigned [`FLATTENED_SIZE-1:0] window_reg;
    reg signed   [`FLATTENED_SIZE-1:0] kernel_reg;
    wire signed [(2*`DATA_WIDTH-1):0] pe_out [0:`N_PE-1];
    reg  [2:0] pip_done, pip_last;
    wire signed [`OUTPUT_WIDTH-1:0] sum_tree1 [0:`MID_LEVEL][0:`N_PE-1];
    wire signed [`OUTPUT_WIDTH-1:0] sum_tree2 [0:`LEVELS2][0:MID_COUNT-1];
    reg signed [`OUTPUT_WIDTH-1:0] sum_mid_reg [0:MID_COUNT-1];
    genvar i,lvl1,idx1,lvl2, idx2;
    integer k;


    //PE instantiation
    generate
        for (i = 0; i < `N_PE; i = i + 1) begin : gen_pe
            PE P0 (
                .clk (clk),
                .rst_n (rst_n),
                .A (window_reg[(i+1)*`DATA_WIDTH-1 : i*`DATA_WIDTH]),
                .B (kernel_reg[(i+1)*`DATA_WIDTH-1 : i*`DATA_WIDTH]),
                .start (pip_done[0]),
                .C (pe_out[i]));
        end
    endgenerate

    // 1st tree level
    generate
        for (idx1 = 0; idx1 < `N_PE; idx1 = idx1 + 1) begin : gen_s1_level0
        assign sum_tree1[0][idx1] = $signed(pe_out[idx1]);
        end
    endgenerate

    generate
        for (lvl1 = 1; lvl1 <= `MID_LEVEL; lvl1 = lvl1 + 1) begin : gen_s1_level
            for (idx1 = 0; idx1 < adder_nodes(`N_PE, lvl1); idx1 = idx1 + 1) begin : gen_s1_node
                if (2*idx1 + 1 < adder_nodes(`N_PE, lvl1-1)) begin
                    assign sum_tree1[lvl1][idx1] = sum_tree1[lvl1-1][2*idx1] + sum_tree1[lvl1-1][2*idx1+1];
                end else begin
                    assign sum_tree1[lvl1][idx1] = sum_tree1[lvl1-1][2*idx1];
                end
            end
        end
    endgenerate

    //Pipeline register

    always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for (k = 0; k < MID_COUNT; k = k + 1)
            sum_mid_reg[k] <= 0;
    end
    else if (pip_done[1]) begin
        for (k = 0; k < MID_COUNT; k = k + 1)
            sum_mid_reg[k] <= sum_tree1[`MID_LEVEL][k];
    end
     end


    generate
        for (idx2 = 0; idx2 < MID_COUNT; idx2 = idx2 + 1) begin : gen_s2_level0
            assign sum_tree2[0][idx2] = sum_mid_reg[idx2];
        end
    endgenerate
    //2nd tree level
    generate
        for (lvl2 = 1; lvl2 <= `LEVELS2; lvl2 = lvl2 + 1) begin : gen_s2_level
            for (idx2 = 0; idx2 < adder_nodes(MID_COUNT, lvl2); idx2 = idx2 + 1) begin : gen_s2_node
                if (2*idx2 + 1 < adder_nodes(MID_COUNT, lvl2-1)) begin
                    assign sum_tree2[lvl2][idx2] = sum_tree2[lvl2-1][2*idx2] + sum_tree2[lvl2-1][2*idx2+1];
                end else begin
                    assign sum_tree2[lvl2][idx2] = sum_tree2[lvl2-1][2*idx2];
                end
            end
        end
    endgenerate

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            kernel_reg     <= 0;
            window_reg     <= 0;
            output_pixels  <= 0;
            done           <= 0;
            pip_done       <= 0;
            finish_conv    <= 0;
            pip_last       <= 0;
        end
        else begin
            if (load_weights) kernel_reg <= kernel;

            if (start) begin
                window_reg  <= window;
                pip_done[0] <= 1;
                if (last_conv) pip_last[0] <= 1;
                else           pip_last[0] <= 0;
            end
            else begin
                pip_done[0] <= 0;
                pip_last[0] <= 0;
            end

            {done, pip_done[2:1]} <= pip_done;
            {finish_conv, pip_last[2:1]} <= pip_last;
            output_pixels <=sum_tree2[`LEVELS2][0];
        end
    end

     
endmodule