.PHONY: all test clean

GNAT = gnatmake
OBJ_DIR = obj
BIN_DIR = bin
PROJECT_FILE = garbage_collection.gpr

all: $(BIN_DIR)/main $(BIN_DIR)/tests

$(BIN_DIR)/main: src/main.adb
	mkdir -p $(OBJ_DIR) $(BIN_DIR)
	gprbuild -P $(PROJECT_FILE)

$(BIN_DIR)/tests: src/tests.adb
	mkdir -p $(OBJ_DIR) $(BIN_DIR)
	gprbuild -P $(PROJECT_FILE)

test: $(BIN_DIR)/tests
	@echo "Running V&V test suite..."
	@$(BIN_DIR)/tests

clean:
	rm -rf $(OBJ_DIR)/* $(BIN_DIR)/*
