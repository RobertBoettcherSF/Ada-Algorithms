.PHONY: all test clean

GNAT = gnatmake
OBJ_DIR = obj
BIN_DIR = bin

all: $(BIN_DIR)/main $(BIN_DIR)/tests

# Directory creation targets
$(OBJ_DIR):
	mkdir -p $(OBJ_DIR)

$(BIN_DIR):
	mkdir -p $(BIN_DIR)

# Compilation targets with order-only prerequisites (|) for directories
$(BIN_DIR)/main: main.adb intersection_algorithm.adb | $(OBJ_DIR) $(BIN_DIR)
	$(GNAT) -D $(OBJ_DIR) -o $(BIN_DIR)/main main.adb

$(BIN_DIR)/tests: tests.adb intersection_algorithm.adb | $(OBJ_DIR) $(BIN_DIR)
	$(GNAT) -D $(OBJ_DIR) -o $(BIN_DIR)/tests tests.adb

# Test execution target
test: $(BIN_DIR)/tests
	@echo "Running tests..."
	@./$(BIN_DIR)/tests

clean:
	rm -rf $(OBJ_DIR) $(BIN_DIR)
