module pc_unit #(
	parameter int XPRLEN = 32
)(
	input  logic 					clk, resetn, branch_detect, pc_write,
	input  logic 	    [XPRLEN-1:0]		pc_id,
	input  logic signed [XPRLEN-1:0]		imm_gen_in,
	output logic	    [XPRLEN-1:0]		pc_if
);

logic	     [XPRLEN-1:0] adder_four;
logic signed [XPRLEN-1:0] adder_branch;

assign	adder_four = pc_if + 32'h0000_0004;
assign  adder_branch = signed'(pc_id) + (imm_gen_in <<< 1);

always_ff @(posedge clk or negedge resetn) begin
	if(!resetn)	pc_if <= '0;
	else begin
		if(pc_write) begin
			if(branch_detect)	pc_if <= adder_branch;
			else			pc_if <= adder_four;
		end			
	end
end

endmodule
