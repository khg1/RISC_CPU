module data_cache #(
        parameter int XPRLEN = 32,
	parameter int ADDR_WIDTH = 32,
	parameter int DATA_WIDTH = 32,
	parameter int RESP_WIDTH = 2
)(
	input	logic					clk, resetn,	
	input	logic  	     				mem_read, mem_write,
	input	logic 		[XPRLEN-1:0] 		address,
	input	logic	signed	[XPRLEN-1:0] 		data_in,
    	output	logic	signed	[XPRLEN-1:0] 		data_out,
	output	logic					stall_pipeline,
	axi_if.AXI_MASTER	axi_port

);

typedef struct packed{
	logic				valid;
	logic				dirty;
	logic	[26:0]			tag;
	logic	[0:1][DATA_WIDTH-1:0]	storage;
} set_t;

typedef struct packed{
	logic		lru;
	set_t	[0:1]	set;
} dcache_block_t;

typedef enum logic [2:0] {D_IDLE=3'h0, W_REQ=3'h1, W_HANDLE=3'h2, W_RESP=3'h3, R_REQ=3'h4, R_HANDLE=3'h5, D_WAIT=3'h6} dcache_state_t;

dcache_block_t [0:3] data_cache;

logic		hit;
logic		done;

logic		word_offset;
logic	[1:0]	byte_offset, cache_index;

logic		set_hit_index;

logic   [ADDR_WIDTH-1:0]	missed_address;
logic	[DATA_WIDTH-1:0]	missed_data;
logic   			written_word_offset;
logic   [RESP_WIDTH-1:0] 	read_response;
logic	[RESP_WIDTH-1:0]	write_response;

logic [7:0] remain_transfer;
logic [3:0] transfer_size;

dcache_state_t dcache_current_state, dcache_next_state;

assign stall_pipeline = (mem_read | mem_write) & ~hit & ~done;
assign word_offset = address[2];
assign byte_offset = address[1:0];
assign cache_index = address[4:3];

always_comb begin
	hit = 0;
	set_hit_index = 0;
	data_out = '0;
	for(int i=0; i<2; i++) begin
		if((data_cache[cache_index].set[i].valid == 1) && (data_cache[cache_index].set[i].tag == address[31:5])) begin
			set_hit_index = i;
			if(mem_read)	data_out = data_cache[cache_index].set[i].storage[word_offset];
			hit = 1;
		end
	end
end

always_ff @(posedge clk or negedge resetn) begin
        if(!resetn) begin
                dcache_current_state      <= D_IDLE;
		for (int i = 0; i < 4; i++) begin
                        data_cache[i].lru <= 0;
                        for (int j = 0; j < 2; j++) begin
                                data_cache[i].set[j].valid <= 0;
                                data_cache[i].set[j].dirty <= 0;
                        end
                end
        end
        else begin
                dcache_current_state      <= dcache_next_state;
	end
end

always_comb begin
        case (dcache_current_state)
		D_IDLE:	begin
			if(!hit & ~done)	begin
				if(mem_write)										dcache_next_state = W_REQ;
				else if(mem_read && data_cache[cache_index].set[data_cache[cache_index].lru].dirty)	dcache_next_state = W_REQ;
				else if(mem_read && !data_cache[cache_index].set[data_cache[cache_index].lru].dirty)	dcache_next_state = R_REQ;
				else											dcache_next_state = D_IDLE;
			end
			else	dcache_next_state = D_IDLE;
		end
		W_REQ:	dcache_next_state = (axi_port.AWVALID && axi_port.AWREADY) ? W_HANDLE:W_REQ;
		W_HANDLE: dcache_next_state = (axi_port.WLAST && axi_port.WREADY)	? W_RESP:W_HANDLE;
		W_RESP: begin
			if(mem_write)		dcache_next_state = (axi_port.BVALID && axi_port.BREADY) ? D_WAIT:W_RESP;
			else if(mem_read)	dcache_next_state = (axi_port.BVALID && axi_port.BREADY) ? R_REQ:W_RESP;
		end
		D_WAIT: dcache_next_state = (!mem_read && !mem_write) ? D_IDLE : D_WAIT;
		R_REQ: dcache_next_state = (axi_port.ARVALID && axi_port.ARREADY) ? R_HANDLE:R_REQ;
		R_HANDLE: dcache_next_state = (axi_port.RLAST && axi_port.RREADY)	? D_IDLE:R_HANDLE;
		default: dcache_next_state = D_IDLE;
	endcase
end

always_ff @(posedge clk or negedge resetn) begin
        if(!resetn) begin
		axi_port.AWVALID	<= 0;
		axi_port.AWADDR		<= '0;
		axi_port.AWLEN		<= '0;
		axi_port.AWSIZE		<= '0;
		axi_port.AWBURST	<= '0;
                
		axi_port.WVALID		<= 0;
		axi_port.WDATA		<= '0;
		axi_port.WSTRB		<= '0;
		axi_port.WLAST		<= 0;

		axi_port.ARVALID         <=  0;
                axi_port.ARADDR          <= '0;
                axi_port.ARLEN           <= '0;
                axi_port.ARSIZE          <= '0;
                axi_port.ARBURST         <= '0;
                
		axi_port.RREADY          <= '0;
		
		axi_port.BREADY		<= '0;
                
		written_word_offset <= '0;
                missed_address  <= '0;
		done <= '0;
                
        end
	else begin
       		case (dcache_current_state)
			D_WAIT: begin
                                done <= 1;
                                axi_port.AWVALID <= 0;
                                axi_port.ARVALID <= 0;
                                if(!mem_read && !mem_write) begin
                                	done <= 0;
                                end
                        end
			W_REQ: begin
				if(axi_port.AWREADY & axi_port.AWVALID) begin
					axi_port.AWVALID <= 0;
					axi_port.WVALID	<= 1;
					if(mem_write)	begin
						axi_port.WDATA	<= missed_data;
						axi_port.WLAST	<= 1;
					end
					else	begin
						axi_port.WDATA	<= data_cache[missed_address[4:3]].set[data_cache[missed_address[4:3]].lru].storage[0];
						axi_port.WLAST	<= 0;
					end	
					remain_transfer <= axi_port.AWLEN;
					transfer_size	<= axi_port.AWSIZE;
				end
			end
			W_HANDLE: begin
				if(axi_port.WREADY & axi_port.WVALID) begin
					if(axi_port.AWBURST == 2'h1) begin
						if(remain_transfer != '0) begin
							axi_port.WDATA	<= data_cache[missed_address[4:3]].set[data_cache[missed_address[4:3]].lru].storage[remain_transfer];
							axi_port.WLAST	<= (remain_transfer == 1);
							remain_transfer <= remain_transfer - 1;
						end
						else begin
							axi_port.WLAST <= 0;
							axi_port.WVALID <= 0;
							axi_port.WDATA <= '0;
							axi_port.BREADY <= 1;
						end
					end		
				end
			end
			W_RESP: begin
				if(axi_port.BREADY & axi_port.BVALID) begin
					axi_port.BREADY <= 0;
					write_response <= axi_port.BRESP;
					if(mem_write)	done <= 1;
					if(mem_read)	begin
						axi_port.ARVALID <= 1;
                                                axi_port.ARADDR  <= {address[31:3], 3'h0};
                                                axi_port.ARLEN   <= 8'h01;       //2 words per set
                                                axi_port.ARSIZE  <= 3'h2;        //4 bytes per word
                                                axi_port.ARBURST <= 2'h1;
					end
				end
			end

       			R_REQ:  begin
                                if(axi_port.ARREADY & axi_port.ARVALID) begin
                                        axi_port.ARVALID <= 0;
					axi_port.RREADY  <= 1;
                                end
                        end
                        R_HANDLE: begin
                                if(axi_port.RREADY & axi_port.RVALID) begin
                                        if(axi_port.ARBURST == 2'h1) begin
                                                data_cache[missed_address[4:3]].set[data_cache[missed_address[4:3]].lru].storage[written_word_offset] <= axi_port.RDATA;
                                                written_word_offset <= written_word_offset + 1;
                                                read_response <= axi_port.RRESP;

                                                if(axi_port.RLAST) begin
                                                        data_cache[missed_address[4:3]].set[data_cache[missed_address[4:3]].lru].valid <= 1;
                                                        data_cache[missed_address[4:3]].set[data_cache[missed_address[4:3]].lru].tag <= missed_address[31:5];
							data_cache[missed_address[4:3]].set[data_cache[missed_address[4:3]].lru].dirty <= 0;
                                                        axi_port.RREADY <= 0;
                                                        written_word_offset <= 0;
							done <= 1;
                                                end
                                        end
                                end
                        end
                        D_IDLE: begin
				done <= 0;
				axi_port.AWVALID <= '0;
				if(mem_read || mem_write) begin
                        	        if(!hit) begin
                        	                missed_address 	<= address;
						missed_data	<= data_in;
						if(mem_read)	data_cache[cache_index].set[data_cache[cache_index].lru].valid <= 0;
						if((mem_read && data_cache[cache_index].set[data_cache[cache_index].lru].dirty) || mem_write) begin
							axi_port.AWVALID <= 1;
							if(mem_write) begin
								axi_port.AWADDR <= address;
								axi_port.AWLEN  <= '0;  //1 input data
							end
							else	begin
								axi_port.AWADDR	<= {data_cache[cache_index].set[data_cache[cache_index].lru].tag, cache_index, 3'h0};
								axi_port.AWLEN	<= 8'h01;	//2 words per set
							end
							axi_port.AWSIZE	<= 3'h2;		//4 bytes per word
							axi_port.AWBURST	<= 2'h1;
							axi_port.WSTRB	<= 4'hF;
						end
						else if(mem_read && !data_cache[cache_index].set[data_cache[cache_index].lru].dirty) begin
                        	                	axi_port.ARVALID <= 1;
                        	                	axi_port.ARADDR  <= {address[31:3], 3'h0};
                        	                	axi_port.ARLEN   <= 8'h01;       //2 words per set
                        	                	axi_port.ARSIZE  <= 3'h2;        //4 bytes per word
                        	                	axi_port.ARBURST <= 2'h1;
						end
                        	        end
					else begin
						data_cache[cache_index].lru <= ~set_hit_index;
						if(mem_write) begin
							data_cache[cache_index].set[set_hit_index].valid <= 1;
							data_cache[cache_index].set[set_hit_index].dirty <= 1;
                        	                 	data_cache[cache_index].set[set_hit_index].tag <= address[31:5];
							data_cache[cache_index].set[set_hit_index].storage[word_offset] <= data_in;
						end
					end
				end
                        end
		endcase
	end
end

endmodule
