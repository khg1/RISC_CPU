//pragma translate_off
`include "risc_pkg.sv"
//pragma translate_on
module control_unit (
	input logic [6:0]  opcode,
	output logic 	   branch,
	output logic       mem_read,
	output logic       mem_to_reg,
	output logic [1:0] aluop,
	output logic	   mem_write,
	output logic [1:0] alusrc,
	output logic	   reg_write
);

import risc_pkg::*;

always_comb begin
	unique case (instr_t'(opcode))
		OP: begin
			branch = 0;
			mem_read = 0;
			mem_to_reg = 0;
			aluop = 2'b10;
			mem_write = 0;
			alusrc = '0;
			reg_write = 1;
		    end
	    	OP_IMM: begin
			branch = 0;
			mem_read = 0;
			mem_to_reg = 0;
			aluop = 2'b11;
			mem_write = 0;
			alusrc = 2'b01;
			reg_write = 1;
			end	
		LOAD: begin
			branch = 0;
			mem_read = 1;
			mem_to_reg = 1;
			aluop = '0;
			mem_write = 0;
			alusrc = 2'b01;
			reg_write = 1;
		      end
		STORE: begin
			branch = 0;
			mem_read = 0;
			mem_to_reg = 0;
			aluop = '0;
			mem_write = 1;
			alusrc = 2'b01;
			reg_write = 0;
		       end
		BRANCH: begin
			 branch = 1;
			 mem_read = 0;
			 mem_to_reg = 0;
			 aluop = 2'b01;
			 mem_write = 0;
			 alusrc = '0;
			 reg_write = 0;
			end
		JAL: begin
			branch = 1;
			mem_read = 0;
			mem_to_reg = 0;
			aluop = '0;
			mem_write = 0;
			alusrc = 2'b10;
			reg_write = 1;
		     end
		default: begin
			  branch = 0;
			  mem_read = 0;
			  mem_to_reg = 0;
			  aluop = '0;
			  mem_write = 0;
			  alusrc = '0;
			  reg_write = 0;
			 end
	endcase
end

endmodule
