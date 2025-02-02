module busy_table (
    input wire clock,                         // Clock signal
    input wire reset_n,                     // Active-low reset signal

    // Read Port 0
    input wire [5:0] disp2bt_instr0rs1_rdaddr, // Address for disp2bt_instr0rs1_rddata
    output wire bt2disp_instr0rs1_busy,      // Data output for disp2bt_instr0rs1_rddata

    // Read Port 1
    input wire [5:0] disp2bt_instr0rs2_rdaddr, // Address for disp2bt_instr0rs2_rddata
    output wire bt2disp_instr0rs2_busy,      // Data output for disp2bt_instr0rs2_rddata

    // Read Port 2
    input wire [5:0] disp2bt_instr1rs1_rdaddr, // Address for disp2bt_instr1rs1_rddata
    output wire bt2disp_instr1rs1_busy,      // Data output for disp2bt_instr1rs1_rddata

    // Read Port 3
    input wire [5:0] disp2bt_instr1rs2_rdaddr, // Address for disp2bt_instr1rs2_rddata
    output wire bt2disp_instr1rs2_busy,      // Data output for disp2bt_instr1rs2_rddata

    // Write Port 0 - Allocate Instruction 0
    input wire disp2bt_alloc_instr0rd_en,             // Enable for disp2bt_alloc_instr0rd_addr
    input wire [5:0] disp2bt_alloc_instr0rd_addr,     // Address for disp2bt_alloc_instr0rd_addr

    // Write Port 1 - Allocate Instruction 1
    input wire disp2bt_alloc_instr1rd_en,             // Enable for disp2bt_alloc_instr1rd_addr
    input wire [5:0] disp2bt_alloc_instr1rd_addr,     // Address for disp2bt_alloc_instr1rd_addr

    // Write Port 2 - Free Instruction 0
    input wire intwb2bt_free_instr0rd_en,              // Enable for intwb2bt_free_instr0rd_addr
    input wire [5:0] intwb2bt_free_instr0rd_addr,      // Address for intwb2bt_free_instr0rd_addr

    // Write Port 3 - Free Instruction 1
    input wire memwb2bt_free_instr0rd_en,              // Enable for memwb2bt_free_instr0rd_addr
    input wire [5:0] memwb2bt_free_instr0rd_addr,       // Address for memwb2bt_free_instr0rd_addr

/* ------------------------------- walk logic ------------------------------- */
    input flush_valid,
    input [`INSTR_ID_WIDTH-1:0] flush_robid,//TODO, use robid to kill young instr
    input wire [1:0] rob_state,
    input wire walking_valid0,
    input wire walking_valid1,
    input wire [5:0] walking_prd0,
    input wire [5:0] walking_prd1,
    input wire walking_complete0,
    input wire walking_complete1

);
    wire is_idle;
    wire is_rollback;
    wire is_walk;

    assign is_idle = (rob_state == `ROB_STATE_IDLE);
    assign is_rollback = (rob_state == `ROB_STATE_ROLLIBACK);
    assign is_walk = (rob_state == `ROB_STATE_WALK);

    // Internal 64-bit busy vector register
    reg [63:0] busy_vector;

    // Synchronous write operations with active-low reset
    always @(posedge clock) begin
        if (!reset_n | is_rollback) begin
            busy_vector <= 64'b0;
        end else begin
            // Allocation Ports - Set Bit to 1
            if (disp2bt_alloc_instr0rd_en)begin
                busy_vector[disp2bt_alloc_instr0rd_addr] <= 1'b1;                
            end

            if (disp2bt_alloc_instr1rd_en)begin
                busy_vector[disp2bt_alloc_instr1rd_addr] <= 1'b1;                
            end

            // Free Ports - Set Bit to 0
            if (intwb2bt_free_instr0rd_en)begin
                busy_vector[intwb2bt_free_instr0rd_addr] <= 1'b0;                
            end

            if (memwb2bt_free_instr0rd_en)begin
                busy_vector[memwb2bt_free_instr0rd_addr] <= 1'b0;                
            end

            if (walking_valid0 && ~walking_complete0)begin
                busy_vector[walking_prd0] <= 1'b1;
            end

            if (walking_valid1 && ~walking_complete1)begin
                busy_vector[walking_prd1] <= 1'b1;
            end
            
        end
    end

    // Bypass Logic for Read Port 0
    wire bypass_instr0rs1;
    assign bypass_instr0rs1 = 
           (disp2bt_alloc_instr0rd_en && (disp2bt_alloc_instr0rd_addr == disp2bt_instr0rs1_rdaddr)) ? 1'b1 :
           (disp2bt_alloc_instr1rd_en && (disp2bt_alloc_instr1rd_addr == disp2bt_instr0rs1_rdaddr)) ? 1'b1 :
           (intwb2bt_free_instr0rd_en && (intwb2bt_free_instr0rd_addr == disp2bt_instr0rs1_rdaddr)) ? 1'b0 :
           (memwb2bt_free_instr0rd_en && (memwb2bt_free_instr0rd_addr == disp2bt_instr0rs1_rdaddr)) ? 1'b0 :
           busy_vector[disp2bt_instr0rs1_rdaddr];

    // Bypass Logic for Read Port 1
    wire bypass_instr0rs2;
    assign bypass_instr0rs2 = 
           (disp2bt_alloc_instr0rd_en && (disp2bt_alloc_instr0rd_addr == disp2bt_instr0rs2_rdaddr)) ? 1'b1 :
           (disp2bt_alloc_instr1rd_en && (disp2bt_alloc_instr1rd_addr == disp2bt_instr0rs2_rdaddr)) ? 1'b1 :
           (intwb2bt_free_instr0rd_en && (intwb2bt_free_instr0rd_addr == disp2bt_instr0rs2_rdaddr)) ? 1'b0 :
           (memwb2bt_free_instr0rd_en && (memwb2bt_free_instr0rd_addr == disp2bt_instr0rs2_rdaddr)) ? 1'b0 :
           busy_vector[disp2bt_instr0rs2_rdaddr];

    // Bypass Logic for Read Port 2
    wire bypass_instr1rs1;
    assign bypass_instr1rs1 = 
           (disp2bt_alloc_instr0rd_en && (disp2bt_alloc_instr0rd_addr == disp2bt_instr1rs1_rdaddr)) ? 1'b1 :
           (disp2bt_alloc_instr1rd_en && (disp2bt_alloc_instr1rd_addr == disp2bt_instr1rs1_rdaddr)) ? 1'b1 :
           (intwb2bt_free_instr0rd_en && (intwb2bt_free_instr0rd_addr == disp2bt_instr1rs1_rdaddr)) ? 1'b0 :
           (memwb2bt_free_instr0rd_en && (memwb2bt_free_instr0rd_addr == disp2bt_instr1rs1_rdaddr)) ? 1'b0 :
           busy_vector[disp2bt_instr1rs1_rdaddr];

    // Bypass Logic for Read Port 3
    wire bypass_instr1rs2;
    assign bypass_instr1rs2 = 
           (disp2bt_alloc_instr0rd_en && (disp2bt_alloc_instr0rd_addr == disp2bt_instr1rs2_rdaddr)) ? 1'b1 :
           (disp2bt_alloc_instr1rd_en && (disp2bt_alloc_instr1rd_addr == disp2bt_instr1rs2_rdaddr)) ? 1'b1 :
           (intwb2bt_free_instr0rd_en && (intwb2bt_free_instr0rd_addr == disp2bt_instr1rs2_rdaddr)) ? 1'b0 :
           (memwb2bt_free_instr0rd_en && (memwb2bt_free_instr0rd_addr == disp2bt_instr1rs2_rdaddr)) ? 1'b0 :
           busy_vector[disp2bt_instr1rs2_rdaddr];

    // Assigning read data with bypass logic
    assign bt2disp_instr0rs1_busy = bypass_instr0rs1;
    assign bt2disp_instr0rs2_busy = bypass_instr0rs2;
    assign bt2disp_instr1rs1_busy = bypass_instr1rs1;
    assign bt2disp_instr1rs2_busy = bypass_instr1rs2;

endmodule
