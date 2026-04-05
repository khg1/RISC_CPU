module tb_dcache;

    logic clk;
    logic resetn;
    
    logic [31:0] address;
    logic [31:0] data_in;
    logic        mem_read;
    logic        mem_write;
    logic [31:0] data_out;
    logic	 done;
    logic        stall_pipeline;

    logic [7:0]	error_count;

    axi_if axi_bus();
    
    data_cache DUT (
        .clk(clk),
        .resetn(resetn),
        .address(address),
        .data_in(data_in),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .data_out(data_out),
        .stall_pipeline(stall_pipeline),
        .axi_port(axi_bus.AXI_MASTER)
    );

    axi_mem main_memory (
	.clk(clk),
	.resetn(resetn),
        .axi_port(axi_bus.AXI_SLAVE)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    task cpu_read(input [31:0] addr, input [31:0] expected_data);
        @(posedge clk);
        address   <= addr;
        mem_read  <= 1;
        mem_write <= 0;

	@(posedge clk);
       
	while(stall_pipeline == 1) begin
		@(posedge clk);	
	end
        
        if (data_out != expected_data) begin
            $error("READ FAILED at 0x%0h: Expected 0x%0h, Got 0x%0h", addr, expected_data, data_out);
	    error_count += 1;
        end 
	else begin
            $display("READ SUCCESS at 0x%0h: Data = 0x%0h", addr, data_out);
        end
        
        mem_read <= 0;
    endtask

    task cpu_write(input [31:0] addr, input [31:0] write_data);
        @(posedge clk);
        address   <= addr;
        data_in   <= write_data;
        mem_write <= 1;
        mem_read  <= 0;
        
	@(posedge clk);

	while (stall_pipeline == 1) begin
		@(posedge clk);	
	end
        
        $display("WRITE SUCCESS to 0x%0h: Data = 0x%0h", addr, write_data);
        mem_write <= 0;
	endtask

    initial begin
	error_count = 0;
        address   = 0;
        data_in   = 0;
        mem_read  = 0;
        mem_write = 0;
        resetn = 0;
	repeat(5)	@(negedge clk);
	resetn = 1;
	@(posedge clk);
        
	// set 0 (cache_index = 00)
        main_memory.mem[32'h0000_0000 >> 2] = 32'hA000_0000; // Block A, Word 0
        main_memory.mem[32'h0000_0004 >> 2] = 32'hA000_0001; // Block A, Word 1
        
        main_memory.mem[32'h0000_0020 >> 2] = 32'hB000_0000; // Block B, Word 0 (Maps to Set 0)
        main_memory.mem[32'h0000_0024 >> 2] = 32'hB000_0001; // Block B, Word 1
        
        main_memory.mem[32'h0000_0040 >> 2] = 32'hC000_0000; // Block C, Word 0 (Maps to Set 0)
        main_memory.mem[32'h0000_0044 >> 2] = 32'hC000_0001; // Block C, Word 1

	// set 1 (cache_index = 01)
        main_memory.mem[32'h0000_0008 >> 2] = 32'hD000_0000; // Block D, Word 0 
        main_memory.mem[32'h0000_000C >> 2] = 32'hD000_0001; // Block D, Word 1 

        // set 2 (cache_index = 10)
        main_memory.mem[32'h0000_0010 >> 2] = 32'hE000_0000; // Block E, Word 0 
        main_memory.mem[32'h0000_0014 >> 2] = 32'hE000_0001; // Block E, Word 1 

        // set 3 (cache_index = 11)
        main_memory.mem[32'h0000_0018 >> 2] = 32'hF000_0000; // Block F, Word 0 
        main_memory.mem[32'h0000_001C >> 2] = 32'hF000_0001; // Block F, Word 1	

        $display("starting tests");

        $display("fetch block A into set 0, column 0");
        cpu_read(32'h0000_0000, 32'hA000_0000);

        $display("fetch block D into set 1, column 0");
        cpu_read(32'h0000_0008, 32'hD000_0000);

        $display("fetch block E into set 2, column 0");
        cpu_read(32'h0000_0010, 32'hE000_0000);
        
        $display("fetch block F into set 3, column 0");
        cpu_read(32'h0000_0018, 32'hF000_0000);

	$display("fetch block B into set 0, column 1");
	cpu_read(32'h0000_0020, 32'hB000_0000);

	$display("Measure HIT for BLOCK A word 1");
	cpu_read(32'h0000_0004, 32'hA000_0001);

	$display("Evict block B from set 0 in column 1");
	cpu_read(32'h0000_0040, 32'hC000_0000);

	$display("Check if LRU worked!!!");
	cpu_read(32'h0000_0000, 32'hA000_0000);

	$display("Check if BLOCK B was removed from cache");
	cpu_read(32'h0000_0024, 32'hB000_0001);
	
        $display("Write Hit (Making block A dirty)");
        cpu_write(32'h0000_0000, 32'hDEAD_BEEF);

        $display("Reading back dirty block to verify Write Hit");
        cpu_read(32'h0000_0000, 32'hDEAD_BEEF);

        $display("Reading BLOCK B to make LRU column 0");
        cpu_read(32'h0000_0024, 32'hB000_0001);

	$display("READ MISS set 0 with dirty bit set for the block to be evicted");
        cpu_read(32'h0000_0040, 32'hC000_0000);

        $display("Verifying Write-Back Memory Content:");
        if (main_memory.mem[0] === 32'hDEAD_BEEF)	$display("SUCCESS: evicted dirty data reached memory!");
	else begin
            $error("FAILED: dirty data not in memory. Got 0x%0h", main_memory.mem[0]);
    	    error_count += 1;
    	end

	$display("Write miss for set 0 word 0");
        cpu_write(32'h0000_0080, 32'hCAFE_F00D);

        $display("Verifying no-write allocate updated main memory directly:");
        if (main_memory.mem[32'h0000_0080 >> 2] === 32'hCAFE_F00D)	$display("SUCCESS: write miss bypassed cache and updated memory");
	else begin
            $error("FAILED: data did not reach main memory! Got 0x%0h", main_memory.mem[32'h0000_0080 >> 2]);
	    error_count += 1;
	end
        $display("Reading back to ensure data is correct (Should trigger a Read Miss)");
        cpu_read(32'h0000_0080, 32'hCAFE_F00D);

	if(error_count == 0) $display("@@@PASS");
	else		     $display("@@@FAIL: %0d error count", error_count);
        $finish;
    end

    endmodule
