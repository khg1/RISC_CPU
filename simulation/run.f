
     -64
     -sv
     -access +rwc
     #-gui
     -timescale 1ns/1ps
     +incdir+../rtl
     -y ../rtl
     +libext+.sv
     +PROG=../tb/program_fib.hex
     +DATA=../tb/data_fib.hex
     +GOLDREG=../tb/gold_rf_fib.hex
     +GOLDMEM=../tb/gold_data_fib.hex
     ../tb/tb_top.sv
     ../sva/axi_read_assertions.sv
     -assert


