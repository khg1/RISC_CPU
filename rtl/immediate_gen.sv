//pragma translate_off
`include "risc_pkg.sv"
//pragma translate_on
module immediate_gen #(
	parameter int XPRLEN = 32
)(
	input logic unsigned [XPRLEN-1:0] instr,
	output logic signed [XPRLEN-1:0] immediate_value
);
import risc_pkg::*;
logic unsigned [6:0] opcode;
logic unsigned [4:0] sign_bit_index;
logic unsigned [XPRLEN-1:0] temp;
always_comb begin
	opcode = instr[6:0];
	unique case (instr_t'(opcode))
		OP_IMM: begin
				temp = instr >> 20;
				sign_bit_index = 12;
				if(temp[sign_bit_index-1])	immediate_value = signed'(temp | (32'hFFFF_FFFF << sign_bit_index));
				else				immediate_value = signed'(temp);		
			end
		LOAD: begin
				temp = instr >> 20;
				sign_bit_index = 12;
				if(temp[sign_bit_index-1])	immediate_value = signed'(temp | (32'hFFFF_FFFF << sign_bit_index));
				else				immediate_value = signed'(temp);		
			end
		STORE: begin
				temp = ((instr & 32'hFE00_0000)>>20) + ((instr & 32'h0000_0F80)>>7);
			        sign_bit_index = 12;	
				if(temp[sign_bit_index-1])	immediate_value = signed'(temp | (32'hFFFF_FFFF << sign_bit_index));
				else				immediate_value = signed'(temp);		
			 end
		JAL: begin
				temp = ((instr & 32'h8000_0000)>>12) + ((instr & 32'h7FE0_0000)>>21)
					+ ((instr & 32'h0010_0000)>>10) + ((instr & 32'h000F_F000)>>1);
				sign_bit_index = 20;
				if(temp[sign_bit_index-1])	immediate_value = signed'(temp | (32'hFFFF_FFFF << sign_bit_index));
				else				immediate_value = signed'(temp);		
		       end
		BRANCH: begin
				temp = ((instr & 32'h8000_0000)>>20) + ((instr & 32'h0000_0080)<<3) 
					+ ((instr & 32'h7E00_0000)>>21) + ((instr & 32'h0000_0E00)>>8);
				sign_bit_index = 12;
				if(temp[sign_bit_index-1])	immediate_value = signed'(temp | (32'hFFFF_FFFF << sign_bit_index));
				else				immediate_value = signed'(temp);		
			end
		default: 	immediate_value = '0;

	endcase
end

endmodule
