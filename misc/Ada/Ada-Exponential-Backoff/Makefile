# Makefile for Exponential Backoff Ada Project
#
# This Makefile compiles the Ada code and runs tests.
#
# Author: Vibe Code (Mistral AI)
# Date: 2025

.PHONY: all test clean

# Compiler and directories
GNAT = gnatmake
OBJ_DIR = obj
BIN_DIR = bin
SRC_DIR = .

# Source files
SRC_FILES = \
	exponential_backoff.ads \
	exponential_backoff.adb \
	tests.adb

# Executables
EXECUTABLES = \
	$(BIN_DIR)/tests

# Default target
all: $(EXECUTABLES)

# Compile tests
$(BIN_DIR)/tests: tests.adb exponential_backoff.ads exponential_backoff.adb
	mkdir -p $(OBJ_DIR) $(BIN_DIR)
	$(GNAT) -o $(BIN_DIR)/tests tests.adb

# Run tests
test: $(BIN_DIR)/tests
	@echo "Running tests..."
	@$(BIN_DIR)/tests

# Clean object and binary files
clean:
	rm -rf $(OBJ_DIR)/* $(BIN_DIR)/*

# Rebuild everything
rebuild: clean all
