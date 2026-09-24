# Makefile
.PHONY: all test clean dirs

GNAT = gnatmake
OBJ_DIR = obj
BIN_DIR = bin

all: dirs $(BIN_DIR)/main $(BIN_DIR)/tests

dirs:
	mkdir -p $(OBJ_DIR) $(BIN_DIR)

$(BIN_DIR)/main: main.adb parity_bit.adb | dirs
	$(GNAT) -D $(OBJ_DIR) -o $(BIN_DIR)/main main.adb

$(BIN_DIR)/tests: tests.adb parity_bit.adb | dirs
	$(GNAT) -D $(OBJ_DIR) -o $(BIN_DIR)/tests tests.adb

test: dirs $(BIN_DIR)/tests
	@echo "Running tests..."
	@./$(BIN_DIR)/tests

clean:
	rm -rf $(OBJ_DIR) $(BIN_DIR)
