#! /bin/bash

vlib work
if ! vlog design.sv fifo.sv keep_fifo.sv last_fifo.sv tb.sv
    then
        echo "COMPILATION ERROR"
        exit 1
    fi
vsim -voptargs=+acc work.testbench -do questa.tcl
 
