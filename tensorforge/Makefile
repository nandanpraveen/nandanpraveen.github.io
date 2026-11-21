PYTHON ?= python3
CC ?= cc
YOSYS ?= yosys
GATE_SIM ?= verilator
ACCELERATOR_RTL := rtl/tf_pe.sv rtl/tf_array.sv rtl/tf_requant.sv rtl/tf_accelerator.sv
HARDWARE_DIR := build/hardware
HARDWARE_NETLIST := $(HARDWARE_DIR)/tensorforge-8x8.v

.DELETE_ON_ERROR:
.PHONY: test synth driver check hardware demo clean

test:
	$(PYTHON) software/run.py

synth:
	$(PYTHON) software/synthesize.py

driver:
	mkdir -p build
	$(CC) -std=c11 -Wall -Wextra -Werror -pedantic -Isoftware \
		software/tensorforge.c verification/test_driver.c -o build/test-driver
	build/test-driver

check: driver test synth

hardware: $(HARDWARE_NETLIST)
	$(PYTHON) software/verify_netlist.py --engine $(GATE_SIM)

$(HARDWARE_NETLIST): $(ACCELERATOR_RTL)
	mkdir -p $(HARDWARE_DIR)
	$(YOSYS) -Q -T -l $(HARDWARE_DIR)/synthesis.log -p 'read_verilog -sv $(ACCELERATOR_RTL); chparam -set SIZE 8 tf_accelerator; synth -flatten -top tf_accelerator; check -assert; tee -q -o $(HARDWARE_DIR)/cells.json stat -json; write_verilog -noattr $@' > $(HARDWARE_DIR)/synthesis-console.log 2>&1

demo:
	$(PYTHON) -m http.server 8000 --bind 127.0.0.1 --directory demo

clean:
	rm -rf build
