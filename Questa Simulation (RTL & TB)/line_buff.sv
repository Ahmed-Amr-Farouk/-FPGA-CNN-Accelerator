`include "cnn_config.vh"
module line_buff (
    input wire clk,
    input wire rst_n,
    input wire pixel_valid,
    input wire [`DATA_WIDTH-1:0] pixel_in,
    output reg window_valid,
    output reg last_window,
    output reg [`KERNEL_SIZE*`KERNEL_SIZE*`DATA_WIDTH-1:0] window_flat
);

reg [`ADDRESS_WIDTH-1:0] col_cnt;
reg [`ADDRESS_WIDTH-1:0] row_cnt;
wire last_col;
assign last_col = (col_cnt == `IMAGE_SIZE-1);

// KERNEL_SIZE-1 row buffers (buf[1] = most recent finished row ... buf[KERNEL_SIZE-1] = oldest)
reg [`DATA_WIDTH-1:0] line_buf [1:`KERNEL_SIZE-1][0:`IMAGE_SIZE-1];

// tap[0] = current incoming pixel (freshest row), tap[KERNEL_SIZE-1] = oldest row
wire [`DATA_WIDTH-1:0] tap [0:`KERNEL_SIZE-1];
assign tap[0] = pixel_in;

genvar gi;
generate
    for (gi = 1; gi < `KERNEL_SIZE; gi = gi + 1) begin : g_taps
        assign tap[gi] = line_buf[gi][col_cnt];
    end
endgenerate

reg [`DATA_WIDTH-1:0] win [0:`KERNEL_SIZE-1][0:`KERNEL_SIZE-1];

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        col_cnt <= 0;
        row_cnt <= 0;
    end
    else if (pixel_valid) begin
        if (last_col) begin
            col_cnt <= 0;
            row_cnt <= row_cnt + 1'b1;
        end
        else begin
            col_cnt <= col_cnt + 1'b1;
        end
    end
end

// ---- row (line) buffers: shift each row's pixel down into the next-older buffer ----
integer i, k;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for (k = 1; k < `KERNEL_SIZE; k = k + 1)
            for (i = 0; i < `IMAGE_SIZE; i = i + 1)
                line_buf[k][i] <= 0;
    end
    else if (pixel_valid) begin
        for (k = `KERNEL_SIZE-1; k >= 2; k = k - 1)
            line_buf[k][col_cnt] <= line_buf[k-1][col_cnt];
        if (`KERNEL_SIZE > 1)
            line_buf[1][col_cnt] <= pixel_in;
    end
end

// ---- sliding window: shift columns left, load newest column from taps ----
integer r, c;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for (r = 0; r < `KERNEL_SIZE; r = r + 1)
            for (c = 0; c < `KERNEL_SIZE; c = c + 1)
                win[r][c] <= 0;
    end
    else if (pixel_valid) begin
        for (r = 0; r < `KERNEL_SIZE; r = r + 1) begin
            for (c = 0; c < `KERNEL_SIZE-1; c = c + 1)
                win[r][c] <= win[r][c+1];
        end
     
        for (r = 0; r < `KERNEL_SIZE; r = r + 1)
            win[r][`KERNEL_SIZE-1] <= tap[`KERNEL_SIZE-1-r];
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        window_valid <= 1'b0;
        last_window  <= 1'b0;
    end
    else if (pixel_valid) begin
        if ((row_cnt >= `KERNEL_SIZE-1) && (col_cnt >= `KERNEL_SIZE-1)) begin
            window_valid <= 1'b1;

            if ((row_cnt == `IMAGE_SIZE-1) && (col_cnt == `IMAGE_SIZE-1))
                last_window <= 1'b1;
            else
                last_window <= 1'b0;
        end
        else begin
            window_valid <= 1'b0;
            last_window  <= 1'b0;
        end
    end
end

//flatten
integer rr, cc;
always @(*) begin
    for (rr = 0; rr < `KERNEL_SIZE; rr = rr + 1) begin
        for (cc = 0; cc < `KERNEL_SIZE; cc = cc + 1) begin
            window_flat[(rr*`KERNEL_SIZE + cc)*`DATA_WIDTH +: `DATA_WIDTH]
                = win[rr][cc];
        end
    end
end

endmodule