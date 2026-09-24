# ============================================================================
#  Makefile for Reference Counting Project
#  Compiles and runs the reference counting package and tests.
# ============================================================================

.PHONY: all test clean

# Compiler and directories
GNAT = gnatmake
OBJ_DIR = obj
BIN_DIR = bin

# Main targets
all: $(BIN_DIR)/tests

# Compile the tests executable
$(BIN_DIR)/tests: tests.adb reference_counting.ads reference_counting.adb
	mkdir -p $(OBJ_DIR) $(BIN_DIR)
	$(GNAT) -o $(BIN_DIR)/tests tests.adb

# Run tests
test: $(BIN_DIR)/tests
	@echo "Running tests..."
	@$(BIN_DIR)/tests

# Clean up
clean:
	rm -rf $(OBJ_DIR)/* $(BIN_DIR)/*
