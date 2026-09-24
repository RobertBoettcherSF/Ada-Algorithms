.PHONY: all test clean

GNAT = gprbuild
OBJ_DIR = obj
BIN_DIR = bin

all: $(BIN_DIR)/tests

$(BIN_DIR)/tests: tests.adb berkeley_algorithm.ads berkeley_algorithm.adb berkeley.gpr
	$(GNAT) -P berkeley.gpr

test: $(BIN_DIR)/tests
	@echo "Running tests..."
	@./$(BIN_DIR)/tests

clean:
	rm -rf $(OBJ_DIR) $(BIN_DIR)
