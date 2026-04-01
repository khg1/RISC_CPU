module axi_mem #(
	parameter int	XPRLEN	= 32,
 	parameter int	DEPTH   = 1024
)(
	input clk, resetn,
	axi_if.AXI_SLAVE axi_port
);

typedef enum logic [1:0]	{SR_IDLE=2'b00, SR_ADDR=2'b01, SR_DATA=2'b10} axiread_state_t;
typedef enum logic [1:0]	{SW_IDLE=2'b00, SW_DATA=2'b01, SW_RESP=2'b10}	axiwrite_state_t;

axiread_state_t current_axiread_state, next_axiread_state;
axiwrite_state_t current_axiwrite_state, next_axiwrite_state;

logic [XPRLEN-1:0] mem [0:DEPTH-1];

logic [7:0] 		sig_read_remain;
logic [XPRLEN-1:0] 	sig_read_addr;
logic [3:0] 		sig_read_size;

logic [7:0] 		sig_write_remain;
logic [XPRLEN-1:0] 	sig_write_addr;
logic [3:0] 		sig_write_size;


always_ff @(posedge clk or negedge resetn) begin
	if(!resetn)	current_axiread_state <= SR_IDLE;
	else			current_axiread_state <= next_axiread_state;
end

always_ff @(posedge clk or negedge resetn) begin
	if(!resetn)	current_axiwrite_state	<= SW_IDLE;
	else			current_axiwrite_state	<= next_axiwrite_state;
end

always_comb begin
	case(current_axiread_state)
		SR_ADDR: next_axiread_state = (axi_port.ARVALID & axi_port.ARREADY) ? SR_DATA:SR_ADDR;
		SR_DATA: next_axiread_state = (axi_port.RVALID & axi_port.RREADY & axi_port.RLAST) ? SR_IDLE:SR_DATA;
		SR_IDLE: next_axiread_state = (axi_port.ARVALID) ? SR_ADDR:SR_IDLE;
		default: next_axiread_state = SR_IDLE;
	endcase
end

always_comb begin
	case(current_axiwrite_state)
		SW_DATA: next_axiwrite_state = (axi_port.WVALID & axi_port.WREADY & axi_port.WLAST) ? SW_RESP:SW_DATA; 
		SW_RESP: next_axiwrite_state = (axi_port.BVALID & axi_port.BREADY) ? SW_IDLE:SW_RESP;
		SW_IDLE: next_axiwrite_state = axi_port.AWVALID ? SW_DATA : SW_IDLE;
		default: next_axiwrite_state = SW_IDLE;
	endcase
end

always_ff @(posedge clk or negedge resetn) begin
	if(!resetn)	begin
		sig_read_remain <= '0;
		sig_read_addr	<= '0;
		sig_read_size	<= '0;
		axi_port.ARREADY <= '0;
		axi_port.RVALID	 <= '0;
		axi_port.RDATA <= '0;
		axi_port.RRESP <= '0;
		axi_port.RLAST <= '0;
	end
	else begin
		case(current_axiread_state)
			SR_ADDR: begin
				if(axi_port.ARVALID && axi_port.ARREADY) begin
					axi_port.ARREADY <= 0;
					axi_port.RVALID	 <= 1;
					axi_port.RDATA	 <= mem[sig_read_addr>>2];
					sig_read_addr <= sig_read_addr + (32'h0000_0001 << sig_read_size);
					axi_port.RLAST	<= (sig_read_remain == 0);	
				end
			end
			SR_DATA: begin
				if(axi_port.RREADY) begin
					if(sig_read_remain != 0) begin
						axi_port.RLAST	<= (sig_read_remain == 1);
						axi_port.RDATA <= mem[sig_read_addr>>2];
						sig_read_addr <= sig_read_addr + (32'h0000_0001 << sig_read_size);
						sig_read_remain <= sig_read_remain - 1;
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
					sig_read_addr <= axi_port.ARADDR;
					sig_read_remain	 <= axi_port.ARLEN;
					sig_read_size	 <= axi_port.ARSIZE;
				end
			end
		endcase
	end
end

always_ff @(posedge clk or negedge resetn) begin
	if(!resetn) begin
		sig_write_remain	<= '0;
		sig_write_addr		<= '0;
		sig_write_size		<= '0;
		axi_port.AWREADY	<= 0;
		axi_port.WREADY		<= 0;
		axi_port.BVALID		<= 0;
		axi_port.BRESP		<= 0;
	end
	else begin
		case(current_axiwrite_state)
			SW_DATA: begin
				axi_port.AWREADY <= 0;
				axi_port.WREADY	 <= 1;

				if(axi_port.WVALID && axi_port.WREADY) begin
					if(axi_port.WSTRB[0])	mem[sig_write_addr>>2][7:0]	<= axi_port.WDATA[7:0];
					if(axi_port.WSTRB[1])	mem[sig_write_addr>>2][15:8]	<= axi_port.WDATA[15:8];
					if(axi_port.WSTRB[2])	mem[sig_write_addr>>2][23:16]	<= axi_port.WDATA[23:16];
					if(axi_port.WSTRB[3])	mem[sig_write_addr>>2][31:24]	<= axi_port.WDATA[31:24];

					if(sig_write_remain != '0) begin
						sig_write_addr	<= sig_write_addr + (32'h0000_0001 << sig_write_size);
						sig_write_remain <= sig_write_remain - 1;
					end
					else begin
						axi_port.WREADY	<= 0;
					end
				end
			end
			SW_RESP: begin
				axi_port.BVALID	<= 1;
				axi_port.BRESP	<= '0;
				if(axi_port.BVALID && axi_port.BREADY) begin
					axi_port.BVALID	<= 0;
				end
			end
			SW_IDLE: begin
				if(axi_port.AWVALID) begin
					axi_port.AWREADY	<= 1;
					sig_write_addr		<= axi_port.AWADDR;
					sig_write_remain	<= axi_port.AWLEN;
					sig_write_size		<= axi_port.AWSIZE;
				end
			end
		endcase
	end
end

endmodule
