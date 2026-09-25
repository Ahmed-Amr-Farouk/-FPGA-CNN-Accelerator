# FPGA CNN Accelerator — N×N Convolution Engine

**IEEE SSCS Egypt Chapter — 2026 Student Design Competition**
FPGA-Based Edge-AI Vision Accelerator performing streaming N×N CNN convolution on a grayscale image / feature map.

Team: **The Bit Spies**
Saif Eldeen Fathi Ali · Ahmed Amr Farouk · Toka Abdelhamed Mohamed · ALaa Kareem Abdelmola
Capital University / Helwan University — Electronics & Communication Engineering

---

## 1. Overview

This project implements a **pipelined, streaming N×N CNN convolution accelerator** in RTL (SystemVerilog), synthesized and implemented on a real FPGA board (Vivado). It performs valid, stride-1 cross-correlation between an 8-bit unsigned grayscale image stream and a programmable 8-bit signed N×N kernel, with an optional ReLU activation stage. The design is verified bit-exact against a Python/NumPy golden model before FPGA implementation.

## 2. Specification Compliance Summary

| Parameter | Specification | Result | Units | Notes |
|---|---|---|---|---|
| Input image size | ≥ 32×32 | 32×32 | pixels | `IMAGE_SIZE = 32`, single-channel |
| Input precision | Unsigned fixed-point | 8-bit unsigned | bits | `DATA_WIDTH = 8` |
| Kernel precision | 8-bit signed | 8-bit signed | bits | Two's-complement, loaded via `weight_in` |
| Architecture type | — | Pipelined systolic PE array, line-buffer based | — | Streaming, valid convolution |
| Multipliers / MACs | — | 9 (N² for N=3) | DSP48 | One PE per kernel tap |
| Pipeline stages | — | 3 (per PE) + control overhead | cycles | See §6 |
| Latency | — | ≈ 73 | cycles | Estimated fill latency to first valid output |
| Throughput | px/cycle (per spec) | 900 / 973 ≈ 0.925 | output px/cycle | See §9 |
| FPGA utilization | — | LUT 491, LUTRAM 1, FF 902, DSP 9, IO 43 | — | Vivado implemented design, §8 |
| Maximum frequency | — | ≈ 209.8 | MHz | 4.766 ns clock period, timing closed |
| Power estimate | — | 0.131 – 0.163 | W | Vivado power report; low = vectorless/constraints-based, high = SAIF-based, §8.3 |
| Verification status | — | **PASS** vs. Python golden model | — | §7 |
| FoM | Throughput / (Power × (LUTs + 50·DSPs + 100·BRAMs)) | ≈ 1,265,300 – 1,574,300 | (px/s)/(W·resource-unit) | See §9 |

## 3. Requirement-by-Requirement Mapping

