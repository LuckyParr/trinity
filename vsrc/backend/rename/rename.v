module rename #()
(

);

/* --------------------------- hazardchecker logic -------------------------- */

hazardchecker u_hazardchecker(
    .instr0_lrs1       (instr0_lrs1       ),
    .instr0_lrs1_valid (instr0_lrs1_valid ),
    .instr0_lrs2       (instr0_lrs2       ),
    .instr0_lrs2_valid (instr0_lrs2_valid ),
    .instr0_lrd        (instr0_lrd        ),
    .instr0_lrd_valid  (instr0_lrd_valid  ),
    .instr1_lrs1       (instr1_lrs1       ),
    .instr1_lrs1_valid (instr1_lrs1_valid ),
    .instr1_lrs2       (instr1_lrs2       ),
    .instr1_lrs2_valid (instr1_lrs2_valid ),
    .instr1_lrd        (instr1_lrd        ),
    .instr1_lrd_valid  (instr1_lrd_valid  ),
    .raw_hazard_rs1    (raw_hazard_rs1    ),
    .raw_hazard_rs2    (raw_hazard_rs2    ),
    .waw_hazard        (waw_hazard        )
);


/* -------------------- read 6 physical reg number from spec_rat when valid-------------------- */

read result:
specrat2rn_instr0prs1;
specrat2rn_instr0prs2;
specrat2rn_instr0prd;

specrat2rn_instr1prs1;
specrat2rn_instr1prs2;
specrat2rn_instr1prd;



/* ------- read 2 rd available free physical reg number from freelist ------- */
//fl2rn stands for "freelist to rename"
read result:
fl2rn_instr0prd;
fl2rn_instr1prd;


/* ------------------------------ rename logic ------------------------------ */

// raw_hazard_rs1 situation: 
// instr0 : add r1,r2,r3   ->  add p51,p42,p43
// instr1 : add r4,r1,r3   ->  add p52,p51,p43
//
// waw_hazard situation: 
// instr0 : add r1,r2,r3   ->  add p51,p42,p43
// instr1 : add r1,r2,r3   ->  add p52,p42,p43
//

always @(*) begin
    if(raw_hazard_rs1)begin
        rn2disp_instr1rs1 = fl2rn_instr0prd;
    end 
    if(raw_hazard_rs2)begin
        rn2disp_instr1rs2 = fl2rn_instr0prd;        
    end
    if(waw_hazard)begin
        rn2specrat_instr0rd_wren = 0;//only need to write back instr1 rd preg to specrat
    end

end


/* ----------- output renamed physical number of 6 reg to dispatch ---------- */



/* ------------ write renamed physical number of 2 rd to spec_rat ----------- */


endmodule