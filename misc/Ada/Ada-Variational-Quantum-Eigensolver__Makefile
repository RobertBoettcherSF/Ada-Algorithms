# Makefile
.PHONY: all test clean

all: bin/tests

bin/tests: tests.adb vqe.ads vqe.adb
	@mkdir -p obj bin
	gprbuild -p -P vqe.gpr

test: bin/tests
	@echo "Running VQE tests..."
	@./bin/tests

clean:
	gprclean -P vqe.gpr || true
	rm -rf obj bin
