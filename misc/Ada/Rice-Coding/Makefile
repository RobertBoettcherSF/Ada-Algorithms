.PHONY: all test clean

GNAT = gnatmake
OBJ_DIR = obj
BIN_DIR = bin

all: $(BIN_DIR)/main $(BIN_DIR)/tests

$(BIN_DIR)/main: main.adb rice_coding.adb
	mkdir -p $(OBJ_DIR) $(BIN_DIR)
	$(GNAT) -P rice.gpr main.adb

$(BIN_DIR)/tests: tests.adb rice_coding.adb
	mkdir -p $(OBJ_DIR) $(BIN_DIR)
	$(GNAT) -P rice.gpr tests.adb

test: $(BIN_DIR)/tests
	@echo "Running tests..."
	@./$(BIN_DIR)/tests

clean:
	rm -rf $(OBJ_DIR)/* $(BIN_DIR)/*
