.PHONY: all test clean

GNAT = gnatmake
OBJ_DIR = obj
BIN_DIR = bin

all: $(BIN_DIR)/main $(BIN_DIR)/tests

$(BIN_DIR)/main: main.adb redundancy_checks.adb redundancy_checks.ads
	mkdir -p $(OBJ_DIR) $(BIN_DIR)
	$(GNAT) -o $(BIN_DIR)/main main.adb -D $(OBJ_DIR)

$(BIN_DIR)/tests: tests.adb redundancy_checks.adb redundancy_checks.ads
	mkdir -p $(OBJ_DIR) $(BIN_DIR)
	$(GNAT) -o $(BIN_DIR)/tests tests.adb -D $(OBJ_DIR)

test: $(BIN_DIR)/tests
	@echo "Running verification and validation tests..."
	@$(BIN_DIR)/tests

clean:
	rm -rf $(OBJ_DIR) $(BIN_DIR)
