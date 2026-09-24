.PHONY: all test clean

GNAT = gnatmake
OBJ_DIR = obj
BIN_DIR = bin

all: $(BIN_DIR)/main $(BIN_DIR)/tests

$(BIN_DIR)/main: main.adb semi_space_collector.ads semi_space_collector.adb
	mkdir -p $(OBJ_DIR) $(BIN_DIR)
	$(GNAT) -P semi_space.gpr main.adb

$(BIN_DIR)/tests: tests.adb semi_space_collector.ads semi_space_collector.adb
	mkdir -p $(OBJ_DIR) $(BIN_DIR)
	$(GNAT) -P semi_space.gpr tests.adb

test: $(BIN_DIR)/tests
	@echo "Running V&V test suite..."
	@./$(BIN_DIR)/tests

clean:
	rm -rf $(OBJ_DIR)/* $(BIN_DIR)/*
