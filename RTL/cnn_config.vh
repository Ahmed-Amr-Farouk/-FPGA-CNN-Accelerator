`define IMAGE_SIZE 32
`define KERNEL_SIZE 3
`define DATA_WIDTH 8
`define OUTPUT_WIDTH (2*`DATA_WIDTH+ $clog2(`KERNEL_SIZE*`KERNEL_SIZE))
`define AW ($clog2(`IMAGE_SIZE))

