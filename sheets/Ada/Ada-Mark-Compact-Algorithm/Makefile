.PHONY: all test clean

GNAT = gnatmake
OBJ_DIR = obj
BIN_DIR = bin

all: $(BIN_DIR)/main $(BIN_DIR)/tests

$(BIN_DIR)/main: src/main.adb src/mark_compact.ads src/mark_compact.adb
	mkdir -p $(OBJ_DIR) $(BIN_DIR)
	$(GNAT) -D $(OBJ_DIR) -Isrc -o $(BIN_DIR)/main src/main.adb

$(BIN_DIR)/tests: tests.adb src/mark_compact.ads src/mark_compact.adb
	mkdir -p $(OBJ_DIR) $(BIN_DIR)
	$(GNAT) -D $(OBJ_DIR) -Isrc -o $(BIN_DIR)/tests tests.adb

test: $(BIN_DIR)/tests
	@echo "Running Verification and Validation tests..."
	@$(BIN_DIR)/tests

clean:
	rm -rf $(OBJ_DIR)/* $(BIN_DIR)/*
