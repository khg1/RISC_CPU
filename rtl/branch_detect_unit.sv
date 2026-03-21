`include "risc_pkg.sv"
module branch_detect_unit #(
    parameter int XPRLEN = 32
)(
    input logic [6:0] opcode,
    input logic [3:0] funct,
    input logic signed [XPRLEN-1:0] data1, data2,
    output logic branch_detected
);
import risc_pkg::*;
logic signed [XPRLEN-1:0] result;
assign result = data1 - data2;

always_comb begin
    case (instr_t'(opcode))
        JAL:    branch_detected = 1;
        BRANCH: begin
                    if((result == 0) && (funct[2:0] == '0))  branch_detected = 1;
                    else if((result != 0) && (funct[2:0] == 3'b001)) branch_detected = 1;
                    else                                            branch_detected = 0;
                end
        default: branch_detected = 0;
    endcase
end

endmodule
