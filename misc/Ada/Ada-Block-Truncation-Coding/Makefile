.PHONY: all test clean

GNAT = gnatmake
OBJ_DIR = obj
BIN_DIR = bin

all: $(BIN_DIR)/tests

$(BIN_DIR)/tests: tests.adb block_truncation_coding.adb block_truncation_coding.ads
	mkdir -p $(OBJ_DIR) $(BIN_DIR)
	$(GNAT) -P btc.gpr

test: $(BIN_DIR)/tests
	@echo "Running verification tests..."
	@./$(BIN_DIR)/tests

clean:
	rm -rf $(OBJ_DIR) $(BIN_DIR)
