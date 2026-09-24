# Makefile for Ada ARC Cache
# Provides simple commands to build and test the ARC Cache implementation

.PHONY: all clean build test run help

# Compiler settings
GNATMAKE := gprbuild
GPRBUILD := gprbuild

# Project files
LIBRARY_PROJECT := arc_cache.gpr
TEST_PROJECT := test_arc_cache.gpr

# Directories
OBJ_DIR := obj
BIN_DIR := bin

# Default target
all: build test

# Build the ARC Cache library
build: $(OBJ_DIR) $(BIN_DIR)
	@echo "Building ARC Cache library..."
	$(GNATMAKE) -P $(LIBRARY_PROJECT)
	@echo "Library built successfully."

# Build the test suite
test: $(OBJ_DIR) $(BIN_DIR)
	@echo "Building test suite..."
	$(GNATMAKE) -P $(TEST_PROJECT)
	@echo "Test suite built successfully."

# Run the tests
run: test
	@echo "Running ARC Cache tests..."
	@echo "========================================"
	./$(BIN_DIR)/test_arc_cache
	@echo "========================================"

# Clean build artifacts
clean:
	@echo "Cleaning build artifacts..."
	-rm -rf $(OBJ_DIR)/*.o $(OBJ_DIR)/*.ali $(BIN_DIR)/test_arc_cache
	@echo "Cleaned up."

# Create required directories
$(OBJ_DIR):
	mkdir -p $(OBJ_DIR)

$(BIN_DIR):
	mkdir -p $(BIN_DIR)

# Help message
help:
	@echo "ARC Cache Makefile - Available targets:"
	@echo ""
	@echo "  make all       - Build library and tests, then run tests"
	@echo "  make build     - Build the ARC Cache library"
	@echo "  make test      - Build the test suite"
	@echo "  make run       - Build and run all tests"
	@echo "  make clean     - Clean build artifacts (keeps obj/ and bin/ dirs)"
	@echo "  make help      - Show this help message"
	@echo ""
	@echo "Quick start:"
	@echo "  1. make all    - Build everything and run tests"
	@echo "  2. make clean  - Clean up after testing"
