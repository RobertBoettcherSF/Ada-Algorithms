.PHONY: all test clean

GNAT = gnatmake

all: tests

tests: tests.adb vegas_algorithm.adb vegas_algorithm.ads
	$(GNAT) -P vegas.gpr

test: tests
	@echo "============================================="
	@echo "Running VEGAS Algorithm V&V Test Suite..."
	@echo "============================================="
	@./tests

clean:
	rm -f *.o *.ali tests b~tests.*
