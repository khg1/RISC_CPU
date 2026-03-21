
     -64
     -sv
     -access +rwc
     #-gui
     -timescale 1ns/1ps
     +incdir+../rtl
     -y ../rtl
     +libext+.sv
     +PROG=../tb/program_3.hex
     +DATA=../tb/data_3.hex
     +GOLDREG=../tb/gold_rf_3.hex
     +GOLDMEM=../tb/gold_data_3.hex
     ../tb/testbench.sv


