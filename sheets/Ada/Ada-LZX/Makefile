# Makefile for LZX Algorithm tests

.PHONY: all test clean

GNAT = gnatmake
OBJ_DIR = obj
BIN_DIR = bin

all: $(BIN_DIR)/tests

$(BIN_DIR)/tests: tests.adb lzx_algorithm.ads lzx_algorithm.adb
	mkdir -p $(OBJ_DIR) $(BIN_DIR)
	gprbuild -P lzx.gpr -p

test: $(BIN_DIR)/tests
	@echo "Running Verification and Validation tests..."
	@./$(BIN_DIR)/tests

clean:
	rm -rf $(OBJ_DIR) $(BIN_DIR)
