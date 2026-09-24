# Makefile for Chase algorithm implementation

.PHONY: all test clean

# Compiler
GNAT = gnatmake

# Directories
OBJ_DIR = obj
BIN_DIR = bin

all: $(BIN_DIR)/tests

# Create directories
$(OBJ_DIR):
	mkdir -p $(OBJ_DIR)

$(BIN_DIR):
	mkdir -p $(BIN_DIR)

# Build the test executable
$(BIN_DIR)/tests: chase.ads chase.adb tests.adb $(OBJ_DIR) $(BIN_DIR)
	$(GNAT) -o $(BIN_DIR)/tests tests.adb -g

# Run tests
test: $(BIN_DIR)/tests
	@echo "Running Chase algorithm tests..."
	@$(BIN_DIR)/tests

# Clean
clean:
	rm -rf $(OBJ_DIR)/* $(BIN_DIR)/*
