.PHONY: all test clean

# Use gnatmake but leverage the GNAT project file to ensure assertions are active
GNAT = gnatmake
OBJ_DIR = obj
BIN_DIR = bin

all: $(BIN_DIR)/tests

$(BIN_DIR)/tests: tests.adb cristians_algorithm.ads cristians_algorithm.adb cristians.gpr
	mkdir -p $(OBJ_DIR) $(BIN_DIR) && $(GNAT) -P cristians.gpr

test: $(BIN_DIR)/tests
	@echo "Running tests..."
	@./$(BIN_DIR)/tests

clean:
	rm -rf $(OBJ_DIR) $(BIN_DIR)
