//pragma translate_off
`include "risc_pkg.sv"
//pragma translate_on
module instr_parser #(
    parameter int XPRLEN = 32
)(
    input  logic [XPRLEN-1:0] instruction,
    output logic [4:0] rs1, rs2, rd,
    output logic [6:0] opcode,
    output logic [3:0] funct
);
import risc_pkg::*;
assign opcode = instruction[6:0];
always_comb begin
	unique case(instr_t'(opcode))
		OP: begin
    			rs1 = instruction[19:15];
    			rs2 = instruction[24:20];
    			rd = instruction[11:7];
    			funct = {instruction[30], instruction[14:12]};
		      end
		OP_IMM: begin
			rs1 = instruction[19:15];
			rs2 = '0;
			rd  = instruction[11:7];
			funct = {1'b0, instruction[14:12]};
			end
		JAL: begin
			rs1 = '0;
			rs2 = '0;
			rd = instruction[11:7];
			funct = '0;
		       end
		BRANCH: begin
			rs1 = instruction[19:15];
                        rs2 = instruction[24:20];
			rd = '0;
                        funct = {1'b0, instruction[14:12]};
			end
		LOAD: begin
			rs1 = instruction[19:15];
                        rs2 = '0;
                        rd  = instruction[11:7];
                        funct = {1'b0, instruction[14:12]};
			end
		STORE: begin
			rs1 = instruction[19:15];
                        rs2 = instruction[24:20];
                        rd = '0;
                        funct = {1'b0, instruction[14:12]};
			end
		default: begin
			rs1 = '0;
			rs2 = '0;
			rd = '0;
			funct = '0;
			end
	endcase 
end

endmodule
