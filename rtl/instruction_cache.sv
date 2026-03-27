`include "risc_pkg.sv"
module instruction_cache #(
	parameter int XPRLEN = 32,
	parameter int DEPTH = 500,
	parameter int ADDR_WIDTH = 32,
	parameter int DATA_WIDTH = 32,
	parameter int RRESP_WIDTH = 4 
)(
	input	logic			clk,
	input	logic	[XPRLEN-1:0]	address,
	output	logic	[XPRLEN-1:0]	instr,
	output	logic			pipeline_stall,
	
	input	logic				ARESETn,
	output  logic                           ARVALID,
        input   logic                           ARREADY,
        output  logic [ADDR_WIDTH-1:0]          ARADDR,
        output  logic [7:0]                     ARLEN,
        output  logic [2:0]                     ARSIZE,
        output  logic [1:0]                     ARBURST,

        input   logic                           RVALID,
        output  logic                           RREADY,
        input   logic [DATA_WIDTH-1:0]          RDATA,
        input   logic [RRESP_WIDTH-1:0]         RRESP,
        input   logic                           RLAST
);

import risc_pkg::*;

logic	[XPRLEN-1:0]	imem	[0:DEPTH-1];
logic			valid	[0:DEPTH-1];		
logic	[7:0]		burst_read_index;
logic   [RRESP_WIDTH-1:0] read_response;
logic	[XPRLEN-1:0]	missed_address;

read_state_t read_current_state, read_next_state;

always_ff @(posedge clk or negedge ARESETn) begin
        if(!ARESETn) begin
                read_current_state      <= R_IDLE;
        end
        else begin
                read_current_state      <= read_next_state;
	end
end

always_comb begin
	if(read_current_state == R_IDLE)	begin
		if((address[1:0] == 2'b00) && (valid[address>>2] == 1))	begin
			instr = imem[address>>2];
			pipeline_stall = 0;
		end
		else 	pipeline_stall = 1;
	end
	else	pipeline_stall = 1;
end

always_comb begin
        case (read_current_state)
                R_ADDR: read_next_state = (ARREADY & ARVALID)   ? R_DATA:R_ADDR;
                R_DATA: read_next_state = (RLAST)     ? R_IDLE:R_DATA;
                R_IDLE: read_next_state = pipeline_stall        ? R_ADDR:R_IDLE;
	endcase
end

always_ff @(posedge clk or negedge ARESETn) begin
	if(!ARESETn) begin
                ARVALID         <= 0;
                ARADDR          <= '0;
                ARLEN           <= '0;
                ARSIZE          <= '0;
                ARBURST         <= '0;
                RREADY          <= '0;
                burst_read_index <= '0;
		missed_address	<= '0;
		for(int i=0; i<(DEPTH-1); i++)	begin
			imem[i] <= '0;
			valid[i] <= 0;
		end
	end
	else begin
		case (read_current_state)
	        	R_ADDR: begin
	        	        if(ARREADY & ARVALID) begin
	        	                ARVALID <= 0;
	        	                RREADY  <= 1;
	        	        end
	        	end
	        	R_DATA: begin
	        	        if(RREADY & RVALID) begin
	        	                imem[(missed_address[XPRLEN-1:2])+burst_read_index] <= RDATA;
	        	                valid[(missed_address[XPRLEN-1:2])+burst_read_index] <= 1;
	        	                burst_read_index <= burst_read_index + 1;
	        	                read_response <= RRESP;
	        	                if(RLAST) begin
	        	                        RREADY <= 0;
	        	                        burst_read_index <= 0;
	        	                end
	        	        end
	        	end
	        	R_IDLE: begin
	        	        if(pipeline_stall) begin
					missed_address <= address;
	        	                ARVALID <= 1;
	        	                ARADDR  <= address;
	        	                ARLEN   <= 8'h0a;       //ARLEN+1 transfers per transactions
	        	                //ARLEN <= '0;
					ARSIZE  <= 3'h2;        // 4 bytes per transfer
	        	        end
	        	end
		endcase
	end
end


endmodule
