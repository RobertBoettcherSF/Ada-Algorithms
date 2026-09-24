.PHONY: all test clean

GPR_FILE = truncated_binary_exponential_backoff.gpr
GNAT = gnatmake
OBJ_DIR = obj
BIN_DIR = bin

all: $(BIN_DIR)/tests

$(BIN_DIR)/tests: tests.adb truncated_binary_exponential_backoff.ads truncated_binary_exponential_backoff.adb
	mkdir -p $(OBJ_DIR) $(BIN_DIR)
	$(GNAT) -c truncated_binary_exponential_backoff.adb
	$(GNAT) tests.adb -o $(BIN_DIR)/tests

test: $(BIN_DIR)/tests
	@echo "Running tests..."
	@$(BIN_DIR)/tests

clean:
	rm -rf $(OBJ_DIR)/* $(BIN_DIR)/*
