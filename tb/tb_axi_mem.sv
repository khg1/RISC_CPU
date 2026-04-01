class axi_packet;
	rand bit [31:0] start_addr;
    	rand bit [7:0]  burst_length;
    	rand bit [31:0] data_payload [];
    
    	constraint align_addr {
        	start_addr[1:0] == 2'b00;
        	start_addr < 4000;
	}
    
    	constraint burst_limit {
		burst_length inside {[0:15]};
	}
    
    	constraint payload_size {
        	data_payload.size() == burst_length + 1;
	}
endclass

module tb_axi_mem;

    logic clk, resetn;
    
    axi_if axi_bus();
    
    axi_mem DUT (
	.clk(clk),
	.resetn(resetn),
        .axi_port(axi_bus.AXI_SLAVE)
    );
    
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    initial begin
        axi_packet pkt;
        
	reset_bus();
        
        resetn = 0;
	repeat(5)	@(negedge clk);
	@(posedge clk);
        resetn = 1;
        
        $display("starting randomized AXI memory verification");
        
        for (int i = 0; i < 10; i++) begin
            pkt = new();
            if(!pkt.randomize())	$fatal(1,"randomization failed!");
            $display("test %0d: len = %0d, address = 0x%0h", i, pkt.burst_length, pkt.start_addr);
            write_burst(pkt);
            read_and_verify(pkt);
        end
        
        $display("@@@PASS");
        $finish;
    end
    
    task reset_bus();
        axi_bus.AWVALID = 0;
        axi_bus.WVALID  = 0;
        axi_bus.BREADY  = 0;
        axi_bus.ARVALID = 0;
        axi_bus.RREADY  = 0;
        axi_bus.WSTRB   = 0;
    endtask

    task write_burst(axi_packet p);
        @(posedge clk);
        axi_bus.AWVALID <= 1;
        axi_bus.AWADDR  <= p.start_addr;
        axi_bus.AWLEN   <= p.burst_length;
        axi_bus.AWSIZE  <= 3'b010; // 4 bytes
	axi_bus.AWBURST	<= 2'b01;
	do begin
		@(posedge clk);
	end while(!axi_bus.AWREADY);
        axi_bus.AWVALID <= 0;
        
        for (int i = 0; i <= p.burst_length; i++) begin
            axi_bus.WVALID <= 1;
            axi_bus.WDATA  <= p.data_payload[i];
            axi_bus.WSTRB  <= 4'hF;
            axi_bus.WLAST  <= (i == p.burst_length);
           
	    do begin 
		    @(posedge clk);
	    end while(!axi_bus.WREADY);
        end
        axi_bus.WVALID <= 0;
        axi_bus.WLAST  <= 0;
        
        axi_bus.BREADY <= 1;
	do begin 
	        @(posedge clk);
	end while(!axi_bus.BVALID);
        axi_bus.BREADY <= 0;

    endtask
    
    task read_and_verify(axi_packet p);
        logic [31:0] read_data;
        
        @(posedge clk);
        axi_bus.ARVALID <= 1;
        axi_bus.ARADDR  <= p.start_addr;
        axi_bus.ARLEN   <= p.burst_length;
        axi_bus.ARSIZE  <= 3'b010;
	    do begin 
		    @(posedge clk);
	    end while(!axi_bus.ARREADY);
        axi_bus.ARVALID <= 0;
        
        axi_bus.RREADY <= 1;
        for (int i = 0; i <= p.burst_length; i++) begin
	    do begin 
		    @(posedge clk);
	    end while(!axi_bus.RVALID);
            read_data = axi_bus.RDATA;
            if (read_data != p.data_payload[i]) begin
                $fatal(1,"data mismatch at index %0d, Expected: 0x%0h, Got: 0x%0h", i, p.data_payload[i], read_data);
            end
	    if(i == p.burst_length)	break;
        end
        axi_bus.RREADY <= 0;
    endtask

endmodule
