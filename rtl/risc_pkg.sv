package risc_pkg;
	typedef enum logic [6:0] {OP = 7'h33, OP_IMM = 7'h13, JAL = 7'h6F, BRANCH = 7'h63, LOAD = 7'h03, STORE = 7'h23, HALT = 7'h7F} instr_t;
	typedef enum logic [2:0] {ADD = 3'h0, SUB = 3'h1, AND = 3'h2, OR = 3'h3, XOR = 3'h4} operation_t;
endpackage
