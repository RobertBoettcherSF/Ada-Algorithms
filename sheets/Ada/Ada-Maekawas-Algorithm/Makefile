# Makefile (fixed)
.PHONY: all test clean

GNAT = gnatmake
OBJ_DIR = obj
BIN_DIR = bin

all: $(BIN_DIR)/main $(BIN_DIR)/tests

$(BIN_DIR)/main: main.adb maekawa.ads maekawa.adb
	mkdir -p $(OBJ_DIR) $(BIN_DIR)
	$(GNAT) -P maekawa.gpr main.adb

$(BIN_DIR)/tests: tests.adb maekawa.ads maekawa.adb
	mkdir -p $(OBJ_DIR) $(BIN_DIR)
	$(GNAT) -P maekawa.gpr tests.adb

test: $(BIN_DIR)/tests
	@echo "==============================="
	@echo "Running V&V Test Suite..."
	@echo "==============================="
	@./$(BIN_DIR)/tests

clean:
	rm -rf $(OBJ_DIR)/* $(BIN_DIR)/*
