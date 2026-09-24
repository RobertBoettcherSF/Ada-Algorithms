# Makefile
.PHONY: all test clean

GNAT = gnatmake
OBJ_DIR = obj
BIN_DIR = bin

all: $(BIN_DIR)/main $(BIN_DIR)/tests

$(BIN_DIR)/main: main.adb fortunes_algorithm.ads fortunes_algorithm.adb
	mkdir -p $(OBJ_DIR) $(BIN_DIR)
	$(GNAT) -P fortunes.gpr

$(BIN_DIR)/tests: tests.adb fortunes_algorithm.ads fortunes_algorithm.adb
	mkdir -p $(OBJ_DIR) $(BIN_DIR)
	$(GNAT) -P fortunes.gpr

test: $(BIN_DIR)/tests
	@echo "\n--- Running V&V Test Suite ---"
	@./$(BIN_DIR)/tests

clean:
	rm -rf $(OBJ_DIR) $(BIN_DIR)
