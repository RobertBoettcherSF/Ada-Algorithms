.PHONY: all test clean

GNAT = gnatmake
OBJ_DIR = obj
BIN_DIR = bin

all: $(BIN_DIR)/tests

$(BIN_DIR)/tests: tests.adb hamming_7_4.adb hamming_7_4.ads
	mkdir -p $(OBJ_DIR) $(BIN_DIR)
	$(GNAT) -P hamming.gpr

test: all
	@echo "Running verification tests..."
	@./$(BIN_DIR)/tests

clean:
	rm -rf $(OBJ_DIR) $(BIN_DIR)
