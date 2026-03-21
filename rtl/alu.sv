module alu #(
	parameter int XPRLEN = 32
)(
	input logic signed  [XPRLEN-1:0]  operand_a, operand_b,
	input logic 	    [2:0] 	 	  alu_ctrl,
	output logic signed [XPRLEN-1:0]  alu_result
);
import risc_pkg::*;

always_comb begin
	unique case (operation_t'(alu_ctrl))
		ADD:	alu_result = operand_a + operand_b;
		SUB:	alu_result = operand_a - operand_b;
		AND:	alu_result = operand_a & operand_b;
		OR:		alu_result = operand_a | operand_b;
		XOR:	alu_result = operand_a ^ operand_b;
	endcase
end

endmodule
