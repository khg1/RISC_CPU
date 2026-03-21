`include "risc_pkg.sv"
module core #(
	parameter int XPRLEN = 32
)(
	input  logic clk, resetn, 
	output logic done
);

/////////////////////////[IFID]///////////////////////
logic 		 [XPRLEN-1:0] ifid_pc, 		Q_ifid_pc;		
logic 		 [XPRLEN-1:0] ifid_instr, 	Q_ifid_instr;

///////////////////////[IDEX]///////////////////////	
logic 		 [XPRLEN-1:0] idex_pc, 			Q_idex_pc;		
logic 		 [XPRLEN-1:0] idex_data1, 		Q_idex_data1;	
logic 		 [XPRLEN-1:0] idex_data2, 		Q_idex_data2;	
logic 		 [XPRLEN-1:0] idex_immediate, 		Q_idex_immediate;
logic 		 [3:0]		idex_funct, 		Q_idex_funct;
logic 		 [4:0]          idex_rd, 		Q_idex_rd; 
logic		 [4:0]		idex_rs1, 		Q_idex_rs1; 
logic		 [4:0]          idex_rs2, 		Q_idex_rs2;
logic					  idex_mem_read,	Q_idex_mem_read;
logic					  idex_mem_write,	Q_idex_mem_write;
logic					  idex_mem_to_reg,  	Q_idex_mem_to_reg;
logic					  idex_reg_write,	Q_idex_reg_write;
logic		 [1:0]		  	  idex_aluop, 		Q_idex_aluop;
logic		 [1:0]			  idex_alusrc,		Q_idex_alusrc;

logic		 [XPRLEN-1:0] Q_idex_instr;

//////////////////////////[EXMEM]///////////////////////
logic 		 [XPRLEN-1:0] exmem_alu_result, 	Q_exmem_alu_result;
logic 		 [XPRLEN-1:0] exmem_data2, 			Q_exmem_data2;
logic 		 [4:0]	 	  exmem_rd, 			Q_exmem_rd; 
logic		 			  exmem_mem_read, 		Q_exmem_mem_read;
logic					  exmem_mem_write, 		Q_exmem_mem_write;
logic 		 			  exmem_reg_write, 		Q_exmem_reg_write;
logic					  exmem_mem_to_reg, 	Q_exmem_mem_to_reg;

logic		[XPRLEN-1:0] Q_exmem_instr;
//////////////////////////[MEMWB]///////////////////////
logic 		 [XPRLEN-1:0] memwb_mem_data, 		Q_memwb_mem_data;
logic 		 [XPRLEN-1:0] memwb_alu_result, 	Q_memwb_alu_result;
logic 		 [4:0]	 	  memwb_rd, 			Q_memwb_rd;
logic		 			  memwb_reg_write, 		Q_memwb_reg_write;
logic					  memwb_mem_to_reg, 	Q_memwb_mem_to_reg;

logic		[XPRLEN-1:0] Q_memwb_instr;
//	hazard detection signals
logic					  sig_write_enable;
logic					  sig_id_flush;
logic					  sig_pc_write;

// branch unit signals
logic			  	      sig_branch_detect;

// control unit signals
logic		 [6:0]		  sig_ctrl_opcode;
logic					  sig_ctrl_branch, sig_ctrl_mem_read;
logic					  sig_ctrl_mem_to_reg, sig_ctrl_mem_write;
logic		 [1:0]		  sig_ctrl_aluop, sig_ctrl_alusrc;
logic					  sig_ctrl_reg_write;

// mux select lines
logic		 [1:0]		  sig_branch_selA, sig_branch_selB;
logic		 [1:0] 		  sig_forward_selA, sig_forward_selB;

// alu control out signal
logic	     [2:0]		 sig_alu_ctrl_out;

logic signed [XPRLEN-1:0] sig_rf_out1, sig_rf_out2;
logic signed [XPRLEN-1:0] sig_alu_in1, sig_alu_in2;

logic signed [XPRLEN-1:0] sig_reg_data_in;

pc_unit inst_pc_unit (
	.clk(clk),
	.resetn(resetn),
	.branch_detect(sig_branch_detect),
	.pc_write(sig_pc_write),
	.pc_id(Q_ifid_pc),
	.imm_gen_in(idex_immediate),
	.pc_if(ifid_pc)
);

instr_mem inst_instr_mem (
	.clk(clk),
	.address(ifid_pc),
	.instr(ifid_instr)
);

instr_parser inst_instr_parser (
	.instruction(Q_ifid_instr),
	.rs1(idex_rs1), .rs2(idex_rs2),
	.funct(idex_funct), .opcode(sig_ctrl_opcode),
	.rd(idex_rd)
);

control_unit inst_control_unit (
	.opcode(sig_ctrl_opcode),
	.branch(sig_ctrl_branch),
	.mem_read(sig_ctrl_mem_read),
	.mem_to_reg(sig_ctrl_mem_to_reg),
	.aluop(sig_ctrl_aluop),
	.mem_write(sig_ctrl_mem_write),
	.alusrc(sig_ctrl_alusrc),
	.reg_write(sig_ctrl_reg_write)
);

always_comb begin
	if(sig_id_flush) begin
		idex_aluop 		= 0;
		idex_mem_read 	= 0;
		idex_alusrc 	= 0;
		idex_mem_write  = 0;
		idex_mem_to_reg = 0;
		idex_reg_write 	= 0;
	end
	else begin
		idex_aluop 		= sig_ctrl_aluop;
		idex_mem_read 	= sig_ctrl_mem_read;
		idex_alusrc 	= sig_ctrl_alusrc;
		idex_mem_write 	= sig_ctrl_mem_write;
		idex_mem_to_reg = sig_ctrl_mem_to_reg;
		idex_reg_write 	= sig_ctrl_reg_write;
	end
end

register_file inst_register_file (
	.clk(clk), .resetn(resetn), .reg_write(Q_memwb_reg_write),
	.rs1(idex_rs1), .rs2(idex_rs2), .rd(Q_memwb_rd),
	.rd_data(sig_reg_data_in), .rs1_data(sig_rf_out1), .rs2_data(sig_rf_out2)
);

immediate_gen inst_immediate_gen (
	.instr(Q_ifid_instr),
	.immediate_value(idex_immediate)
);

branch_detect_unit inst_branch_detect_unit (
	.opcode(sig_ctrl_opcode),
	.funct(idex_funct),
	.data1(idex_data1),
	.data2(idex_data2),
	.branch_detected(sig_branch_detect)
);

branch_forwarding_unit inst_branch_forwarding_unit (
	.rs1_id(idex_rs1), .rs2_id(idex_rs2), 
	.rd_ex(Q_idex_rd), .rd_mem(Q_exmem_rd), .rd_wb(Q_memwb_rd),
	.reg_write_ex(Q_idex_reg_write),
	.reg_write_mem(Q_exmem_reg_write),
	.reg_write_wb(Q_memwb_reg_write),
	.forward_a(sig_branch_selA),
	.forward_b(sig_branch_selB)
);

hazard_detect_unit inst_hazard_detection_unit (
	.opcode(sig_ctrl_opcode),
	.mem_read_ex(Q_idex_mem_read), .rd_ex(Q_idex_rd), .rs1_id(idex_rs1), .rs2_id(idex_rs2),
	.id_flush(sig_id_flush), .pc_write(sig_pc_write), .write_enable(sig_write_enable)
);

assign sig_reg_data_in = (Q_memwb_mem_to_reg) ? Q_memwb_mem_data : Q_memwb_alu_result;

// MUX for Selecting IDEX register data based on branching condition
always_comb begin
	unique case (sig_branch_selA)
		2'h0: idex_data1 = sig_rf_out1;
		2'h1: idex_data1 = Q_exmem_alu_result;
		2'h2: idex_data1 = sig_reg_data_in;
		2'h3: idex_data1 = exmem_alu_result;
	endcase
	unique case (sig_branch_selB)
		2'h0: idex_data2 = sig_rf_out2;
		2'h1: idex_data2 = Q_exmem_alu_result;
		2'h2: idex_data2 = sig_reg_data_in;
		2'h3: idex_data2 = exmem_alu_result;
	endcase
end

forwarding_unit inst_forwarding_unit(
	.rs1_ex(Q_idex_rs1), .rs2_ex(Q_idex_rs2), 
	.rd_mem(Q_exmem_rd), .rd_wb(Q_memwb_rd),
	.reg_write_mem(Q_exmem_reg_write), .reg_write_wb(Q_memwb_reg_write),
	.forward_a(sig_forward_selA), .forward_b(sig_forward_selB)
);

// MUX for Selecting Input data to ALU based on forwarding condition and instruction type
always_comb begin
	if(Q_idex_alusrc == 2'h2)	     sig_alu_in1 = Q_idex_pc;
	else if(sig_forward_selA == 2'h0)    sig_alu_in1 = Q_idex_data1;
	else if(sig_forward_selA == 2'h1)    sig_alu_in1 = Q_exmem_alu_result;
	else if(sig_forward_selA == 2'h2)    sig_alu_in1 = sig_reg_data_in;
	
	unique case (Q_idex_alusrc)
		2'h0: begin	
			if(sig_forward_selB == 2'h0)	     sig_alu_in2 = Q_idex_data2;
			else if(sig_forward_selB == 2'h1)    sig_alu_in2 = Q_exmem_alu_result;
		        else if(sig_forward_selB == 2'h2)    sig_alu_in2 = sig_reg_data_in;
		      end
	        2'h1: sig_alu_in2 = Q_idex_immediate;
		2'h2: sig_alu_in2 = 32'h0000_0004;
	endcase
end

alu_control inst_alu_constrol(
	.aluop(Q_idex_aluop),
	.funct(Q_idex_funct),
	.alu_ctrl_out(sig_alu_ctrl_out)
);

alu inst_alu (
	.operand_a(sig_alu_in1), .operand_b(sig_alu_in2),
	.alu_ctrl(sig_alu_ctrl_out), .alu_result(exmem_alu_result)
);

data_memory inst_data_memory (
	.clk(clk),
	.mem_read(Q_exmem_mem_read),
	.mem_write(Q_exmem_mem_write),
	.address(Q_exmem_alu_result),
	.data_in(Q_exmem_data2),
	.data_out(memwb_mem_data)
);

always_comb begin
	idex_pc			= Q_ifid_pc;			
	exmem_mem_read		= Q_idex_mem_read;
	exmem_mem_write		= Q_idex_mem_write;
	exmem_mem_to_reg	= Q_idex_mem_to_reg;
	exmem_reg_write		= Q_idex_reg_write;
	exmem_rd   			= Q_idex_rd;         
	exmem_data2             = Q_idex_data2;	
	memwb_reg_write		= Q_exmem_reg_write;
	memwb_alu_result	= Q_exmem_alu_result;
	memwb_mem_to_reg	= Q_exmem_mem_to_reg;
	memwb_rd		= Q_exmem_rd;
end

always_ff @(posedge clk or negedge resetn) begin
	if(!resetn) begin
		done <= 0;

		Q_ifid_pc 			<= '0;
		Q_ifid_instr		<= '0;

		Q_idex_pc			<= '0;
		Q_idex_data1		<= '0;
		Q_idex_data2		<= '0;
		Q_idex_immediate	<= '0;
		Q_idex_funct		<= '0;
		Q_idex_rd			<= '0;
	    Q_idex_rs1			<= '0;
	    Q_idex_rs2			<= '0;
		Q_idex_mem_read     <= '0;
		Q_idex_mem_write	<= '0;
		Q_idex_mem_to_reg	<= '0;
		Q_idex_reg_write    <= '0;
		Q_idex_aluop		<= '0;
		Q_idex_alusrc		<= '0;
		Q_idex_instr	<= '0;
		
		Q_exmem_alu_result	<= '0;
		Q_exmem_data2		<= '0;
		Q_exmem_rd			<= '0;
		Q_exmem_mem_read 	<= '0;
		Q_exmem_mem_write	<= '0;
		Q_exmem_reg_write 	<= '0;
		Q_exmem_mem_to_reg	<= '0;
		Q_exmem_instr <= '0;

		Q_memwb_reg_write	<= '0;
		Q_memwb_mem_data	<= '0;
		Q_memwb_alu_result	<= '0;
		Q_memwb_rd 			<= '0;
		Q_memwb_mem_to_reg	<= '0;
		Q_memwb_instr <= '0;
	end
	else begin
		if(Q_memwb_instr == 32'hFFFF_FFFF)	done <= 1;
		else					done <= 0;
		if(sig_branch_detect) begin
			Q_ifid_pc <= '0;
			Q_ifid_instr <= '0;
		end
		else if(sig_write_enable) begin
			Q_ifid_pc 	<= ifid_pc;
			Q_ifid_instr	<= ifid_instr;
		end
		Q_idex_pc			<= idex_pc;
		Q_idex_data1		<= idex_data1;
		Q_idex_data2		<= idex_data2;
		Q_idex_immediate	<= idex_immediate;
		Q_idex_funct		<= idex_funct;
		Q_idex_rd			<= idex_rd;
	    	Q_idex_rs1			<= idex_rs1;
	    	Q_idex_rs2			<= idex_rs2;
		Q_idex_mem_read     <= idex_mem_read;
		Q_idex_mem_write	<= idex_mem_write;
		Q_idex_mem_to_reg	<= idex_mem_to_reg;
		Q_idex_reg_write    <= idex_reg_write;
		Q_idex_aluop		<= idex_aluop;
		Q_idex_alusrc		<= idex_alusrc;
		Q_idex_instr		<= Q_ifid_instr;

		Q_exmem_alu_result	<= exmem_alu_result;
		Q_exmem_data2		<= exmem_data2;
		Q_exmem_rd			<= exmem_rd;
		Q_exmem_mem_read 	<= exmem_mem_read;
		Q_exmem_mem_write	<= exmem_mem_write;
		Q_exmem_reg_write 	<= exmem_reg_write;
		Q_exmem_mem_to_reg	<= exmem_mem_to_reg;
		Q_exmem_instr	<= Q_idex_instr;

		Q_memwb_mem_data	<= memwb_mem_data;
		Q_memwb_alu_result	<= memwb_alu_result;
		Q_memwb_rd 			<= memwb_rd;
		Q_memwb_mem_to_reg	<= memwb_mem_to_reg;
		Q_memwb_reg_write	<= memwb_reg_write;
		Q_memwb_instr	<= Q_exmem_instr;
	end
end

endmodule
