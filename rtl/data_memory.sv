module data_memory #(
	parameter int XPRLEN = 32,
	parameter int DEPTH = 500
)(
	input logic		clk,
	input logic  	     	mem_read, mem_write,
	input logic  	     	[XPRLEN-1:0] address,
	input logic  signed  	[XPRLEN-1:0] data_in,
    	output logic signed  	[XPRLEN-1:0] data_out	
);

logic [XPRLEN-1:0] dmem [0:DEPTH-1];


always_comb begin
	if(mem_read & (address%4==0)) data_out = dmem[address/4];
end

always_ff @(posedge clk) begin
	if(mem_write && (address%4==0)) begin
		dmem[address/4] <= data_in;
	end
end

endmodule
