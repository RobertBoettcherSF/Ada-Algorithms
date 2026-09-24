# Makefile for SRT Scheduling Algorithm Tests
# 
# This Makefile provides targets to compile and run the test suite
# for the SRT scheduling algorithm implementation.

.PHONY: all run clean shell_tests ada_tests

# Default target
all: shell_tests

# Run shell script tests (no Ada compiler required)
shell_tests:
	@echo "=========================================="
	@echo "  Running Shell Script Tests"
	@echo "=========================================="
	@chmod +x test_srt_algorithm.sh
	@./test_srt_algorithm.sh

# Run Ada tests (requires Ada compiler)
ada_tests:
	@echo "=========================================="
	@echo "  Compiling Ada Test Runner"
	@echo "=========================================="
	@gnatmake test_runner.adb -o test_runner || \
		(gprbuild -P ../srt_simulation.gpr test_runner.adb || \
		 (echo "Error: Ada compiler not found. Install gnat or gprbuild."; exit 1))
	@echo ""
	@echo "=========================================="
	@echo "  Running Ada Tests"
	@echo "=========================================="
	@./test_runner

# Run all tests
run: shell_tests ada_tests

# Clean up
clean:
	@rm -f test_runner test_runner.o test_runner.ali test_runner.bexch
	@rm -rf obj

# Show help
help:
	@echo "Available targets:"
	@echo "  all          - Run shell script tests (default)"
	@echo "  shell_tests  - Run shell script tests only"
	@echo "  ada_tests    - Compile and run Ada tests"
	@echo "  run          - Run all tests"
	@echo "  clean        - Clean up compiled files"
	@echo "  help         - Show this help message"
