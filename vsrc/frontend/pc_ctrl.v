module pc_ctrl (
    input wire clock,                          // Clock signal
    input wire reset_n,                        // Active-low reset signal

    //boot and interrupt addr
    input wire [47:0] boot_addr,             // 48-bit boot address
    input wire interrupt_valid,              // Interrupt valid signal
    input wire [47:0] interrupt_addr,        // 48-bit interrupt address

    //port with pju
    input wire redirect_valid,
    input wire [47:0] redirect_target,

    //ports with ibuffer
    input wire fetch_inst,                   // Fetch instruction signal, pulse signal for PC increment
    output reg can_fetch_inst,                // Indicates if a new instruction can be fetched
    output reg clear_ibuffer,
    output reg [47:0] pc,                     // 48-bit Program Counter

    //ports with channel_arb
    output reg pc_index_valid,               // Valid signal for PC index
    output wire [18:0] pc_index,              // Selected bits [21:3] of the PC for DDR index
    input wire pc_index_ready,                // Signal indicating DDR operation is complete
    input wire pc_operation_done

);

    
    // Output the selected bits [21:3] of the current PC as pc_index
    assign pc_index = pc[21:3];

    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            // Reset PC to boot address, and clear other signals on negative edge of reset_n
            pc <= boot_addr;
            pc_index_valid <= 1'b0;
            can_fetch_inst <= 1'b0;
            clear_ibuffer <=1'b0;
        end else if (interrupt_valid) begin
                //Update pc:  Handle interrupt logic
                pc <= interrupt_addr;       // Set PC to interrupt address if interrupt_valid is high
                pc_index_valid <= 1'b1;     // Set pc_index_valid to indicate new index is ready
                can_fetch_inst <= 1'b0;     // Clear can_fetch_inst during interrupt processing
                clear_ibuffer <= 1'b1;
        end else if (redirect_valid)begin
                //Update pc: Handle branch logic
                pc_index_valid <= 1'b1;
                pc <= redirect_target;
                can_fetch_inst <= 1'b0;
                clear_ibuffer <= 1'b1;
        end else if (fetch_inst) begin
                //Update pc: Normal PC increment on fetch_inst pulse
                pc <= pc + 64;              // Increment PC by 64
                pc_index_valid <= 1'b1;     // Set pc_index_valid to indicate new index is ready
                can_fetch_inst <= 1'b0;     // Clear can_fetch_inst when fetch_inst is asserted
        end else if (pc_index_valid && pc_index_ready) begin  //handshake, indicate fetch inst req to ddr sent
                // Set can_fetch_inst when pc_index_ready indicates operation completion
                pc_index_valid <= 1'b0;     // Clear pc_index_valid on completion
                can_fetch_inst <= 1'b0;     // Set can_fetch_inst to allow new fetch
        end else if (pc_operation_done) begin
                can_fetch_inst <= 1'b1;
        end
            end

    end

endmodule
