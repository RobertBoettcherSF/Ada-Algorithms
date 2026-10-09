.PHONY: all test clean

GNAT = gnatmake

all: bin/tests

bin/tests: tests.adb warnsdorff.adb warnsdorff.ads warnsdorff.gpr
	mkdir -p obj bin
	$(GNAT) -P warnsdorff.gpr

test: bin/tests
	@echo "Running verification tests..."
	@bin/tests

clean:
	rm -rf obj bin
