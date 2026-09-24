.PHONY: all test clean

GNAT = gnatmake

all: tests

tests: tests.adb warnsdorff.adb warnsdorff.ads
	$(GNAT) -P warnsdorff.gpr

test: tests
	@echo "Running verification tests..."
	@./tests

clean:
	rm -f *.o *.ali tests tests.exe
