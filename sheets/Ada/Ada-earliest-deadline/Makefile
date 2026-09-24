# Makefile for Ada EDF Scheduling Project

.PHONY: all clean test run

# Default target
all: build

# Build the main project
build: obj bin
	gprbuild -P edf_scheduling.gpr

# Build and run tests
test: tests/edf_tests.adb tests/test_runner.gpr
	mkdir -p obj bin
	gprbuild -P tests/test_runner.gpr
	./bin/edf_tests

# Run the main simulation
run: build
	./bin/main

# Create necessary directories
obj bin:
	mkdir -p obj bin

# Clean build artifacts
clean:
	rm -rf obj bin

# Run tests with verbose output
test-verbose: tests/edf_tests.adb tests/test_runner.gpr
	mkdir -p obj bin
	gprbuild -P tests/test_runner.gpr -v
	./bin/edf_tests

# Show help
help:
	@echo "Available targets:"
	@echo "  all      - Build the main project (default)"
	@echo "  build    - Build the main project"
	@echo "  run      - Build and run the main simulation"
	@echo "  test     - Build and run all tests"
	@echo "  clean    - Remove build artifacts"
	@echo "  help     - Show this help message"
