`include "risc_pkg.sv"
module data_cache #(
	parameter int XPRLEN = 32,
        parameter int DEPTH = 500,
        parameter int ADDR_WIDTH = 32,
        parameter int DATA_WIDTH = 32,
        parameter int RRESP_WIDTH = 4

)(
	input	logic			clk, ARESETn,
	input	logic  	     		mem_read, mem_write,
	input	logic  	     		[XPRLEN-1:0] address,
	input	logic	signed  	[XPRLEN-1:0] data_in,
    	output	logic	signed  	[XPRLEN-1:0] data_out,
	output	logic				pipeline_stall,
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
logic	[XPRLEN-1:0]	dmem	[0:DEPTH-1];
logic	[XPRLEN-1:0]	valid	[0:DEPTH-1];
logic   [XPRLEN-1:0]	missed_address;
logic   [7:0]		burst_read_index;
logic   [RRESP_WIDTH-1:0] read_response;

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
        if(read_current_state == R_IDLE)        begin
                if((address[1:0] == 2'b00) && (valid[address>>2] == 1) && (mem_read)) begin
                        data_out = dmem[address>>2];
                        pipeline_stall = 0;
                end
		else if(mem_read)	pipeline_stall = 1;
		else			pipeline_stall = 0;
        end
        else pipeline_stall = 1;
end

always_ff @(posedge clk) begin
	if(mem_write) begin
		dmem[address>>2] = data_in;
		valid[address>>2] = 1;
	end
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
                missed_address  <= '0;
                for(int i=0; i<(DEPTH-1); i++)  begin
                        dmem[i] <= '0;
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
       		                        dmem[(missed_address[XPRLEN-1:2])+burst_read_index] <= signed'(RDATA);
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
       		                        //missed_address <= '0;
       		                        missed_address <= address;
       		                        ARVALID <= 1;
       		                        ARADDR  <= address;
					//ARADDR	<= '0;
       		                        //ARLEN   <= 8'h3F;       //63+1 transfers per transactions
       		                        ARLEN <= '0;
					ARSIZE  <= 3'h2;        // 4 bytes per transfer
       		                end
       		        end
       		endcase
	end
end

endmodule
