module axi_mem #(
	parameter int	XPRLEN	= 32,
 	parameter int	DEPTH    = 500
)(
	risc_if.sub_modport axi_port
);

typedef enum logic [1:0] {SR_IDLE=2'b00, SR_ADDR=2'b01, SR_DATA=2'b10} axi_state_t;
axi_state_t current_axi_state, next_axi_state;

logic [XPRLEN-1:0] mem [0:DEPTH-1];

logic [7:0] remain_transfer;
logic [XPRLEN-1:0] sig_addr;
logic [3:0] transfer_size;


always_ff @(posedge axi_port.clk or negedge axi_port.resetn) begin
	if(!axi_port.resetn)	current_axi_state <= SR_IDLE;
	else			current_axi_state <= next_axi_state;
end

always_comb begin
	unique case(current_axi_state)
		SR_ADDR: next_axi_state = (axi_port.ARVALID & axi_port.ARREADY) ? SR_DATA:SR_ADDR; 
		SR_DATA: next_axi_state = (axi_port.RVALID & axi_port.RREADY & axi_port.RLAST) ? SR_IDLE:SR_DATA;
		SR_IDLE: next_axi_state = (axi_port.ARVALID) ? SR_ADDR:SR_IDLE;
	endcase
end

always_ff @(posedge axi_port.clk or negedge axi_port.resetn) begin
	if(!axi_port.resetn)	begin
		remain_transfer <= '0;
		sig_addr	<= '0;
		transfer_size	<= '0;
		axi_port.ARREADY <= '0;
		axi_port.RVALID	 <= '0;
		axi_port.RDATA <= '0;
		axi_port.RRESP <= '0;
		axi_port.RLAST <= '0;
	end
	else begin
		unique case(current_axi_state)
			SR_ADDR: begin
				if(axi_port.ARVALID && axi_port.ARREADY) begin
					axi_port.ARREADY <= 0;
					axi_port.RVALID	 <= 1;
					axi_port.RDATA	 <= mem[sig_addr>>2];
					sig_addr <= sig_addr + (32'h0000_0001 << transfer_size);
					axi_port.RLAST	<= (remain_transfer == 0);	
				end
			end
			SR_DATA: begin
				if(axi_port.RREADY) begin
					if(remain_transfer != 0) begin
						axi_port.RLAST	<= (remain_transfer == 1);
						axi_port.RDATA <= mem[sig_addr>>2];
						sig_addr <= sig_addr + (32'h0000_0001 << transfer_size);
						remain_transfer <= remain_transfer - 1;
					end
					else begin
						axi_port.RLAST <= 0;
						axi_port.RVALID <= 0;
					end
				end
			end
			SR_IDLE: begin
				if(axi_port.ARVALID) begin
					axi_port.ARREADY <= 1;
					sig_addr <= axi_port.ARADDR;
					remain_transfer	 <= axi_port.ARLEN;
					transfer_size	 <= axi_port.ARSIZE;
				end
			end
		endcase
	end
end

endmodule
