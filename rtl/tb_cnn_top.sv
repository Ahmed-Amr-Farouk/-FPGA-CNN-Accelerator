`timescale 1ns/1ps
`include "cnn_config.vh"
// ============================================================
// Self-checking testbench for cnn_top_old  (rename the DUT
// instantiation below to `cnn_top` once you swap in the
// non-"_old" top level)
// ------------------------------------------------------------
// This is tb_cnn_top_old.sv restructured so the exact same
// stream/capture/align/compare flow runs once per test vector
// that golden_model.py exports, instead of only the single
// primary kernel.mem/image.mem/relu_output.mem set:
//
//   1) the PRIMARY vector       : export_Test/{kernel,image,relu_output}.mem
//   2) the 4 "vectors/" images  : export_Test/vectors/<name>/{image,relu_output}.mem
//                                 (these reuse the PRIMARY kernel, per golden_model.py)
//   3) the 9-case multi-kernel  : export_Test/test_cases/<name>/{kernel,image,relu_output}.mem
//      suite from
//      export_multi_kernel_suite()
//
// NOTE: keep `MULTI_CASE_NAMES` / `VECTOR_CASE_NAMES` below in
// sync with golden_model.py's `plan` list (export_multi_kernel_suite)
// and `generate_test_images()` any time the python side changes -
// there's no dependency on case_list.txt so the two must be kept
// in sync by hand.
// ============================================================
module tb_cnn_top;

    localparam CLK_PERIOD    = 10;
    localparam TOTAL_PIXELS  = `IMAGE_SIZE * `IMAGE_SIZE;
    localparam NUM_WEIGHTS   = `KERNEL_SIZE * `KERNEL_SIZE;
    localparam OUT_ROWS      = `IMAGE_SIZE - `KERNEL_SIZE + 1;
    localparam NUM_GOLDEN    = OUT_ROWS * OUT_ROWS;

    // pipeline slack tolerated by the alignment search (unchanged
    // from tb_cnn_top_old.sv)
    localparam MAX_OFFSET    = 8;
    localparam DRAIN_CYCLES  = 30;
    localparam CAP_SLACK     = 10;

    // Root folder golden_model.py's Config.EXPORT_DIR writes into.
    // Adjust if you run the sim from somewhere else relative to it.
    localparam string EXPORT_ROOT = "export_Test";

    localparam int NUM_VECTOR_CASES = 4;
    string vector_case_names [0:NUM_VECTOR_CASES-1];

    localparam int NUM_MULTI_CASES = 9;
    string multi_case_names [0:NUM_MULTI_CASES-1];

    localparam int NUM_TOTAL_CASES = 1 + NUM_VECTOR_CASES + NUM_MULTI_CASES;

    // ---------------- DUT I/O ----------------
    reg  clk;
    reg  rst_n;
    reg  start;
    reg  signed [`DATA_WIDTH-1:0] weight_in;
    reg  [`DATA_WIDTH-1:0]        pixel_in;

    wire signed [`OUTPUT_WIDTH-1:0] output_pixels;
    wire output_valid;
    wire last_output;
    wire kernel_valid;
    wire window_valid;

    // ---------------- reference data (reloaded per case) ----------------
    reg signed [`DATA_WIDTH-1:0] kernel_rom [0:NUM_WEIGHTS-1];
    reg        [`DATA_WIDTH-1:0] image_mem  [0:TOTAL_PIXELS-1];
    reg signed [15:0]            golden_mem [0:NUM_GOLDEN-1];

    // captured DUT outputs (+ slack for alignment search)
    reg signed [`OUTPUT_WIDTH-1:0] captured [0:NUM_GOLDEN+CAP_SLACK-1];
    integer captured_count;

    // loop index for the outer case-selection loops ONLY - run_case()
    // has its own local pixel-streaming index so the two never alias
    // (they used to share one `i`, which silently truncated every
    // outer for-loop to a single iteration)
    integer case_idx;

    // running totals across every case
    integer total_cases, passed_cases, failed_cases;

    // ---------------- DUT instance ----------------
    cnn_top dut (
        .clk           (clk),
        .rst_n         (rst_n),
        .start         (start),
        .weight_in     (weight_in),
        .pixel_in      (pixel_in),
        .output_pixels (output_pixels),
        .output_valid  (output_valid),
        .last_output   (last_output),
        .kernel_valid  (kernel_valid),
        .window_valid  (window_valid)
    );

    // ---------------- clock ----------------
    always #(CLK_PERIOD/2) clk = ~clk;

    // ---------------- capture every valid output sample ----------------
    always @(posedge clk) begin
        if (rst_n && output_valid && (captured_count < NUM_GOLDEN+CAP_SLACK)) begin
            captured[captured_count] <= output_pixels;
            captured_count           <= captured_count + 1;
        end
    end

    // ---------------- live monitor ----------------
    always @(posedge clk) begin
        if (rst_n && output_valid) begin
            $display("[t=%0t] sample #%0d -> output_pixels = %0d (0x%0h)",
                      $time, captured_count, $signed(output_pixels), output_pixels);
        end
    end

    // ============================================================
    // run_case: loads one {kernel,image,golden} .mem trio, resets
    // the DUT, streams the whole image through, waits for drain,
    // then self-checks against golden with the same offset-search
    // tb_cnn_top_old.sv used - but tallies pass/fail instead of
    // $stop-ing on the first case.
    // ============================================================
    task automatic run_case(input string case_label,
                             input string kernel_path,
                             input string image_path,
                             input string golden_path);
        integer offset, best_offset, errs, best_errs, k;
        integer local_errors;
        integer px;  // local pixel-streaming index - do not reuse case_idx here
        reg signed [`OUTPUT_WIDTH-1:0] exp;
        reg signed [`OUTPUT_WIDTH-1:0] got;
        begin
            $readmemh(kernel_path, kernel_rom);
            $readmemh(image_path,  image_mem);
            $readmemh(golden_path, golden_mem);

            // ---- reset DUT for a clean run of this case ----
            rst_n          = 0;
            start          = 0;
            weight_in      = 0;
            pixel_in       = 0;
            captured_count = 0;
            repeat (5) @(posedge clk);
            rst_n = 1;
            repeat (2) @(posedge clk);

            // pulse start -> FSM leaves IDLE and moves into LOAD
            start = 1;
            @(posedge clk);
            start = 0;

            // Stream the whole image in, one pixel per cycle; the
            // first NUM_WEIGHTS cycles also carry the kernel weights.
            for (px = 0; px < TOTAL_PIXELS; px = px + 1) begin
                pixel_in  = image_mem[px];
                weight_in = (px < NUM_WEIGHTS) ? kernel_rom[px] : {`DATA_WIDTH{1'b0}};
                @(posedge clk);
            end

            wait (last_output === 1'b1);
            repeat (DRAIN_CYCLES) @(posedge clk);

            // ---- self-check with alignment search ----
            $display("==================================================");
            $display("CASE [%s]: captured %0d samples, expected %0d",
                       case_label, captured_count, NUM_GOLDEN);

            best_offset = 0;
            best_errs   = NUM_GOLDEN + 1;
            for (offset = 0; offset <= MAX_OFFSET; offset = offset + 1) begin
                errs = 0;
                for (k = 0; k < NUM_GOLDEN; k = k + 1) begin
                    exp = {{(`OUTPUT_WIDTH-16){golden_mem[k][15]}}, golden_mem[k]};
                    if ((k+offset >= captured_count) || (captured[k+offset] !== exp))
                        errs = errs + 1;
                end
                if (errs < best_errs) begin
                    best_errs   = errs;
                    best_offset = offset;
                end
            end

            local_errors = 0;
            for (k = 0; k < NUM_GOLDEN; k = k + 1) begin
                exp = {{(`OUTPUT_WIDTH-16){golden_mem[k][15]}}, golden_mem[k]};
                if ((k+best_offset >= captured_count) || (captured[k+best_offset] !== exp)) begin
                    local_errors = local_errors + 1;
                    if (local_errors <= 10) begin
                        got = (k+best_offset < captured_count) ? captured[k+best_offset] : {`OUTPUT_WIDTH{1'bx}};
                        $display("  MISMATCH[%0d]: expected=%0d got=%0d", k, $signed(exp), $signed(got));
                    end
                end
            end

            total_cases = total_cases + 1;
            if (local_errors == 0) begin
                passed_cases = passed_cases + 1;
                $display("CASE [%s][%d]: PASSED (alignment offset = %0d)", case_label,total_cases , best_offset);
            end
            else begin
                failed_cases = failed_cases + 1;
                $display("CASE [%s][%d]: FAILED  %0d / %0d mismatches (best alignment offset = %0d)",
                           case_label,total_cases, local_errors, NUM_GOLDEN, best_offset);
            end
            $display("==================================================");
        end
    endtask

    // ---------------- stimulus: run every case in sequence ----------------
    initial begin
        clk          = 0;
        total_cases  = 0;
        passed_cases = 0;
        failed_cases = 0;

        // must mirror generate_test_images() / export_multi_kernel_suite()'s
        // `plan` list in golden_model.py - update both sides together
        vector_case_names[0] = "zeros";
        vector_case_names[1] = "max_value";
        vector_case_names[2] = "checkerboard";
        vector_case_names[3] = "ramp";

        multi_case_names[0] = "showcase_identity";
        multi_case_names[1] = "showcase_edge_h";
        multi_case_names[2] = "showcase_edge_v";
        multi_case_names[3] = "showcase_sharpen";
        multi_case_names[4] = "showcase_box_blur";
        multi_case_names[5] = "checkerboard_box_blur";
        multi_case_names[6] = "ramp_edge_h";
        multi_case_names[7] = "max_value_sharpen";
        multi_case_names[8] = "random_edge_v";

        // 1) PRIMARY vector: export_Test/{kernel,image,relu_output}.mem
        run_case("primary/random",
                 {EXPORT_ROOT, "/kernel.mem"},
                 {EXPORT_ROOT, "/image.mem"},
                 {EXPORT_ROOT, "/relu_output.mem"});

        // 2) vectors/<name>: same kernel as the primary, different image
        for (case_idx = 0; case_idx < NUM_VECTOR_CASES; case_idx = case_idx + 1) begin
            run_case({"vectors/", vector_case_names[case_idx]},
                      {EXPORT_ROOT, "/kernel.mem"},
                      {EXPORT_ROOT, "/vectors/", vector_case_names[case_idx], "/image.mem"},
                      {EXPORT_ROOT, "/vectors/", vector_case_names[case_idx], "/relu_output.mem"});
        end

        // 3) test_cases/<name>: own kernel + image + golden per case
        for (case_idx = 0; case_idx < NUM_MULTI_CASES; case_idx = case_idx + 1) begin
            run_case({"test_cases/", multi_case_names[case_idx]},
                      {EXPORT_ROOT, "/test_cases/", multi_case_names[case_idx], "/kernel.mem"},
                      {EXPORT_ROOT, "/test_cases/", multi_case_names[case_idx], "/image.mem"},
                      {EXPORT_ROOT, "/test_cases/", multi_case_names[case_idx], "/relu_output.mem"});
        end

        $display("##################################################");
        $display("FINAL SUMMARY: %0d total, %0d passed, %0d failed",
                   total_cases, passed_cases, failed_cases);
        if (failed_cases == 0)
            $display("ALL %0d TEST CASES PASSED", total_cases);
        else
            $display("%0d / %0d TEST CASES FAILED", failed_cases, total_cases);
        $display("##################################################");

        $stop;
    end

    // ---------------- watchdog (scaled for NUM_TOTAL_CASES runs) ----------------
    initial begin
        #(CLK_PERIOD*300000*(NUM_TOTAL_CASES+2));
        $display("TIMEOUT: simulation did not finish in time");
        $stop;
    end

endmodule