| # | Requirement | Implementation |
|---|---|---|
| 1 | Min. 32×32 input, single-channel | `IMAGE_SIZE = 32` (parameterizable in `cnn_config.vh`); `pixel_in` is a single 8-bit stream |
| 2 | Unsigned fixed-point input | 8-bit unsigned `pixel_in` (Q8.0) |
| 3 | Programmable N×N kernel | `reg_kernel` serially loads N²=9 signed coefficients via `weight_in` / `weight_valid` |
| 4 | 8-bit signed kernel | `DATA_WIDTH = 8`, two's-complement weights |
| 5 | Stride = 1 | `line_buff` advances the sliding window by exactly one column per valid pixel |
| 6 | Output ≥16-bit signed, overflow handling | `OUTPUT_WIDTH = 2·DATA_WIDTH + ⌈log2(K²)⌉ = 20 bits`; ReLU stage saturates negative results to zero |
| 7 | Optional ReLU (bonus) | Dedicated ReLU module: `f(x) = max(0, x)`, gated by `st_ReLU` from the FSM |
| 8 | Verification vs. golden model | Python/NumPy `golden_model.py` + self-checking SystemVerilog testbench (`tb_cnn_top.sv`), bit-exact compare (§7) |
| 9 | FPGA synthesis/implementation results | Real Vivado synthesis + implementation results (§8) |
| 10 | Figure of Merit | Computed in §9 from real resource/power figures |
| Bonus | One output pixel per cycle (pipelined) | PE array + line buffer fully pipelined; steady-state throughput ≈1 px/cycle (§6) |
| Bonus | ReLU activation | Implemented (see #7) |

## 4. Architecture

The accelerator streams the input image pixel-by-pixel into a **line-buffer / sliding-window unit** that forms a N×N window every cycle once enough rows/columns have been seen. The window feeds a **systolic array of Processing Elements (PEs)**, one per kernel tap, each computing a signed×unsigned partial product and pipelining it through a fixed-latency multiply-accumulate chain. The programmable kernel is loaded once (serially, one 8-bit coefficient per cycle) into `reg_kernel` before streaming begins. A **ReLU stage** optionally clips negative results to zero before the pixel is presented on `output_pixels`. A single control FSM (`control_fsm`) sequences kernel loading and the convolution/streaming phase.

### 4.1 Module list

| Module | File | Role |
|---|---|---|
| `cnn_top` | `cnn_top.sv` | Top-level integration; wires all submodules together |
| `control_fsm` | `FSM.sv` | 3-state control FSM: `IDLE → LOAD → CONV` |
| `reg_kernel` | `REG_Kernel.sv` | Serially-loaded N×N signed kernel coefficient register file |
| `line_buff` | `line_buff.sv` | Row-delay line buffers + N×N sliding-window generation (`window_gen`) |
| `PE` | `PE.sv` | Single processing element: signed×unsigned multiply (mapped to a DSP48 slice), 3-stage pipeline |
| `PE_Array` | instantiated in `cnn_top` as `u_pe_array` | Array of 9 PEs (one per kernel tap) + accumulate/adder tree producing `conv_pixels`; drives `done`/`finish_conv` |
| `ReLU` | `ReLU.sv` | Optional ReLU post-processing stage; also gates `last_output` |

### 4.2 Control FSM

- **IDLE** — waits for `start`; all datapath enables de-asserted.
- **LOAD** — streams `weight_in` into `reg_kernel` (`weight_valid` high) while simultaneously beginning to stream the first image rows into `line_buff`, so the first window is ready the moment the kernel finishes loading (`kernel_valid`).
- **CONV** — main streaming/compute phase; `start_conv` follows `window_valid`, `st_ReLU` is asserted once `conv_done` indicates a valid result; `last` is asserted on the `last_window` pulse and propagated through `ReLU_last` back to the FSM as `ReLU_done`, returning the machine to `IDLE`.

## 5. Fixed-Point Bit-Width Analysis

| Signal | Format | Width | Justification |
|---|---|---|---|
| Input pixel (`pixel_in`) | Unsigned (Q8.0) | 8 bits | Standard 8-bit grayscale depth; matches spec #2, resource-efficient for an edge accelerator |
| Kernel coefficient (`weight_in`) | Signed, two's-complement | 8 bits | Mandated by spec #4 |
| PE product (A×B) | Signed | 16 bits | `DATA_WIDTH×2` — minimum width that cannot overflow an 8-bit unsigned × 8-bit signed product |
| Convolution output (`conv_pixels` / `output_pixels`) | Signed | 20 bits (`2·DATA_WIDTH + ⌈log2(K²)⌉ = 16+4`) | Guard bits so the full 9-term dot product of full-range operands cannot overflow; exceeds the mandated 16-bit minimum (spec #6) |
| ReLU output | Signed | 20 bits | `f(x) = max(0, x)`; negative results zeroed rather than saturated/wrapped |

`OUTPUT_WIDTH` is derived symbolically from `DATA_WIDTH` and `KERNEL_SIZE`, so changing the kernel size in `cnn_config.vh` automatically keeps the accumulator wide enough to avoid overflow — no separate saturation logic is needed in the convolution path for the N×N configuration; only the ReLU stage performs a data-dependent clamp (to zero).

## 6. Pipeline / Timing Behaviour

Each `PE` uses a native signed multiply so Vivado infers a DSP48 slice directly, followed by two register stages (post-multiply and output), giving each PE a fixed **3-cycle latency** regardless of kernel size. The PE array's `done`/`finish_conv` chain is tuned for this 3-cycle PE latency. `line_buff` advances the window by one pixel per valid cycle; `window_valid` is asserted once `row_cnt` and `col_cnt` both reach `KERNEL_SIZE−1`, and `last_window` marks the final (bottom-right) window of the frame. Once the pipeline is full, the design produces **one output pixel per valid cycle**.

> ⚠️ Open note: a designer comment in `FSM.sv` flags that the row-to-row transition gap in `line_buff` should be re-checked against the PE's current 3-cycle latency (it was originally tuned for an earlier 2-cycle PE) — see §10.

## 7. Verification Methodology

A **Python/NumPy golden reference model** (`golden_model.py`) performs the same valid, stride-1, cross-correlation convolution as the RTL — unsigned 8-bit input, signed 8-bit kernel, optional ReLU, saturated to a 16-bit signed range — and exports kernel/image/expected-output vectors as `$readmemh`-compatible hex files (`kernel.mem`, `image.mem`, `relu_output.mem`).

A **self-checking SystemVerilog testbench** (`tb_cnn_top.sv`) drives the DUT with these vectors, captures every output pixel, aligns the captured stream against the golden output (tolerating pipeline slack), and reports a PASS/FAIL with mismatch count. Beyond the primary N×N vector, the testbench also runs a set of **edge-case images** (all-zero, full-scale, checkerboard, ramp) and a **multi-kernel regression suite** generated by `golden_model.py`, exercising symmetric, anti-symmetric, and saturating kernels.

## 8. FPGA Implementation Results

Synthesized and implemented in **Vivado**, targeting the **PYNQ-Z2 board (XC7Z020-1CLG400C)**, with a **209.8 MHz** system clock (4.766 ns period, per `Constraints_cnn_top.xdc`). Figures below are real post-implementation results, not estimates.

### 8.1 Resource utilization

| Resource | Utilization | Available | Utilization % |
|---|---|---|---|
| LUT | 491 | 53,200 | 0.92% |
| LUTRAM | 1 | 17,400 | 0.01% |
| FF | 902 | 106,400 | 0.85% |
| DSP | 9 | 220 | 4.09% |
| IO | 43 | 125 | 34.40% |

### 8.2 Timing

- Worst Negative Slack (WNS): **0.013 ns** — setup met, 0 failing endpoints out of 1,745
- Worst Hold Slack (WHS): **0.162 ns** — hold met, 0 failing endpoints out of 1,745
- Worst Pulse Width Slack (WPWS): **1.402 ns** — met, 0 failing endpoints out of 913
- All user-specified timing constraints are met at the 209.8 MHz target frequency.

### 8.3 Power

Two post-implementation power reports were generated, differing in the switching-activity source supplied to Vivado:

**Without SAIF (vectorless/constraints-based estimate):**
- Total on-chip power: **0.131 W**
- Dynamic power: 0.025 W (19%) — Clocks 0.007 W, Signals 0.009 W, Logic 0.003 W, DSP ≈0.000 W, I/O 0.006 W
- Device static power: 0.106 W (81%)
- Junction temperature: 26.5 °C; thermal margin 58.5 °C (4.9 W headroom); confidence level: Low (activity derived from constraints/vectorless analysis rather than a full simulation testbench)

**With SAIF (simulation-derived switching activity):**
- Total on-chip power: **0.163 W**
- Dynamic power: 0.057 W (35%) — Clocks 0.008 W, Signals 0.018 W, Logic 0.010 W, DSP 0.015 W, I/O 0.006 W
- Device static power: 0.107 W (65%)
- Junction temperature: 26.9 °C; thermal margin 58.1 °C (4.9 W headroom); confidence level: Medium

## 9. Figure of Merit (FoM)

Per the competition formula: `FOM = Throughput / (Power × (LUTs + 50·DSPs + 100·BRAMs))`, throughput in output pixels/cycle.

Using real implementation results (LUTs = 491, DSPs = 9, BRAMs = 0):

- LUT-equivalent denominator = 491 + 50×9 + 100×0 = **941**
- Estimated fill latency ≈ 73 cycles; full 30×30 = 900-pixel output frame ≈ 73 + 900 = **973 cycles**
- Throughput (spec units) = 900 / 973 ≈ **0.925 output px/cycle**

Two FoM values follow from the two power figures in §8.3:

**Without SAIF (0.131 W):**
- Power × denominator = 0.131 × 941 ≈ **123.27**
- **FOM (spec units) ≈ 7.50×10⁻³** (output px/cycle)/(W·resource-unit)
- Equivalently, at the 209.8 MHz implemented clock: Throughput ≈ (900/973) × 209,800,000 ≈ **194,065,000 output px/s**, giving **FOM ≈ 1,574,300** (output px/s)/(W·resource-unit)

**With SAIF (0.163 W):**
- Power × denominator = 0.163 × 941 ≈ **153.38**
- **FOM (spec units) ≈ 6.03×10⁻³** (output px/cycle)/(W·resource-unit)
- Equivalently, at 209.8 MHz: FOM ≈ 194,065,000 / 153.38 ≈ **1,265,300** (output px/s)/(W·resource-unit)

Both power figures describe the same design — see §10 for which power report and FoM unit convention to report in the final Table 1.

## 10. Design Tradeoffs & Open Items

**Tradeoffs**
- `PE.sv` uses a native signed multiply (unsigned pixel zero-extended by one bit) so Vivado maps it directly onto a DSP48 slice rather than a LUT-based shift-add tree — trading extra multiplier bit-width for lower LUT usage and better timing.
- The PE's multiply and output are split into two register stages purely to preserve a fixed 3-cycle PE latency, so the rest of the pipeline needed no re-tuning when the multiply implementation changed.
- `OUTPUT_WIDTH` is derived symbolically instead of hand-picked, so the design generalizes to other kernel sizes without manual overflow re-analysis.

**Open items for a fully finished submission**
- `PE_Array.sv` (instantiated as `u_pe_array`) RTL should be added/verified against the schematic-inferred structure.
- The `line_buff` row-to-row transition gap needs re-checking against the PE's current 3-cycle latency (tuned earlier for a 2-cycle PE).
- The ≈73-cycle latency and resulting FoM are currently analytical; a simulation waveform/testbench log showing measured cycle count would substantiate §9.
- Actual PASS/FAIL testbench logs (mismatch counts per vector) should be included to substantiate §7.
- Decide which FoM unit convention (px/cycle vs. px/s) to report in the final Table 1.
- Confirm BRAM = 0 is intentional (no on-chip frame buffer; design streams pixels rather than buffering a full frame).

## 11. Repository Structure & Deliverables

```
.
├── FPGA_Vivado/                     # Vivado project (synthesis, implementation, bitstream, constraints)
├── RTL/                             # SystemVerilog source for the accelerator
│   ├── cnn_config.vh                # Global parameters: IMAGE_SIZE, KERNEL_SIZE, DATA_WIDTH, OUTPUT_WIDTH, AW
│   ├── cnn_top.sv                   # Top-level integration module
│   ├── FSM.sv                       # Control FSM (control_fsm)
│   ├── REG_Kernel.sv                # Programmable kernel coefficient register file (reg_kernel)
│   ├── line_buff.sv                 # Row-delay line buffer / sliding-window generator
│   ├── PE.sv                        # Single processing element (DSP48-mapped multiply, 3-stage pipeline)
│   └── ReLU.sv                      # Optional ReLU post-processing stage
├── export_Test/                     # Exported test vectors / simulation outputs
└── verification && golden model/    # Verification environment
    ├── golden_model.py              # Python/NumPy golden reference model + test-vector generator
    └── tb_cnn_top.sv                # Self-checking SystemVerilog testbench
```

| File | Description |
|---|---|
| `cnn_config.vh` | Global parameters: `IMAGE_SIZE`, `KERNEL_SIZE`, `DATA_WIDTH`, `OUTPUT_WIDTH`, `AW` |
| `cnn_top.sv` | Top-level integration module |
| `FSM.sv` | Control FSM (`control_fsm`) |
| `REG_Kernel.sv` | Programmable kernel coefficient register file (`reg_kernel`) |
| `line_buff.sv` | Row-delay line buffer / sliding-window generator |
| `PE.sv` | Single processing element (DSP48-mapped multiply, 3-stage pipeline) |
| `ReLU.sv` | Optional ReLU post-processing stage |
| `golden_model.py` | Python/NumPy golden reference model and test-vector generator |
| `tb_cnn_top.sv` | Self-checking SystemVerilog testbench |
| `Constraints_cnn_top.xdc` | Pin assignment and 209.8 MHz clock constraint for the PYNQ-Z2 board |

## 12. Getting Started

### Prerequisites
- Xilinx **Vivado** (with support for the Zynq-7000 / PYNQ-Z2 device, `XC7Z020-1CLG400C`)
- **Python 3** + NumPy (for `golden_model.py`)
- A SystemVerilog simulator (Vivado XSIM or ModelSim/QuestaSim) for `tb_cnn_top.sv`

### Simulation & verification
```bash
# 1. Generate golden vectors
python golden_model.py

# 2. Simulate the RTL against the generated vectors
#    (run tb_cnn_top.sv in Vivado XSIM or your simulator of choice)
#    -> reports PASS/FAIL and mismatch count vs. the golden model
```

### FPGA implementation
1. Open the Vivado project in `FPGA_Vivado/`.
2. Add the RTL sources from `RTL/`.
3. Apply `Constraints_cnn_top.xdc` (targets the PYNQ-Z2 board, 209.8 MHz clock).
4. Run Synthesis → Implementation → Generate Bitstream.
5. Compare post-implementation utilization/timing/power reports against §8.
