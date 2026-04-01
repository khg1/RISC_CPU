module top#(
	parameter int XPRLEN = 32,
	parameter int ADDR_WIDTH = 32,
	parameter int DATA_WIDTH = 32
)(
	input 				clk, resetn,
	axi_if.AXI_MASTER		axi_port,
        output  logic                   program_executed,
        output  logic [XPRLEN-1:0]      count_instruction, count_clk_cycle
);

logic [ADDR_WIDTH-1:0]  icache_address;
logic [DATA_WIDTH-1:0]  icache_data;
logic                   icache_stall;
logic                   dcache_memread;
logic                   dcache_memwrite;
logic [ADDR_WIDTH-1:0]  dcache_address;
logic [DATA_WIDTH-1:0]  dcache_wdata;
logic [DATA_WIDTH-1:0]  dcache_rdata;
logic                   dcache_stall;
logic                   done;
logic [XPRLEN-1:0]      count_inst, count_cycle;

axi_if icache_port();
axi_if dcache_port();

assign program_executed = done;
assign count_instruction = count_inst;
assign count_clk_cycle	= count_cycle;

core inst_core (.*);
instruction_cache inst_icache (
	.clk(clk),
	.resetn(resetn),
	.address(icache_address),
	.data(icache_data),
	.stall_pipeline(icache_stall),
	.axi_port(icache_port.AXI_MASTER_READ)
);
data_cache inst_dcache (
	.clk(clk),
	.resetn(resetn),
	.mem_read(dcache_memread),
	.mem_write(dcache_memwrite),
	.address(dcache_address),
	.data_in(dcache_wdata),
	.data_out(dcache_rdata),
	.stall_pipeline(dcache_stall),
	.axi_port(dcache_port.AXI_MASTER)
);
axi_arbiter inst_arbiter (
	.clk(clk),
	.resetn(resetn),
	.icache_axi(icache_port.AXI_SLAVE_READ),
	.dcache_axi(dcache_port.AXI_SLAVE),
	.mem_axi(axi_port)	
);
endmodule
