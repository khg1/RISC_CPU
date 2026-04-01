module tb_top;

localparam int XPRLEN = 32;
localparam CLK_T = 2;         //2ns (500MHz)

logic 			clk, resetn;
logic 			program_executed;
logic [XPRLEN-1:0]	count_instruction, count_clk_cycle;

int incorrect_register, incorrect_data;
real final_cpi, final_ipc;
string mem_file, final_register_file;
logic [XPRLEN-1:0] golden_rf [0:XPRLEN-1];


axi_if axi_bus();

top cpu_top(
	.clk(clk),
	.resetn(resetn),
	.axi_port(axi_bus.AXI_MASTER),
	.program_executed(program_executed),
	.count_instruction(count_instruction),
	.count_clk_cycle(count_clk_cycle)
);

axi_mem my_ram(
	.clk(clk),
	.resetn(resetn),
	.axi_port(axi_bus.AXI_SLAVE)
);

initial begin
        clk = 0;
        forever #(CLK_T/2)      clk = ~clk;
end

initial begin
        resetn = 0;
        repeat(5)       @(negedge clk);
        resetn = 1;
        $display("STARTING CPU EXECUTION !!!!!!!!");
end

initial begin
        if($value$plusargs("MEM=%s", mem_file)) begin
                $readmemh(mem_file, my_ram.mem);
        end
        else begin
                $error("PROVIDE MEM FILE TO LOAD +MEM=");
                $finish;
        end
        if($value$plusargs("GOLDREG=%s", final_register_file))        $readmemh(final_register_file, golden_rf);
        else begin
                $error("PROVIDE EXPECTED REGISTER FILE TO COMPARE +GOLDREG=");
                $finish;
        end
end

initial begin
        fork
		begin
		        do  begin
		                @(posedge clk);
		                $display("icache_stall=%0d and dcache_stall=%0d", cpu_top.inst_core.i_cpu_stall, cpu_top.inst_core.d_cpu_stall);
		                print_pipeline_state();
		        end while(!program_executed);
		        $display("EXECUTION DONE!!!!!");
		end
		begin
		        repeat(50000)     @(posedge clk);
		        $error("TIMEOUT ??????????");
		        $finish;
		end
        join_any
	disable fork;
        for (int i = 0; i < XPRLEN; i++) begin
            if (cpu_top.inst_core.inst_register_file.x[i] != golden_rf[i]) begin
                $display("[FAIL] Reg x%0d | Expected: %h | Got: %h", i, golden_rf[i], cpu_top.inst_core.inst_register_file.x[i]);
                incorrect_register += 1;
            end
        end
        
	if(incorrect_register == 0)  $display("@@@PASS");
        else                         $display("@@@FAIL wrong register=%d", incorrect_register);

	if(count_instruction > 0 && count_clk_cycle > 0) begin
        	final_cpi = $itor(count_clk_cycle)/$itor(count_instruction);
        	final_ipc = $itor(count_instruction)/$itor(count_clk_cycle);
	end
	else begin
		final_cpi = 0.0;
		final_ipc = 0.0;
	end
        $display("Total Clock Cycles : %0d", count_clk_cycle);
        $display("Total Instructions : %0d", count_instruction);
        $display("----------------------------------------");
        $display("Performance (CPI)  : %0f Cycles/Inst", final_cpi);
        $display("Performance (IPC)  : %0f Inst/Cycles", final_ipc);
        $finish;

        end

task print_pipeline_state();
	 $strobe("==================================================================");
   	 $strobe(" TIME: %0t | PIPELINE STAGE DASHBOARD", $time);
	 $strobe("------------------------------------------------------------------");

   	 $strobe(" [IF/ID]  PC: %h | Instr: %h | (Stall/Write_En: %b)",
   	         cpu_top.inst_core.Q_ifid_pc, cpu_top.inst_core.Q_ifid_instr, cpu_top.inst_core.sig_write_enable);

   	 $strobe(" [ID/EX]  PC: %h | rs1: %0d | rs2: %0d | rd: %0d | Imm: %h",
   	         cpu_top.inst_core.Q_idex_pc, cpu_top.inst_core.Q_idex_rs1, cpu_top.inst_core.Q_idex_rs2, cpu_top.inst_core.Q_idex_rd, cpu_top.inst_core.Q_idex_immediate);
   	 $strobe("          Data1: %h | Data2: %h | Funct: %b",
   	         cpu_top.inst_core.Q_idex_data1, cpu_top.inst_core.Q_idex_data2, cpu_top.inst_core.Q_idex_funct);
   	 $strobe("          Ctrl -> RegWr:%b | ALUOp:%b | ALUSrc:%b | MemRd:%b | MemWr:%b | Mem2Reg:%b",
   	         cpu_top.inst_core.Q_idex_reg_write, cpu_top.inst_core.Q_idex_aluop, cpu_top.inst_core.Q_idex_alusrc, cpu_top.inst_core.Q_idex_mem_read, cpu_top.inst_core.Q_idex_mem_write, cpu_top.inst_core.Q_idex_mem_to_reg);

   	 $strobe(" [EX/MEM] ALU_Res: %h | Store_Data (Data2): %h | rd: %0d",
   	         cpu_top.inst_core.Q_exmem_alu_result, cpu_top.inst_core.Q_exmem_data2, cpu_top.inst_core.Q_exmem_rd);
   	 $strobe("          Ctrl -> RegWr:%b | MemRd:%b | MemWr:%b | Mem2Reg:%b",
   	         cpu_top.inst_core.Q_exmem_reg_write, cpu_top.inst_core.Q_exmem_mem_read, cpu_top.inst_core.Q_exmem_mem_write, cpu_top.inst_core.Q_exmem_mem_to_reg);

   	 $strobe(" [MEM/WB] Mem_Data: %h | ALU_Res: %h | rd: %0d",
   	         cpu_top.inst_core.Q_memwb_mem_data, cpu_top.inst_core.Q_memwb_alu_result, cpu_top.inst_core.Q_memwb_rd);
   	 $strobe("          Ctrl -> Mem2Reg:%b",
   	         cpu_top.inst_core.Q_memwb_mem_to_reg);
	$strobe("====================================================================");

endtask


endmodule
