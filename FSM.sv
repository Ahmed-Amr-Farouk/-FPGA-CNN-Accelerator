module control_fsm (
    input  wire clk,
    input  wire rst_n,
    input  wire start        ,
    input  wire window_valid ,
    input  wire last_window  ,
    input  wire kernel_valid ,
    input  wire conv_done    ,
    input  wire ReLU_done    ,
    

    output reg  pixel_valid  ,
    output reg  weight_valid ,
    output reg  start_conv   ,
    output reg  load_weight  ,
    output reg  last         ,
    output reg  st_ReLU
   
);
    reg kernel_loaded ;
    typedef enum bit [1:0] { IDLE   = 2'b00 ,
                             LOAD   = 2'b01 ,
                             CONV   = 2'b11 
    } state_e ;
    state_e current_state , next_state ;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
        begin
            current_state <= IDLE ;
            kernel_loaded <= 1'b0 ;
        end
        else
        begin
            current_state <= next_state  ;

            if (current_state == IDLE)
                kernel_loaded <= 1'b0;
            else if (kernel_valid)
                kernel_loaded <= 1'b1;
        end
    end
 

    always @(*) begin
        next_state = current_state ;
        case (current_state)
            IDLE     : if (start)                          next_state = LOAD ;
            LOAD     : if (window_valid)                   next_state = CONV ; // to load kernel and 1st window 
            CONV     : if (ReLU_done)                      next_state = IDLE ; 
            default  : next_state = IDLE ;
        endcase
    end
    
    always @(*) begin
        case (current_state)
            IDLE   : begin
                pixel_valid  = 0 ;   // to start dirct
                weight_valid = 0 ;
                start_conv   = 0 ;
                load_weight  = 0 ;
                st_ReLU      = 0 ;
                last         = 0 ;
            end
            LOAD :begin
                pixel_valid  = 1 ;
                st_ReLU      = 0 ;
                last         = 0 ;
                start_conv   = window_valid; //to get the 1st widow at the same T

                //to stop after kernel
                if (kernel_loaded || kernel_valid)  weight_valid = 0 ;
                else                                weight_valid = 1 ;
               // kernal vaild for 1 cyc then mac load it and white the widow 
                if (kernel_valid)   load_weight = 1 ;
                else                load_weight = 0 ;
            end
            CONV :begin
                pixel_valid  = 1 ;
                weight_valid = 0 ;
                start_conv   = window_valid ; // to stop conv at trans from row to row 
                                              // NOTE: line_buff's row-transition
                                              // gap must now be >= 3 cycles (was
                                              // tuned for the old 2-cycle PE) --
                                              // see line_buff.sv, still pending.
                load_weight  = 0 ;
                st_ReLU      = conv_done ;
                if (last_window) last         = 1 ;
                else             last         = 0 ;
            end 
            default : begin
                pixel_valid  = 0 ;
                weight_valid = 0 ;
                start_conv   = 0 ;
                load_weight  = 0 ;
                st_ReLU      = 0 ;
                last         = 0 ;

            end
            
        endcase
    end
 
endmodule