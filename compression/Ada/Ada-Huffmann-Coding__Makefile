# Makefile
.PHONY: all test clean

GNAT = gnatmake
OBJ_DIR = obj
BIN_DIR = bin

all: $(BIN_DIR)/tests

# Compiles everything in the root directory while pushing artifacts to obj/ and bin/
$(BIN_DIR)/tests: tests.adb huffman_coding.adb huffman_coding.ads
	mkdir -p $(OBJ_DIR) $(BIN_DIR)
	$(GNAT) -P huffman.gpr
	# Fallback if gprbuild isn't available: 
	# $(GNAT) -D $(OBJ_DIR) -o $(BIN_DIR)/tests tests.adb -gnata

test: $(BIN_DIR)/tests
	@echo "Running tests..."
	@./$(BIN_DIR)/tests

clean:
	rm -rf $(OBJ_DIR) $(BIN_DIR)
