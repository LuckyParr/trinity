module pc_ctrl (
    input wire clock,   // Clock signal
    input wire reset_n, // Active-low reset signal

    //boot and interrupt addr
    input wire [47:0] boot_addr,        // 48-bit boot address
    input wire        interrupt_valid,  // Interrupt valid signal
    input wire [47:0] interrupt_addr,   // 48-bit interrupt address

    //port with pju
    input wire        redirect_valid,
    input wire [47:0] redirect_target,

    //ports with ibuffer
    input  wire        fetch_inst,      // Fetch instruction signal, pulse signal for PC increment
    output reg         can_fetch_inst,  // Indicates if a new instruction can be fetched
    output reg         clear_ibuffer,
    output reg  [47:0] pc,              // 48-bit Program Counter  
    output reg         cancel_pc_fetch,

    //ports with channel_arb
    output reg         pc_index_valid,    // Valid signal for PC index
    output wire [18:0] pc_index,          // Selected bits [21:3] of the PC for DDR index
    input  wire        pc_index_ready,    // Signal indicating DDR operation is complete
    input  wire        pc_operation_done

);
    // Output the selected bits [21:3] of the current PC as pc_index
    assign pc_index = pc[21:3];

    localparam BOOT_SETTING = 4'd0;
    localparam WAIT_FOR_FIRE = 4'd1;
    localparam ONGOING_NORMAL_FETCH = 4'd2;
    localparam NORMAL_FINISH = 4'd3;
    localparam WAIT_FOR_IBUFFER_INST_FETCH = 4'd4;
    localparam ONGOING_REDIRECT_FETCH = 4'd5;
    localparam REDIRECT_FINISH = 4'd6;
    localparam ONGONG_WASTED_NORMAL_FETCH = 4'd7;
    localparam WASTED_NORMAL_FETCH_FINISH = 4'd8;

    reg [3:0] current_state;
    reg [3:0] next_state;

    always @(posedge clock or negedge reset_n) begin
        if(~reset_n) begin
            current_state <= 4'd0;
        end else begin
            current_state <= next_state;
        end
    end

    always @(*) begin
        case(current_state)
            BOOT_SETTING: begin
                pc = boot_addr;
                pc_index_valid = 1'b0;
                can_fetch_inst = 1'b0;
                //cancel_pc_fetch = 1'b0;
                clear_ibuffer  = 1'b0;
                    next_state = WAIT_FOR_FIRE;                
            end
            WAIT_FOR_FIRE:begin
                //cancel_pc_fetch = 1'b0;
                pc_index_valid = 1'b1;
                if(~redirect_valid_or &&  pc_index_ready) begin
                    next_state = ONGOING_NORMAL_FETCH;
                end else if (redirect_valid_or &&  pc_index_ready)begin
                    next_state = ONGOING_REDIRECT_FETCH;                    
                end
            end
            ONGOING_NORMAL_FETCH:begin
                pc_index_valid = 1'b0;
                if(redirect_valid_or)begin
                    pc=redirect_valid_or;
                    next_state = ONGONG_WASTED_NORMAL_FETCH;
                end else if(pc_operation_done) begin
                    next_state = NORMAL_FINISH;
                end
            end
            ONGONG_WASTED_NORMAL_FETCH:begin
                pc_index_valid = 1'b0;
                //cancel_pc_fetch = 1'b1;
                if(pc_operation_done)begin
                    next_state = WASTED_NORMAL_FETCH_FINISH;
                end
            end
            WASTED_NORMAL_FETCH_FINISH:begin
                //cancel_pc_fetch = 1'b1;
                pc = redirect_target_or;
                next_state = WAIT_FOR_FIRE;
            end
            NORMAL_FINISH:begin
                if(redirect_valid_or)begin
                    pc = redirect_target_or;
                    //cancel_pc_fetch = 1'b1;
                        next_state= WAIT_FOR_FIRE;
                end else begin
                    pc = had_unalign_redirect ? pc + 60 :(pc + 64);
                        next_state=WAIT_FOR_IBUFFER_INST_FETCH;                    
                end
            end
            WAIT_FOR_IBUFFER_INST_FETCH:begin
                can_fetch_inst = 1'b1;
                if(fetch_inst)begin
                    next_state = WAIT_FOR_FIRE;
                end
                //if(redirect_valid)begin
                //    pc = redirect_target;
                //    next_state = WAIT_FOR_FIRE;
                //end else if(fetch_inst)begin
                //    //pc = had_unalign_redirect ? pc + 60 :(pc + 64);
                //    next_state = WAIT_FOR_FIRE;
                //end
            end
            ONGOING_REDIRECT_FETCH:begin
                pc_index_valid = 1'b0;
                //cancel_pc_fetch = 1'b0;
                //clr_redirect_valid_latch = 1'b0;
                if(pc_operation_done) begin
                    next_state = REDIRECT_FINISH;
                end
            end
            REDIRECT_FINISH:begin
                //clr_redirect_valid_latch = 1'b1;
                if(redirect_valid_or)begin
                    pc = redirect_target_or;
                    next_state = WAIT_FOR_FIRE;
                end else begin
                    next_state = WAIT_FOR_IBUFFER_INST_FETCH;                                    
                end
            end
            default:begin
                
            end
        endcase
    end

    reg redirect_valid_latch;
    reg [47:0] redirect_target_latch;
    //reg clr_redirect_valid_latch;
    always @(posedge clock or negedge reset_n) begin
        if(~reset_n)begin
            redirect_valid_latch <= 1'b0;
            redirect_target_latch <= 48'd0;
        end else if (redirect_valid) begin
            redirect_valid_latch <= 1'b1; 
            redirect_target_latch <= redirect_target;
        end else if (current_state == REDIRECT_FINISH) begin
            redirect_valid_latch <= 1'b0;
            redirect_target_latch <= 48'd0;
        end
    end

    wire redirect_valid_or;
    assign redirect_valid_or = redirect_valid || redirect_valid_latch;
    wire [47:0] redirect_target_or;
    assign redirect_target_or = ({48{redirect_valid}} & redirect_target) | ({48{redirect_valid_latch}} & redirect_target_latch);

    always @(*) begin
        //if(~reset_n) begin
        //    cancel_pc_fetch <= 'b0;
        //end
        if (redirect_valid_or && current_state == WAIT_FOR_FIRE  ) begin
            cancel_pc_fetch = 'b1;            
        end
        else if(current_state == REDIRECT_FINISH)begin
            cancel_pc_fetch = 'b0;            
        end
    end


    //redirect caused unalign 64B pc :record when redirect_valid & (redirect_target is unalign with 64B)
    //reg had_unalign_redirect;
    //always @(posedge clock or negedge reset_n ) begin
    //    if(~reset_n) begin
    //        had_unalign_redirect <= 'b0;
    //    end
    //    else begin
    //        if(redirect_valid & redirect_target[2] & ~pc_operation_done) begin
    //            had_unalign_redirect <= 1'b1;
//  //          end else if(pc_operation_done & ~ongoing_normal_pc_fetch) begin
//  //          end else if(pc_operation_done && (current_state != ONGOING_NORMAL_FETCH)) begin
//  //          end else if(pc_operation_done && (current_state == NORMAL_FINISH)) begin
    //        end else if((current_state == WAIT_FOR_IBUFFER_INST_FETCH)) begin
    //            had_unalign_redirect <= 1'b0;
    //        end
    //    end
    //end

    reg had_unalign_redirect;
    always @(posedge clock or negedge reset_n ) begin
        if(~reset_n) begin
            had_unalign_redirect <= 'b0;
        end
        else begin
            if(redirect_valid & redirect_target[2] & ~pc_operation_done) begin
                had_unalign_redirect <= 1'b1;
//            end else if(pc_operation_done & ~ongoing_normal_pc_fetch) begin
//            end else if(pc_operation_done && (current_state != ONGOING_NORMAL_FETCH)) begin
//            end else if(pc_operation_done && (current_state == NORMAL_FINISH)) begin
            end else if((current_state == REDIRECT_FINISH)) begin
                had_unalign_redirect <= 1'b0;
            end
        end
    end



endmodule
