module instr_admin (
    input  wire        pc_operation_done,
    input  wire [`ICACHE_FETCHWIDTH128_RANGE] fetch_instr,         // 128-bit cache line input (4 instructions)
    input  wire [63:0] pc,                  // 63-bit Program Counter  
    output reg  [`ICACHE_FETCHWIDTH128_RANGE] admin2ib_instr,       // Output cache line after processing
    output reg  [ 3:0] admin2ib_instr_valid, // indicate instr valid
    // Outputs from BHT
    input wire [7:0] bht_read_data,              // 8-bit data from BHT (4 counters)
    input wire bht_valid,                       // BHT valid bit
    // Outputs from BTB
    input wire [127:0] btb_targets,             // Four 32-bit branch target addresses
    input wire btb_valid,                       // BTB valid bit
    output wire [3:0]       admin2ib_predicttaken,
    output wire [4*32-1:0]  admin2ib_predicttarget,
    output wire             admin2pcctrl_predicttaken,
    output wire [31:0]      admin2pcctrl_predicttarget
);
reg  [`ICACHE_FETCHWIDTH128_RANGE] aligned_instr; // 4 instr after aligner logic
reg  [ 3:0] aligned_instr_valid; // indicate instr valid

/* ------------ aligner logic : to delete some front instr base on pc ------------ */
    always @* begin
        aligned_instr       = 'b0;
        aligned_instr_valid = 'b0;
        if (pc_operation_done) begin
            if (pc[3:2] == 2'b01) begin
                // Shift cache line to discard the lowest 32 bits (shift by 32 bits)
                aligned_instr       = {32'b0, fetch_instr[127:32]};
                aligned_instr_valid = {4'b0111};
            end else if (pc[3:2] == 2'b10) begin
                aligned_instr       = {64'b0, fetch_instr[127:64]};
                aligned_instr_valid = {4'b0011};
            end else if (pc[3:2] == 2'b11) begin
                aligned_instr       = {96'b0, fetch_instr[127:96]};
                aligned_instr_valid = {4'b0001};
            end else begin // (pc[3:2] == 2'b00), get all instr
                aligned_instr       = fetch_instr;
                aligned_instr_valid = {4'b1111};
            end
        end
    end

/* ------- checker logic : determine if 4 instr is true branch/jal/jalr , then get instrs that truly need jump ------- */
// Define local parameters for instruction types
localparam OTHER    = 2'b00;
localparam JAL      = 2'b01;
localparam JALR     = 2'b10;
localparam BRANCH   = 2'b11;

// Function to decode a single 32-bit RISC-V instruction
function [1:0] decode_instr;
    input [31:0] instr;
    reg [6:0] opcode;
    begin
        opcode = instr[6:0];  // Extract opcode [6:0]

        case (opcode)
            7'b1101111: decode_instr = JAL;    // JAL
            7'b1100111: decode_instr = JALR;   // JALR
            7'b1100011: decode_instr = BRANCH; // Branch 
            default: decode_instr = OTHER; // Other instructions
        endcase
    end
endfunction

    reg  [1:0]   instr3_type;        // Type of Instruction 3
    reg  [1:0]   instr2_type;        // Type of Instruction 2
    reg  [1:0]   instr1_type;        // Type of Instruction 1
    reg  [1:0]   instr0_type;        // Type of Instruction 0

    always @(*) begin
        // Extract each 32-bit instruction
        wire [31:0] instr3 = aligned_instr[127:96];//4th instr
        wire [31:0] instr2 = aligned_instr[95:64];//3rd instr
        wire [31:0] instr1 = aligned_instr[63:32];//2nd instr
        wire [31:0] instr0 = aligned_instr[31:0];//1st instr
        
        // Decode instruction types
        instr3_type = decode_instr(instr3);
        instr2_type = decode_instr(instr2);
        instr1_type = decode_instr(instr1);
        instr0_type = decode_instr(instr0);
    end

    wire [3:0] jal_jalr_branch_of_4instr;
    assign jal_jalr_branch_of_4instr = {
        (instr3_type != 2'b0),
        (instr2_type != 2'b0),
        (instr1_type != 2'b0),
        (instr0_type != 2'b0),
    };

    assign admin2ib_predicttaken = {bht_read_data[7],bht_read_data[5],bht_read_data[3],bht_read_data[1]};

    wire [3:0] bpu_say_jump_makesense_of_4instr;//bit = 1 indicate this instruction is truly jump or branch , while bpu predict jump 
    assign bpu_say_jump_makesense_of_4instr = jal_jalr_branch_of_4instr & admin2ib_predicttaken;

    assign admin2ib_predicttarget = {
        {32{admin2ib_predicttaken[3]} & btb_targets[127:96]},
        {32{admin2ib_predicttaken[2]} & btb_targets[95:64]},
        {32{admin2ib_predicttaken[1]} & btb_targets[63:32]},
        {32{admin2ib_predicttaken[0]} & btb_targets[31:0]}
    };

    /* ---------------- convert bpu_say_jump_makesense_of_4instr ---------------- */
    wire [3:0] set_valid_before_first_branch;
    assign set_valid_before_first_branch = (bpu_say_jump_makesense_of_4instr[0]) ? 4'b0001 :          
                                           (bpu_say_jump_makesense_of_4instr[1]) ? 4'b0011 :          
                                           (bpu_say_jump_makesense_of_4instr[2]) ? 4'b0111 :          
                                           (bpu_say_jump_makesense_of_4instr[3]) ? 4'b1111 :          
                                            4'b0000 ;   

    /* --------------------------- last process logic:(admin2ib_instr after trimfront(aligned) and trimtail(branch)) --------------------------- */
    wire [3:0] aligned_makesensejump_of_4instr;
    assign aligned_makesensejump_of_4instr = (aligned_instr_valid & bpu_say_jump_makesense_of_4instr);

    wire exist_aligned_makesensejump;
    assign exist_aligned_makesensejump = | aligned_makesensejump_of_4instr;

    wire [3:0] trimtail_instr_valid;
    assign trimtail_instr_valid = {
        (aligned_instr_valid[3] & set_valid_before_first_branch[3]),
        (aligned_instr_valid[2] & set_valid_before_first_branch[2]),
        (aligned_instr_valid[1] & set_valid_before_first_branch[1]),
        (aligned_instr_valid[0] & set_valid_before_first_branch[0])
    };

    wire [127:0] trimtail_instr;
    assign trimtail_instr[127:96] = {32{trimtail_instr_valid[3]}} & aligned_instr[127:96];
    assign trimtail_instr[95:64] = {32{trimtail_instr_valid[2]}} & aligned_instr[95:64];
    assign trimtail_instr[63:32] = {32{trimtail_instr_valid[1]}} & aligned_instr[63:32];
    assign trimtail_instr[31:0] = {32{trimtail_instr_valid[0]}} & aligned_instr[31:0];
    

    always @(*) begin
        admin2ib_instr = 'b0;
        admin2ib_instr_valid = 'b0;
        if(~exist_aligned_makesensejump)begin
            admin2ib_instr = aligned_instr;
            admin2ib_instr_valid = aligned_instr_valid;
        end else begin
            admin2ib_instr = trimtail_instr;
            admin2ib_instr_valid = trimtail_instr_valid;
        end
    end

    /* ------------------------------ signal to pc ------------------------------ */
    wire [3:0] first_aligned_makesensejump_oh;
    findfirstone u_findfirstone_admin(
        .in_vector (aligned_makesensejump_of_4instr ),
        .onehot    (first_aligned_makesensejump_oh    ),
        .valid     (     )
    );

    assign admin2pcctrl_predicttaken = exist_aligned_makesensejump;
    assign admin2pcctrl_predicttarget = {
        (32{first_aligned_makesensejump_oh[3]} & btb_targets[127:96]) |
        (32{first_aligned_makesensejump_oh[2]} & btb_targets[95:64]) |
        (32{first_aligned_makesensejump_oh[1]} & btb_targets[63:32]) |
        (32{first_aligned_makesensejump_oh[0]} & btb_targets[31:0]) 
    };
    

endmodule
