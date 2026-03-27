module hazard_detect_unit (
	input  logic 		mem_read_ex,
       	input  logic [6:0]	opcode,	
	input  logic [4:0]	rd_ex, rs1_id, rs2_id,
	input  logic		i_cpu_stall, d_cpu_stall, branch_taken,
	output logic 		id_flush, pc_write, write_enable
);

always_comb begin
	if(d_cpu_stall) begin
		pc_write = 0;
		write_enable = 0;
		id_flush = 0;
	end
	else if(branch_taken) begin
		pc_write = 1;
		write_enable = 1;
		id_flush = 0;
	end
	else if(i_cpu_stall) begin
		pc_write = 0;
		write_enable = 0;
		id_flush = 0;
	end
	else if((mem_read_ex && (rd_ex != 0) && ((rd_ex == rs1_id)||(rd_ex == rs2_id))) || (opcode == 7'h7F)) begin
		pc_write = 0;
		write_enable = 0;
		id_flush = 1;
	end
	else	begin
		pc_write = 1;
		write_enable = 1;
		id_flush = 0;
	end
end

endmodule
