.PHONY: all test clean

GNAT = gnatmake
OBJ_DIR = obj
BIN_DIR = bin

all: $(BIN_DIR)/tests

$(BIN_DIR)/tests: tests.adb lzss.adb lzss.ads
	mkdir -p $(OBJ_DIR) $(BIN_DIR)
	$(GNAT) -P lzss.gpr

test: $(BIN_DIR)/tests
	@echo "Running verification tests..."
	@$(BIN_DIR)/tests

clean:
	rm -rf $(OBJ_DIR) $(BIN_DIR)
