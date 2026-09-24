.PHONY: all test clean

GNAT = gnatmake
OBJ_DIR = obj
BIN_DIR = bin

all: $(BIN_DIR)/tests

$(BIN_DIR)/tests: tests.adb run_length_encoding.adb run_length_encoding.ads rle.gpr
	mkdir -p $(OBJ_DIR) $(BIN_DIR) && $(GNAT) -P rle.gpr

test: $(BIN_DIR)/tests
	@echo "Running verification tests..."
	@./$(BIN_DIR)/tests

clean:
	rm -rf $(OBJ_DIR) $(BIN_DIR)
