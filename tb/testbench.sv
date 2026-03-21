module testbench;

localparam clock_period = 5;
localparam XPRLEN = 32;
localparam DEPTH = 500;

logic clk, resetn, done;

logic [XPRLEN-1:0] golden_rf [0:XPRLEN-1];
logic [XPRLEN-1:0] golden_dmem [0:DEPTH-1];

core DUT (
	.clk(clk),
	.resetn(resetn),
	.done(done)
);

string instr_file, data_file, register_file, gold_file;
int incorrect_register, incorrect_data;

initial begin
	clk = 0;
	forever #clock_period clk = ~clk;
end

initial begin
	if($value$plusargs("PROG=%s", instr_file))	$readmemh(instr_file, DUT.inst_instr_mem.imem);
	else begin
		$error("PROVIDE PROGRAM FILE TO RUN :)");
		$finish;
	end
	if($value$plusargs("DATA=%s", data_file))	$readmemh(data_file, DUT.inst_data_memory.dmem);
	else begin
		$error("PROVIDE DATA FILE TO LOAD +DATA=");
		$finish;
	end
	if($value$plusargs("GOLDREG=%s", register_file))	$readmemh(register_file, golden_rf);
	else begin
		$error("PROVIDE EXPECTED REGISTER FILE TO COMPARE +GOLDREG=");
		$finish;
	end
	if($value$plusargs("GOLDMEM=%s", gold_file))	$readmemh(gold_file, golden_dmem);
	else begin
		$error("PROVIDE EXPECTED MEMEORY FILE TO COMPARE +GOLDMEM=");
		$finish;
	end
end

initial begin
	resetn = 0;
	repeat(5)	@(negedge clk);
	$display("STARTING CPU EXECUTION!!!!!!!!!");
	resetn = 1;
	fork
		begin
			do  begin
				@(posedge clk);
				print_pipeline_state();
			end while(!done);
			$display("EXECUTION DONE!!!!!");
		end
		begin
			repeat(500)	@(posedge clk);
			$error("TIMEOUT ??????????");
			$finish;
		end
	join_any
	for (int i = 0; i < XPRLEN; i++) begin
            if (DUT.inst_register_file.x[i] != golden_rf[i]) begin
                $display("[FAIL] Reg x%0d | Expected: %h | Got: %h", i, golden_rf[i], DUT.inst_register_file.x[i]);
		incorrect_register += 1;
            end
        end
	for (int i = 0; i < DEPTH; i++) begin
            if (DUT.inst_data_memory.dmem[i] != golden_dmem[i]) begin
                $display("[FAIL] Mem [%0d] | Expected: %h | Got: %h", i, golden_dmem[i], DUT.inst_data_memory.dmem[i]);
		incorrect_data += 1;
            end
        end
	if((incorrect_register == 0) && (incorrect_data == 0))	$display("@@@PASS");
	else							$display("@@@FAIL wrong register=%d, and wrong data=%d",
									  incorrect_register, incorrect_data); 
	$finish;
end
task print_pipeline_state();
    $strobe("================================================================================");
    $strobe(" TIME: %0t | PIPELINE STAGE DASHBOARD", $time);
    $strobe("--------------------------------------------------------------------------------");
    
    // --- IF/ID STAGE ---
    $strobe(" [IF/ID]  PC: %h | Instr: %h | (Stall/Write_En: %b)", 
            DUT.Q_ifid_pc, DUT.Q_ifid_instr, DUT.sig_write_enable);
    
    // --- ID/EX STAGE ---
    $strobe(" [ID/EX]  PC: %h | rs1: %0d | rs2: %0d | rd: %0d | Imm: %h", 
            DUT.Q_idex_pc, DUT.Q_idex_rs1, DUT.Q_idex_rs2, DUT.Q_idex_rd, DUT.Q_idex_immediate);
    $strobe("          Data1: %h | Data2: %h | Funct: %b", 
            DUT.Q_idex_data1, DUT.Q_idex_data2, DUT.Q_idex_funct);
    $strobe("          Ctrl -> RegWr:%b | ALUOp:%b | ALUSrc:%b | MemRd:%b | MemWr:%b | Mem2Reg:%b", 
            DUT.Q_idex_reg_write, DUT.Q_idex_aluop, DUT.Q_idex_alusrc, DUT.Q_idex_mem_read, DUT.Q_idex_mem_write, DUT.Q_idex_mem_to_reg);

    // --- EX/MEM STAGE ---
    $strobe(" [EX/MEM] ALU_Res: %h | Store_Data (Data2): %h | rd: %0d", 
            DUT.Q_exmem_alu_result, DUT.Q_exmem_data2, DUT.Q_exmem_rd);
    $strobe("          Ctrl -> RegWr:%b | MemRd:%b | MemWr:%b | Mem2Reg:%b", 
            DUT.Q_exmem_reg_write, DUT.Q_exmem_mem_read, DUT.Q_exmem_mem_write, DUT.Q_exmem_mem_to_reg);

    // --- MEM/WB STAGE ---
    $strobe(" [MEM/WB] Mem_Data: %h | ALU_Res: %h | rd: %0d", 
            DUT.Q_memwb_mem_data, DUT.Q_memwb_alu_result, DUT.Q_memwb_rd);
    $strobe("          Ctrl -> Mem2Reg:%b", 
            DUT.Q_memwb_mem_to_reg);
            
    $strobe("================================================================================\n");
endtask
endmodule
