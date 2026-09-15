# FPGA CNN Accelerator

Hardware accelerator for Convolutional Neural Network (CNN) inference, implemented in RTL (Verilog/VHDL) and targeted for FPGA deployment via Xilinx Vivado. The design is validated against a software golden model to verify functional correctness before hardware bring-up.

## ✨ Features

- RTL implementation of core CNN operations (convolution, activation, pooling — *adjust to match your actual modules*)
- Vivado project for synthesis, implementation, and bitstream generation
- Testbench-based verification flow with a golden reference model for output comparison
- Exported test vectors / results for validation

> ⚠️ Update this section with the specifics of your design: target FPGA board, supported layer types, data precision (e.g. INT8/FP16), clock frequency, and any resource utilization or performance numbers.

## 📁 Repository Structure

```
.
├── FPGA_Vivado/                  # Vivado project files (synthesis, implementation, bitstream)
├── RTL/                          # Verilog/VHDL source code for the accelerator modules
├── export_Test/                  # Exported test data / simulation outputs
└── verification && golden model/ # Testbenches + software golden model for output verification
```

## 🛠️ Prerequisites

- **Xilinx Vivado** (specify version, e.g. 2020.2 or later)
- Target FPGA board (e.g. *Zynq-7000, Artix-7, ...* — fill in your actual board)
- A simulator supported by Vivado (XSIM) or a third-party simulator (ModelSim/QuestaSim) if used
- Python / MATLAB (if the golden model was built with either) for generating reference outputs

## 🚀 Getting Started

1. **Clone the repository**
   ```bash
   git clone https://github.com/Ahmed-Amr-Farouk/-FPGA-CNN-Accelerator.git
   cd -FPGA-CNN-Accelerator
   ```

2. **Open the Vivado project**
   - Launch Vivado and open the project file inside `FPGA_Vivado/`.

3. **Run simulation**
   - Use the testbenches provided under `verification && golden model/` to simulate the RTL design in Vivado's simulator.

4. **Compare against the golden model**
   - The golden model produces expected outputs used to validate the RTL simulation results located under `export_Test/`.

5. **Synthesize and implement**
   - Run synthesis → implementation → bitstream generation from the Vivado project to target your FPGA board.

## ✅ Verification Flow

The design correctness is verified by comparing the RTL simulation outputs against a software-based golden model:

1. The golden model computes the expected CNN output for a given input (e.g. an image or feature map).
2. The RTL design is simulated with the same input.
3. Outputs are exported (`export_Test/`) and compared against the golden model results to confirm functional correctness.

## 📊 Results

| Metric | Value |
|---|---|
| Target FPGA | *TBD* |
| Clock Frequency | *TBD* |
| Resource Utilization (LUT/FF/DSP/BRAM) | *TBD* |
| Inference Latency | *TBD* |
| Accuracy vs. Golden Model | *TBD* |

## 👤 Author

**Ahmed Amr Farouk**
GitHub: [@Ahmed-Amr-Farouk](https://github.com/Ahmed-Amr-Farouk)

## 📄 License

*Add a license (e.g. MIT) if you'd like others to know how they can use this project.*
