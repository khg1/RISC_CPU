module instruction_cache #(
	parameter int ADDR_WIDTH = 32,
	parameter int DATA_WIDTH = 32,
	parameter int RESP_WIDTH = 2
)(
	input	logic				clk,
	input	logic				resetn,
	input	logic	[ADDR_WIDTH-1:0]	address,
	output	logic	[DATA_WIDTH-1:0]	data,
	output	logic				stall_pipeline,
	axi_if.AXI_MASTER_READ			axi_port
);

typedef struct packed {
	logic				valid;
	logic	[25:0]			tag;
	logic	[0:3][DATA_WIDTH-1:0]	storage;
} icache_block_t;

typedef enum logic [1:0] {I_IDLE = 2'b00, I_REQ = 2'b01, I_HANDLE = 2'b10} icache_state_t;

icache_block_t [0:3] instruction_cache;
icache_state_t icache_current_state, icache_next_state;

logic [1:0] cache_index, word_offset, byte_offset;


logic	[ADDR_WIDTH-1:0]	missed_address;
logic	[1:0]			written_word_offset;
//pragma translate_off
logic   [RESP_WIDTH-1:0]	read_response;
//pragma translate_on
logic				hit;

assign stall_pipeline = ~hit;
assign cache_index = address[5:4];
assign word_offset = address[3:2];
assign byte_offset = address[1:0];

always_comb begin
	hit = 0;
	data = '0;
	if((instruction_cache[cache_index].tag == address[31:6])&&instruction_cache[cache_index].valid) begin
		data = instruction_cache[cache_index].storage[word_offset];
		hit = 1;
	end
	else	hit = 0;
end

always_ff @(posedge clk or negedge resetn) begin
	if(!resetn) begin
		icache_current_state <= I_IDLE;
	end
	else	icache_current_state <= icache_next_state;
end

always_comb begin
	case (icache_current_state)
		I_REQ:			icache_next_state = (axi_port.ARREADY & axi_port.ARVALID) ? I_HANDLE:I_REQ;
		I_HANDLE:		icache_next_state = (axi_port.RLAST & axi_port.RVALID) ? I_IDLE:I_HANDLE;
		I_IDLE:			icache_next_state = (!hit) ? I_REQ:I_IDLE;
		default:		icache_next_state = I_IDLE;
	endcase
end

always_ff @(posedge clk or negedge resetn) begin
	if(!resetn) begin
		missed_address <= '0;
		written_word_offset <= '0;
		axi_port.ARVALID <= 0;
		axi_port.ARADDR	<= '0;
		axi_port.ARLEN	<= '0;
		axi_port.ARSIZE	<= '0;
		axi_port.ARBURST <= '0;
		axi_port.RREADY	<= 0;
		for(int i = 0; i < 4; i++) begin
			instruction_cache[i].valid <= 0;
		end
	end
	else begin
		case (icache_current_state)
			I_REQ:	begin
				if(axi_port.ARREADY & axi_port.ARVALID) begin
					axi_port.ARVALID <= 0;
					axi_port.RREADY	<= 1;
				end
			end
			I_HANDLE: begin
				if(axi_port.RREADY & axi_port.RVALID) begin
					instruction_cache[missed_address[5:4]].storage[written_word_offset] <= axi_port.RDATA;
					written_word_offset <= written_word_offset + 1;
					//pragma translate_off
					read_response <= axi_port.RRESP;
					//pragma translate_on
					if(axi_port.RLAST) begin
						instruction_cache[missed_address[5:4]].valid <= 1;
						instruction_cache[missed_address[5:4]].tag <= missed_address[31:6];
						axi_port.RREADY <= 0;
						written_word_offset <= 0;
					end
				end
			end
			I_IDLE: begin
				if(!hit) begin
					missed_address <= address;
					axi_port.ARVALID <= 1;
					axi_port.ARADDR  <= {address[31:4], 4'h0};
					axi_port.ARLEN	<= 8'h03;	//4 words per block
					axi_port.ARSIZE	<= 3'h2;	// 4 bytes per word
					axi_port.ARBURST	<= 2'h1;
					instruction_cache[address[5:4]].valid <= 0;
				end
			end
		endcase
	end
end

endmodule
