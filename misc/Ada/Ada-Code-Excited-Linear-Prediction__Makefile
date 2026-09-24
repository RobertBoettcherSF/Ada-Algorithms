.PHONY: all test clean

GNAT = gnatmake

all: tests

tests: tests.adb celp.ads celp.adb
	$(GNAT) -P celp.gpr

test: tests
	@echo "\n=============================="
	@echo "Executing Verification Suite..."
	@echo "==============================\n"
	@./tests

clean:
	rm -f *.o *.ali tests *.bexch celp.gpr.ali
