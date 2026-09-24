# Makefile for Luleå Algorithm Ada Project
#
# Author: Vibe Code (Mistral AI)
# Date: 2025
#
# Description:
# This Makefile provides targets for compiling and running the Luleå Algorithm
# implementation and its test suite.
#
# Usage:
# - make all: Compile everything
# - make test: Compile and run tests
# - make clean: Remove object and executable files

.PHONY: all test clean

# Compiler
GNAT = gnatmake

# Directories
OBJ_DIR = obj
BIN_DIR = bin
SRC_DIR = .

# Compiler flags
GNAT_FLAGS = -gnatN -gnata -O2

# Main executable (if applicable)
MAIN_EXEC = $(BIN_DIR)/main

# Test executable
TEST_EXEC = $(BIN_DIR)/tests

# Source files
ADS_FILES = lulea_algorithm.ads
ADB_FILES = lulea_algorithm.adb tests.adb

# Object files
OBJ_FILES = $(patsubst %.adb,%.o,$(ADB_FILES))

# Default target
all: $(BIN_DIR)/lulea_algorithm $(TEST_EXEC)

# Compile the Luleå Algorithm library
$(BIN_DIR)/lulea_algorithm: lulea_algorithm.ads lulea_algorithm.adb
	mkdir -p $(OBJ_DIR) $(BIN_DIR)
	$(GNAT) $(GNAT_FLAGS) -o $(BIN_DIR)/lulea_algorithm lulea_algorithm.adb

# Compile the test executable
$(TEST_EXEC): tests.adb lulea_algorithm.ads lulea_algorithm.adb
	mkdir -p $(OBJ_DIR) $(BIN_DIR)
	$(GNAT) $(GNAT_FLAGS) -o $(TEST_EXEC) tests.adb

# Run tests
test: $(TEST_EXEC)
	@echo "Running Luleå Algorithm Test Suite..."
	@echo "========================================"
	@$(TEST_EXEC)

# Clean up
clean:
	rm -rf $(OBJ_DIR)/* $(BIN_DIR)/*

# Phony targets
.PHONY: all test clean
