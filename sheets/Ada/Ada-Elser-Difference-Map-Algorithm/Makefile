# Makefile for Difference Map Ada Implementation
.PHONY: all test clean

GNAT = gnatmake
OBJ_DIR = obj
BIN_DIR = bin
GPR_FILE = diffmap.gpr

all:
	mkdir -p $(OBJ_DIR) $(BIN_DIR)
	gprbuild -P $(GPR_FILE)

$(BIN_DIR)/main: all

$(BIN_DIR)/tests: all

test: $(BIN_DIR)/tests
	@echo "Running verification tests..."
	@./$(BIN_DIR)/tests

clean:
	rm -rf $(OBJ_DIR) $(BIN_DIR)
