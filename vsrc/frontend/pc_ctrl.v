module pc_ctrl (
    input wire clock,   // Clock signal
    input wire reset_n, // Active-low reset signal

    //boot and interrupt addr
    input wire [`PC_RANGE] boot_addr,        // 48-bit boot address
    //input wire        interrupt_valid,  // Interrupt valid signal
    //input wire [`PC_RANGE] interrupt_addr,   // 48-bit interrupt address

    //port with pju
    input wire        redirect_valid,
//    input wire [`PC_RANGE] redirect_target,
    input wire [63:0] redirect_target,

    //ports with ibuffer
    input  wire        fetch_inst,      // ibuffer level signal
//    output reg  [`PC_RANGE] pc,              // 48-bit Program Counter  
    output reg  [63:0] pc,              // 63-bit Program Counter   

    //ports with channel_arb
    output reg         pc_index_valid,    // Valid signal for PC index
//    output wire [18:0] pc_index,          // Selected bits [21:3] of the PC for DDR index
    output wire [63:0] pc_index,          // Selected bits [21:3] of the PC for DDR index
    input  wire        pc_index_ready,    // Signal indicating DDR operation is complete
    input  wire        pc_operation_done,
    input  wire           admin2pcctrl_predicttaken,
    input  wire  [31:0]   admin2pcctrl_predicttarget,
    output wire   pc_req_handshake

);

    always @(posedge clock or negedge reset_n) begin
        if(~reset_n)begin
            pc <= boot_addr;
        end else if(redirect_valid)begin
            pc <= redirect_target; 
        end else if (pc_operation_done && admin2pcctrl_predicttaken)begin
            pc <= {32'b0,admin2pcctrl_predicttarget};
        end else if(pc_operation_done && ~admin2pcctrl_predicttaken) begin
            pc <= ({pc[63:4], 4'b0}) + 16;
        end
    end


    //wire pc_req_handshake;
    assign pc_req_handshake = pc_index_ready && pc_index_valid;
    reg pc_req_outstanding;
    always @(posedge clock or negedge reset_n) begin
        if(~reset_n)begin
            pc_req_outstanding <= 1'b0;
        end else if (redirect_valid)begin
            pc_req_outstanding <= 1'b0;
        end else if (pc_req_handshake)begin
            pc_req_outstanding <= 1'b1;             
        end else if(pc_operation_done)begin
            pc_req_outstanding <= 1'b0; 
        end
    end


    always @(posedge clock or negedge reset_n) begin
        if(~reset_n)begin
            pc_index_valid <= 1'b0;
        end else if (redirect_valid)begin //redirect fetch
            pc_index_valid <= 1'b1;             
        end else if(fetch_inst & ~pc_req_outstanding & ~pc_req_handshake )begin //normal fetch. 
            pc_index_valid <= 1'b1; 
        //fastest icache fetch flow: take 4 cycle
        //(1) 1st cycle, pc change 
        //(2) 2nd cycle, pc_index_valid set to 1 , if pc_index_ready is already 1, handshake at this cycle 
        //(3) 3rd cycle, icache state: IDLE->LOOKUP 
        //(4) 4th cycle, icache state: LOOKUP->READ_CACHE , pc_operation_done set to 1
        //(5) 5th cycle, icache state: READ_CACHE->IDLE, pc change again
        end else begin
            pc_index_valid <= 1'b0;
        end
    end

    assign pc_index = pc;


endmodule
