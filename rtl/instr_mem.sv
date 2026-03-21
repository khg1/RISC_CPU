module instr_mem #(
	parameter int XPRLEN = 32,
	parameter int DEPTH = 500
)(
	input logic 		   clk,
	input logic  [XPRLEN-1:0]  address,
	output logic [XPRLEN-1:0]  instr
);

logic [XPRLEN-1:0] imem [0:DEPTH-1];

assign instr = (address%4==0)? imem[address/4] : '0;

always_ff @(posedge clk) begin
end

endmodule
