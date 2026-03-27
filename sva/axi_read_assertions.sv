module axi_read_assertions #(
	parameter ADDR_WIDTH = 32,
	parameter DATA_WIDTH = 32,
	parameter RESP_WIDTH = 4
)(
	input   logic				CLK, ARESETn,
	input	logic                           ARVALID,
	input	logic                           ARREADY,
	input	logic [ADDR_WIDTH-1:0]          ARADDR,
	input	logic [7:0]                     ARLEN,
	input	logic [2:0]                     ARSIZE,
	input	logic [1:0]                     ARBURST,
	
	input	logic                           RVALID,
	input	logic                           RREADY,
	input	logic [DATA_WIDTH-1:0]          RDATA,
	input	logic [RESP_WIDTH-1:0]          RRESP,
	input	logic                           RLAST
					
);

default clocking cb @(posedge CLK); endclocking
default disable iff (!ARESETn);

property arvalid_reset;
	$rose(ARESETn) |-> !ARVALID;
endproperty

property rvalid_reset;
	$rose(ARESETn) |-> !RVALID; 
endproperty

property arvalid_stable;
	ARVALID && !ARREADY |=> ARVALID;
endproperty

property rvalid_stable;
	RVALID && !RREADY |=> RVALID;
endproperty

ARVALID_S : assert property (arvalid_stable)
	else $error("ARVALID de-asserted before ARREADY");

RVALID_S : assert property (rvalid_stable)
	else $error("RVALID de-asserted before RREADY");

ARVALID_R: assert property (arvalid_reset)
	else $error("ARVALID not low on the first cycle after reset");

RVALID_R: assert property (rvalid_reset)
	else $error("RVALID not low on the first cyclel after reset");
	
endmodule

