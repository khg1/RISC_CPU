interface risc_if #(
	parameter int ADDR_WIDTH = 32,
	parameter int DATA_WIDTH = 32,
	parameter int RESP_WIDTH = 4
)(
	input logic clk,
	input logic resetn
);

logic                           ARVALID;
logic                           ARREADY;
logic [ADDR_WIDTH-1:0]          ARADDR;
logic [7:0]                     ARLEN;
logic [2:0]                     ARSIZE;
logic [1:0]                     ARBURST;

logic                           RVALID;
logic                           RREADY;
logic [DATA_WIDTH-1:0]          RDATA;
logic [RESP_WIDTH-1:0]          RRESP;
logic                           RLAST;

modport cache_modport (
	input	clk,
	input	resetn,
	output	ARVALID,
	input	ARREADY,
	output	ARADDR,
	output	ARLEN,
	output	ARSIZE,
	output	ARBURST,
	
	input	RVALID,
	output	RREADY,
	input	RDATA,
	input	RRESP,
	input	RLAST	
);

modport sub_modport(
	input	clk,
	input	resetn,
	input	ARVALID,
	output	ARREADY,
	input	ARADDR,
	input	ARLEN,
	input	ARSIZE,
	input	ARBURST,

	output	RVALID,
	input	RREADY,
	output	RDATA,
	output	RRESP,
	output	RLAST
);

endinterface
