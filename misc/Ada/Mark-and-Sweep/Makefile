# Makefile
.PHONY: all test clean

GNAT = gnatmake
GPRBUILD = gprbuild
OBJ_DIR = obj
BIN_DIR = bin

all: $(BIN_DIR)/tests

$(BIN_DIR)/tests: src/mark_and_sweep.ads src/mark_and_sweep.adb tests.adb
	mkdir -p $(OBJ_DIR) $(BIN_DIR)
	$(GPRBUILD) -P mark_sweep.gpr

test: $(BIN_DIR)/tests
	@echo "Running tests..."
	@./$(BIN_DIR)/tests

clean:
	rm -rf $(OBJ_DIR)/* $(BIN_DIR)/*
