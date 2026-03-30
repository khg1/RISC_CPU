TB_DIR     ?= ../tb
TB_FILE    ?= tb_axi_mem.sv
TOP_MODULE ?= tb_axi_mem

XRUN_FLAGS = -64 -sv -f run.f $(TB_DIR)/$(TB_FILE) -top $(TOP_MODULE) \
	     -access +rwc -timescale 1ns/1ps

run:
	@echo "Running Target: $(TOP_MODULE)"
	xrun $(XRUN_FLAGS)

tb_core:
	$(MAKE) run TB_FILE=tb_core.sv TOP_MODULE=tb_core +PROG=../tb/program_fib.hex \
	       	+DATA=../tb/data_fib.hex +GOLDREG=../tb/gold_rf_fib.hex \
	       	+GOLDMEM=../tb/gold_data_fib.hex \
		../sva/axi_read_assertions.sv -assert
tb_axi_mem:
	$(MAKE) run

clean:
	rm -rf xrun.history xrun.log xcelium.d waves.shm xrun.key
