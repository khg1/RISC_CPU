module alu_control (
	input logic [1:0] aluop,
	input logic [3:0] funct,
        output logic [2:0] alu_ctrl_out	
);

always_comb begin
	unique case (aluop)
		2'b00: alu_ctrl_out = '0;	// Addition operation for LW and SW
		2'b01: alu_ctrl_out = 3'h1;    // Subtraction operation for BEQ BNE
		2'b10: begin
			if((funct & 4'h7) == '0) begin
				if(!funct[3]) alu_ctrl_out = '0;	// Register Addition
				else	      alu_ctrl_out = 3'h1;     // Register Subtraction
			end
			else if((funct & 4'h7) == 4'h4) alu_ctrl_out = 3'h4; //Register XOR
			else if((funct & 4'h7) == 4'h6) alu_ctrl_out = 3'h3; //Register OR
			else if((funct & 4'h7) == 4'h7) alu_ctrl_out = 3'h2; //Register AND
		       end
	        2'b11: begin
			if((funct & 4'h7) == '0) alu_ctrl_out = '0; //Immediate Addition
			else if((funct & 4'h7) == 4'h4) alu_ctrl_out = 3'h4; //Immediate XOR
			else if((funct & 4'h7) == 4'h6) alu_ctrl_out = 3'h3; //Immediate OR
			else if((funct & 4'h7) == 4'h7) alu_ctrl_out = 3'h2; //Immediate AND
		       end
	endcase

	
end

endmodule
