module axi_arbiter #(
    parameter int ADDR_WIDTH = 32,
    parameter int DATA_WIDTH = 32
)(
    input  logic clk,
    input  logic resetn,
    
    axi_if.AXI_SLAVE_READ	icache_axi,
    axi_if.AXI_SLAVE		dcache_axi,
    axi_if.AXI_MASTER		mem_axi
);

typedef enum logic [1:0] {IDLE = 2'b00, SERVE_ICACHE = 2'b01, SERVE_DCACHE_READ = 2'b10, SERVE_DCACHE_WRITE = 2'b11} state_t;
state_t current_state, next_state;

logic last_served; // 0 = icache, 1 =dcache

logic icache_req, dcache_req;
assign icache_req = icache_axi.ARVALID;
assign dcache_req = dcache_axi.ARVALID | dcache_axi.AWVALID;

always_ff @(posedge clk or negedge resetn) begin
    	if(!resetn) begin
        	current_state <= IDLE;
        	last_served   <= 1'b0;
   	end else begin
        	current_state <= next_state;
        	if(current_state == IDLE) begin
            		if(next_state == SERVE_ICACHE) 
               			last_served <= 1'b0;
            		else if(next_state == SERVE_DCACHE_READ || next_state == SERVE_DCACHE_WRITE) 
               			last_served <= 1'b1;
        	end
    	end
end

always_comb begin
	case(current_state)
		IDLE: begin
			if(icache_req && dcache_req) begin
				if(last_served == 1'b1)
				   next_state = SERVE_ICACHE;
				else begin
					if(dcache_axi.ARVALID) next_state = SERVE_DCACHE_READ;
					else               next_state = SERVE_DCACHE_WRITE;
				end
			end 
			else if(icache_req) begin
				next_state = SERVE_ICACHE;
			end 
			else if(dcache_req) begin
				if(dcache_axi.ARVALID) next_state = SERVE_DCACHE_READ;
			    	else               next_state = SERVE_DCACHE_WRITE;
			end
		end
		
		SERVE_ICACHE: begin
			if(mem_axi.RVALID && mem_axi.RREADY && mem_axi.RLAST)
				next_state = IDLE;
			end
		
		SERVE_DCACHE_READ: begin
		    	if(mem_axi.RVALID && mem_axi.RREADY && mem_axi.RLAST) 
		        	next_state = IDLE;
			end
		
		SERVE_DCACHE_WRITE: begin
		    	if(mem_axi.BVALID && mem_axi.BREADY) 
		        	next_state = IDLE;
			end
		
		default: next_state = IDLE;
    	endcase
end

always_comb begin
    	icache_axi.ARREADY = 0;
	icache_axi.RVALID = 0;
	icache_axi.RDATA = '0;
	icache_axi.RRESP = '0;
	icache_axi.RLAST = 0;
    	
	dcache_axi.ARREADY = 0;
	dcache_axi.RVALID = 0;
	dcache_axi.RDATA = '0;
	dcache_axi.RRESP = '0; 
	dcache_axi.RLAST = 0;
   	dcache_axi.AWREADY = 0; 
	dcache_axi.WREADY = 0; 
	dcache_axi.BVALID = 0; 
	dcache_axi.BRESP = '0;
    
   	mem_axi.ARVALID = 0; 
	mem_axi.ARADDR = '0; 
	mem_axi.ARLEN = '0; 
	mem_axi.ARSIZE = '0; 
	mem_axi.ARBURST = '0; 
	mem_axi.RREADY = 0;
    	mem_axi.AWVALID = 0; 
	mem_axi.AWADDR = '0; 
	mem_axi.AWLEN = '0; 
	mem_axi.AWSIZE = '0; 
	mem_axi.AWBURST = '0;
    	mem_axi.WVALID  = 0; 
	mem_axi.WDATA  = '0; 
	mem_axi.WLAST = 0; 
	mem_axi.BREADY = 0;

   	case(current_state)
   	    SERVE_ICACHE: begin
   	        mem_axi.ARVALID    = icache_axi.ARVALID;
   	        mem_axi.ARADDR     = icache_axi.ARADDR; // offset = 0x0000
   	        mem_axi.ARLEN      = icache_axi.ARLEN;
   	        mem_axi.ARSIZE     = icache_axi.ARSIZE;
   	        mem_axi.ARBURST    = icache_axi.ARBURST;
   	        icache_axi.ARREADY = mem_axi.ARREADY;

   	        icache_axi.RVALID  = mem_axi.RVALID;
   	        icache_axi.RDATA   = mem_axi.RDATA;
   	        icache_axi.RRESP   = mem_axi.RRESP;
   	        icache_axi.RLAST   = mem_axi.RLAST;
   	        mem_axi.RREADY     = icache_axi.RREADY;
   	    end

   	    SERVE_DCACHE_READ: begin
   	        mem_axi.ARVALID    = dcache_axi.ARVALID;
   	        mem_axi.ARADDR     = dcache_axi.ARADDR + 32'h0000_0800; // THE DATA OFFSET TRANSLATION
   	        mem_axi.ARLEN      = dcache_axi.ARLEN;
   	        mem_axi.ARSIZE     = dcache_axi.ARSIZE;
   	        mem_axi.ARBURST    = dcache_axi.ARBURST;
   	        dcache_axi.ARREADY = mem_axi.ARREADY;

   	        dcache_axi.RVALID  = mem_axi.RVALID;
   	        dcache_axi.RDATA   = mem_axi.RDATA;
   	        dcache_axi.RRESP   = mem_axi.RRESP;
   	        dcache_axi.RLAST   = mem_axi.RLAST;
   	        mem_axi.RREADY     = dcache_axi.RREADY;
   	    end

   	    SERVE_DCACHE_WRITE: begin
   	        mem_axi.AWVALID    = dcache_axi.AWVALID;
   	        mem_axi.AWADDR     = dcache_axi.AWADDR + 32'h0000_0800; // THE DATA OFFSET TRANSLATION
   	        mem_axi.AWLEN      = dcache_axi.AWLEN;
   	        mem_axi.AWSIZE     = dcache_axi.AWSIZE;
   	        mem_axi.AWBURST    = dcache_axi.AWBURST;
   	        dcache_axi.AWREADY = mem_axi.AWREADY;

   	        mem_axi.WVALID     = dcache_axi.WVALID;
   	        mem_axi.WDATA      = dcache_axi.WDATA;
   	        mem_axi.WLAST      = dcache_axi.WLAST;
		mem_axi.WSTRB	   = dcache_axi.WSTRB;
   	        dcache_axi.WREADY  = mem_axi.WREADY;

   	        dcache_axi.BVALID  = mem_axi.BVALID;
   	        dcache_axi.BRESP   = mem_axi.BRESP;
   	        mem_axi.BREADY     = dcache_axi.BREADY;
   	    end
   	endcase
end

endmodule
