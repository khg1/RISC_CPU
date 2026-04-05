module tb_icache;
    logic                   clk;
    logic                   resetn;
    logic [31:0]  	    address;
    logic [31:0]	    data;
    logic                   stall_pipeline;
    logic [7:0]		    error_count;
    axi_if axi_bus ();

    instruction_cache DUT (
        .clk(clk),
        .resetn(resetn),
        .address(address),
        .data(data),
        .stall_pipeline(stall_pipeline),
        .axi_port(axi_bus.AXI_MASTER_READ)
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

    task cpu_read(input [31:0] target_addr, input [31:0] expected_data);
        $display("[%0t] CPU REQUEST: Read Address 0x%0h", $time, target_addr);
        
        @(posedge clk);
        address <= target_addr;
        
       	@(posedge clk); 
        
	while (stall_pipeline == 1) begin
            @(posedge clk);
        end
	
	if(data != expected_data) begin
		$error("[%0t] READ FAILED at 0x%0h: Expected 0x%0h, Got 0x%0h", $time, target_addr, expected_data, data);
		error_count += 1;
	end
	else begin
        	$display("[%0t] CPU SUCCESS: Read Address 0x%0h | Data = 0x%0h\n", $time, target_addr, data);
	end
    endtask

    initial begin
        main_memory.mem[32'h0000_0040 >> 2] = 32'hA1A1_A1A1; // Word 0
        main_memory.mem[32'h0000_0044 >> 2] = 32'hB2B2_B2B2; // Word 1
        main_memory.mem[32'h0000_0048 >> 2] = 32'hC3C3_C3C3; // Word 2
        main_memory.mem[32'h0000_004C >> 2] = 32'hD4D4_D4D4; // Word 3

        main_memory.mem[32'h0000_0050 >> 2] = 32'hE5E5_E5E5; // Word 0

        main_memory.mem[32'h0000_0080 >> 2] = 32'hFFFF_1111; // Word 0
    end
    
    initial begin
        error_count = 0;
	resetn  = 0;
        address = 0;
        repeat(3) @(posedge clk);
        resetn <= 1;
        repeat(2) @(posedge clk);
	
	$display("Read miss index 0");
        cpu_read(32'h0000_0040, 32'hA1A1_A1A1);

        $display("Read hit index 0 word 1");
        cpu_read(32'h0000_0044, 32'hB2B2_B2B2);

        $display("Read hit index 0 word 3");
        cpu_read(32'h0000_004C, 32'hD4D4_D4D4);

        $display("Read miss index 1 word 0");
        cpu_read(32'h0000_0050, 32'hE5E5_E5E5);

        $display("Evicting index 0");
        cpu_read(32'h0000_0080, 32'hFFFF_1111);

        $display("Read miss index 0 due to eviction");
        cpu_read(32'h0000_0040, 32'hA1A1_A1A1);
	
	if(error_count == 0)	$display("@@@PASS");
	else			$display("@@@FAIL: %0d error count", error_count);
        $finish;
    end

endmodule
