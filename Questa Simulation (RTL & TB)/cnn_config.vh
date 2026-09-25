`define IMAGE_SIZE 32
`define KERNEL_SIZE 3
`define DATA_WIDTH 8
`define OUTPUT_WIDTH (2*`DATA_WIDTH+ $clog2(`KERNEL_SIZE*`KERNEL_SIZE))
`define ADDRESS_WIDTH ($clog2(`IMAGE_SIZE))
`define N_PE (`KERNEL_SIZE * `KERNEL_SIZE)
`define LEVELS ($clog2(`N_PE))
`define MID_LEVEL ((`LEVELS + 1) / 2)         // split point of the tree
`define LEVELS2 (`LEVELS - `MID_LEVEL)       // remaining levels after the register
`define FLATTENED_SIZE (`KERNEL_SIZE * `KERNEL_SIZE * `DATA_WIDTH)