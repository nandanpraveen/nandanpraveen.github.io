PYTHON ?= python3
CC ?= cc

.PHONY: test synth driver check demo clean

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

demo:
	$(PYTHON) -m http.server 8000 --bind 127.0.0.1 --directory demo

clean:
	rm -rf build
