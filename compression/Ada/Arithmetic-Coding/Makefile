.PHONY: all test clean

GNAT = gnatmake
OBJ_DIR = obj
BIN_DIR = bin

all: $(BIN_DIR)/tests

$(BIN_DIR)/tests: tests.adb arithmetic_coding.ads arithmetic_coding.adb
	mkdir -p $(OBJ_DIR) $(BIN_DIR)
	$(GNAT) -P arithmetic_coding.gpr

test: $(BIN_DIR)/tests
	@echo "Running Arithmetic Coding V&V tests..."
	@./$(BIN_DIR)/tests

clean:
	rm -rf $(OBJ_DIR)/* $(BIN_DIR)/*
