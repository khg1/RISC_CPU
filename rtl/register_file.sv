module register_file #(
	parameter int XPRLEN = 32
)(
	input  logic				clk, resetn, reg_write,
	input  logic unsigned [4:0] 		rs1, rs2, rd,
	input  logic signed   [XPRLEN-1:0]	rd_data,
	output logic signed   [XPRLEN-1:0]	rs1_data, rs2_data
		
);

logic signed 	[XPRLEN-1:0] x  [XPRLEN-1:0];

always_comb begin
	rs1_data = x[rs1];
	rs2_data = x[rs2];
end

always_ff @(posedge clk or negedge resetn) begin
	if(!resetn) begin
		for(int i=0;i<XPRLEN-1;i++)	x[i] <= '0;
	end
	else begin
		if(reg_write)	begin
			if(rd != 0)	x[rd] <= rd_data;
			else		x[rd] <= '0;
		end
	end
end
endmodule
