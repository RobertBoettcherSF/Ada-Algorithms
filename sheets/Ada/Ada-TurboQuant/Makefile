# Makefile
.PHONY: all test clean

GNAT = gnatmake

all: tests

tests: tests.adb turbo_quant.adb turbo_quant.ads
	$(GNAT) -P turboquant.gpr

test: tests
	@echo "Running tests..."
	@./tests

clean:
	rm -f *.o *.ali tests b~*
