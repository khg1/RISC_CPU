interface axi_if #(
	parameter int ADDR_WIDTH = 32,
	parameter int DATA_WIDTH = 32,
	parameter int RESP_WIDTH = 2
)();

logic				AWVALID;
logic				AWREADY;	
logic [ADDR_WIDTH-1:0]		AWADDR;
logic [7:0]			AWLEN;
logic [2:0]			AWSIZE;
logic [1:0]			AWBURST;

logic				WVALID;
logic				WREADY;
logic [DATA_WIDTH-1:0]		WDATA;
logic				WLAST;
logic [(DATA_WIDTH>>3)-1:0]	WSTRB;

logic				BVALID;
logic				BREADY;
logic [RESP_WIDTH-1:0]		BRESP;

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

modport AXI_MASTER_READ(
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

modport AXI_SLAVE_READ(
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

modport AXI_MASTER(
	output	AWVALID,
	input	AWREADY,
	output	AWADDR,
	output	AWLEN,
	output	AWSIZE,
	output	AWBURST,

	output	WVALID,
	input	WREADY,
	output	WDATA,
	output	WLAST,
	output	WSTRB,

	input	BVALID,
	output	BREADY,
	input	BRESP,

	output  ARVALID,
        input   ARREADY,
        output  ARADDR,
        output  ARLEN,
        output  ARSIZE,
        output  ARBURST,

        input   RVALID,
        output  RREADY,
        input   RDATA,
        input   RRESP,
        input   RLAST	
	
);

modport AXI_SLAVE(
	input  AWVALID,
        output   AWREADY,
        input  AWADDR,
        input  AWLEN,
        input  AWSIZE,
        input  AWBURST, 

       	input  WVALID,
        output   WREADY,
        input  WDATA,
	input  WLAST,
        input  WSTRB,

        output   BVALID,
        input  BREADY,
        output   BRESP,

        input  ARVALID,
        output   ARREADY,
        input  ARADDR,
        input  ARLEN,
        input  ARSIZE,
        input  ARBURST,

        output   RVALID,
        input  RREADY,
        output   RDATA,
        output   RRESP,
        output   RLAST
	
);

endinterface
