module ifu_top (
    input wire clock,
    input wire reset_n,

    // Inputs for PC control
    input wire [47:0] boot_addr,               // 48-bit boot address
    input wire interrupt_valid,                // Interrupt valid signal
    input wire [47:0] interrupt_addr,          // 48-bit interrupt address
    input wire redirect_valid,              // Branch address valid signal
    input wire [47:0] redirect_target,             // 48-bit branch address
    output wire pc_index_valid,
    input wire pc_index_ready,                 // Signal indicating DDR operation is complete
    input wire pc_operation_done,              // Signal indicating PC operation is done

    // Inputs for instruction buffer
    input wire [511:0] pc_read_inst,           // 512-bit input data for instructions
    input wire fifo_read_en,                   // External read enable signal for FIFO
    input wire clear_ibuffer_ext,              // External clear signal for ibuffer

    // Outputs from ibuffer
    output wire ibuffer_instr_valid,
    output wire [31:0] ibuffer_inst_out,
    output wire [47:0] ibuffer_pc_out,
    output wire fifo_empty,                    // Signal indicating if the FIFO is empty

    // Outputs from pc_ctrl
    output wire [18:0] pc_index,                // Selected bits [21:3] of the PC for DDR index
    
    input wire mem_stall
);

    // Internal signals connecting ibuffer and pc_ctrl
    wire fetch_inst;                           // Pulse from ibuffer to trigger fetch in pc_ctrl
    wire can_fetch_inst;                       // Signal from pc_ctrl to allow fetch in ibuffer
    wire clear_ibuffer;                        // Clear signal from pc_ctrl to ibuffer

    wire [47:0] pc;
    wire [511:0] selected_data;
    wire cut_first_32_bit;
    wire cancel_pc_fetch;

cacheline_selector u_cacheline_selector(
    .cache_line       (pc_read_inst       ),
    .pc_bit_2         (pc[2]         ),
    .cut_first_32_bit (cut_first_32_bit ),
    .selected_data    (selected_data    )
);


    // Instantiate the ibuffer module
    ibuffer ibuffer_inst (
        .clock(clock),
        .reset_n(reset_n),
        .pc(pc),
        .cut_first_32_bit(cut_first_32_bit),
        .pc_index_ready(pc_index_ready),
        .pc_operation_done(pc_operation_done),
        .pc_read_inst(selected_data),
        .fifo_read_en(fifo_read_en),
        .clear_ibuffer(clear_ibuffer | clear_ibuffer_ext | cancel_pc_fetch), // OR external and internal clear signals
        .can_fetch_inst(can_fetch_inst),
        .fetch_inst(fetch_inst),
        .ibuffer_instr_valid(ibuffer_instr_valid),
        .ibuffer_inst_out (ibuffer_inst_out),
        .ibuffer_pc_out (ibuffer_pc_out),
        .fifo_empty(fifo_empty),
        .mem_stall(mem_stall)
    );

    // Instantiate the pc_ctrl module
    pc_ctrl pc_ctrl_inst (
        .clock(clock),
        .reset_n(reset_n),
        .pc(pc),
        .boot_addr(boot_addr),
        .interrupt_valid(interrupt_valid),
        .interrupt_addr(interrupt_addr),
        .redirect_valid(redirect_valid),
        .redirect_target(redirect_target),
        .fetch_inst(fetch_inst),
        .can_fetch_inst(can_fetch_inst),
        .clear_ibuffer(clear_ibuffer),
        .pc_index_valid(pc_index_valid),
        .pc_index(pc_index),
        .pc_index_ready(pc_index_ready),
        .pc_operation_done(pc_operation_done),
        .cancel_pc_fetch (cancel_pc_fetch)
    );




endmodule
