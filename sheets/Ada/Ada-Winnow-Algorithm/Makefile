# Makefile
.PHONY: all test clean

all: bin/tests

bin/tests: tests.adb winnow.adb winnow.ads winnow_proj.gpr
	mkdir -p obj bin
	gnatmake -P winnow_proj.gpr

test: bin/tests
	@echo "Running tests..."
	@./bin/tests

clean:
	rm -rf obj bin
