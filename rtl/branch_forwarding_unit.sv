module branch_forwarding_unit (
	input logic [4:0] 	rs1_id, rs2_id, rd_ex, rd_mem, rd_wb,
    input logic	  	    reg_write_ex, reg_write_mem, reg_write_wb,
	output logic [1:0]  forward_a, forward_b
);

always_comb begin
	if((reg_write_mem) && (rd_mem == rs1_id) && (rd_mem != '0)) 	  	  forward_a = 2'h1;  // alu_result_mem
	else if((reg_write_wb) && (rd_wb == rs1_id) && (rd_wb != '0))       	  forward_a = 2'h2;  // mem_data or alu_result_wb
	else if((reg_write_ex) && (rd_ex == rs1_id) && (rd_ex != '0))       	  forward_a = 2'h3;  // alu output
	else					          			  forward_a = 2'h0;  // no forwarding

	if((reg_write_mem) && (rd_mem == rs2_id) && (rd_mem != '0)) 	    forward_b = 2'h1;  // alu_resultx1
	else if((reg_write_wb) && (rd_wb == rs2_id) && (rd_wb != '0))       forward_b = 2'h2;  // mem_data or alu_resultx2
	else if((reg_write_ex) && (rd_ex == rs2_id) && (rd_ex != '0))       forward_b = 2'h3;  // alu output
	else					          		    forward_b = 2'h0;  // no forwarding
end

endmodule
