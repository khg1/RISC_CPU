TB_DIR     ?= ../tb
TB_FILE    ?= tb_axi_mem.sv
TOP_MODULE ?= tb_axi_mem

reg_file   ?= ../tb/gold_rf_1.hex
mem_file   ?= ../tb/mem_1.hex

XRUN_FLAGS = -64 -sv -f run.f $(TB_DIR)/$(TB_FILE) -top $(TOP_MODULE) \
	     -access +rwc -timescale 1ns/1ps

run:
	@echo "Running Target: $(TOP_MODULE)"
	xrun -clean $(XRUN_FLAGS)

run_system:
	@echo "Running Target: $(TOP_MODULE)"
	xrun -clean $(XRUN_FLAGS) +MEM=$(mem_file) +GOLDREG=$(reg_file)

tb_top:
	$(MAKE) run_system TB_FILE=tb_top.sv TOP_MODULE=tb_top mem_file=../tb/mem_fib.hex \
	       	reg_file=../tb/gold_rf_fib.hex
tb_axi_mem:
	$(MAKE) run

tb_dcache:
	$(MAKE) run TB_FILE=tb_dcache.sv TOP_MODULE=tb_dcache

tb_icache:
	$(MAKE) run TB_FILE=tb_icache.sv TOP_MODULE=tb_icache

clean:
	rm -rf xrun.history xrun.log xcelium.d waves.shm xrun.key
