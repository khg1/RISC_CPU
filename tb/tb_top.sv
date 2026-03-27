module tb_top;

	localparam CLK_T = 2;         //2ns (500MHz)
        localparam XPRLEN = 32;
	localparam DEPTH = 500;

	logic clk, resetn, done;
	string instr_file, data_file;
	string register_file, gold_file;
	logic [XPRLEN-1:0] golden_rf [0:XPRLEN-1];
	logic [XPRLEN-1:0] golden_dmem [0:DEPTH-1];
	int incorrect_register, incorrect_data;
	logic [XPRLEN-1:0]	num_inst, num_cycle;

	real final_cpi, final_ipc;


        initial begin
                clk = 0;
                forever #(CLK_T/2)      clk = ~clk;
        end

	initial begin
		resetn = 0;
		repeat(5)	@(negedge clk);
		resetn = 1;
		$display("STARTING CPU EXECUTION !!!!!!!!");
	end

	initial begin
		if($value$plusargs("PROG=%s", instr_file)) begin
        		for(int i=0;i<(DEPTH-1);i++)    imem.mem[i] = '0;
        		$readmemh(instr_file, imem.mem);	
		end
	        else begin
                	$error("PROVIDE PROGRAM FILE TO RUN :)");
                	$finish;
        	end
		if($value$plusargs("DATA=%s", data_file)) begin
                        for(int i=0;i<(DEPTH-1);i++)    dmem.mem[i] = '0;
                        $readmemh(data_file, dmem.mem);
		end
        	else begin
                	$error("PROVIDE DATA FILE TO LOAD +DATA=");
               		$finish;
        	end
		if($value$plusargs("GOLDREG=%s", register_file))	$readmemh(register_file, golden_rf);
        	else begin
                	$error("PROVIDE EXPECTED REGISTER FILE TO COMPARE +GOLDREG=");
                	$finish;
        	end
        	if($value$plusargs("GOLDMEM=%s", gold_file))    $readmemh(gold_file, golden_dmem);
        	else begin
                	$error("PROVIDE EXPECTED MEMEORY FILE TO COMPARE +GOLDMEM=");
                	$finish;
        	end
	end

        risc_if icache_if (.clk(clk), .resetn(resetn));
        risc_if dcache_if (.clk(clk), .resetn(resetn));

        core DUT (
                .clk(clk),
                .resetn(resetn),
                .icache_port(icache_if.cache_modport),
                .dcache_port(dcache_if.cache_modport),
                .done(done),
		.count_inst(num_inst),
		.count_cycle(num_cycle)
        );

        axi_mem imem(
                .axi_port(icache_if.sub_modport)
        );

        axi_mem dmem(
                .axi_port(dcache_if.sub_modport)
        );
	
	bind DUT axi_read_assertions b_axi_check (
    		  .CLK        (clk),
  		  .ARESETn    (resetn),
  		  .ARVALID    (icache_port.ARVALID),
  		  .ARREADY    (icache_port.ARREADY),
  		  .ARADDR     (icache_port.ARADDR),
  		  .ARLEN      (icache_port.ARLEN),
  		  .ARSIZE     (icache_port.ARSIZE),
  		  .ARBURST    (icache_port.ARBURST),
  		  .RVALID     (icache_port.RVALID),
  		  .RREADY     (icache_port.RREADY),
  		  .RDATA      (icache_port.RDATA),
  		  .RRESP      (icache_port.RRESP),
  		  .RLAST      (icache_port.RLAST)
	);
	

	initial begin
	fork
                begin
                        do  begin
                                @(posedge clk);
				$display("icache_stall=%0d and dcache_stall=%0d", DUT.i_cpu_stall, DUT.d_cpu_stall);
                                print_pipeline_state();
                        end while(!done);
                        $display("EXECUTION DONE!!!!!");
                end
                begin
                        repeat(5000)     @(posedge clk);
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
            if (DUT.inst_dcache.dmem[i] != golden_dmem[i]) begin
                $display("[FAIL] Mem [%0d] | Expected: %h | Got: %h", i, golden_dmem[i], DUT.inst_dcache.dmem[i]);
                incorrect_data += 1;
            end
        end
        if((incorrect_register == 0) && (incorrect_data == 0))  $display("@@@PASS");
        else                                                    $display("@@@FAIL wrong register=%d, and wrong data=%d",
                                                                          incorrect_register, incorrect_data);
    
	final_cpi = $itor(num_cycle)/$itor(num_inst);
	final_ipc = $itor(num_inst)/$itor(num_cycle);
	$display("Total Clock Cycles : %0d", num_cycle);
        $display("Total Instructions : %0d", num_inst);
        $display("----------------------------------------");
        $display("Performance (CPI)  : %0f Cycles/Inst", final_cpi);
        $display("Performance (IPC)  : %0f Inst/Cycles", final_ipc);
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
