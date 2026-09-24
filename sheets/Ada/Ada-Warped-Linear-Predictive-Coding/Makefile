.PHONY: all test clean

GNAT = gnatmake
OBJ_DIR = obj
BIN_DIR = bin

all: $(BIN_DIR)/main $(BIN_DIR)/tests

$(BIN_DIR)/main: main.adb warped_lpc.ads warped_lpc.adb
	mkdir -p $(OBJ_DIR) $(BIN_DIR)
	$(GNAT) -D $(OBJ_DIR) -o $(BIN_DIR)/main main.adb

$(BIN_DIR)/tests: tests.adb warped_lpc.ads warped_lpc.adb
	mkdir -p $(OBJ_DIR) $(BIN_DIR)
	$(GNAT) -D $(OBJ_DIR) -o $(BIN_DIR)/tests tests.adb

test: $(BIN_DIR)/tests
	@echo "Running Verification and Validation tests..."
	@./$(BIN_DIR)/tests

clean:
	rm -rf $(OBJ_DIR) $(BIN_DIR)
