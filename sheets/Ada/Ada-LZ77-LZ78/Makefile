.PHONY: all test clean

GNAT = gnatmake
OBJ_DIR = obj
BIN_DIR = bin

all: $(BIN_DIR)/main $(BIN_DIR)/tests

$(BIN_DIR)/main: main.adb lz_compression.adb lz_compression.ads
	mkdir -p $(OBJ_DIR) $(BIN_DIR)
	$(GNAT) -P lz_compression.gpr -p

$(BIN_DIR)/tests: tests.adb lz_compression.adb lz_compression.ads
	mkdir -p $(OBJ_DIR) $(BIN_DIR)
	$(GNAT) -P lz_compression.gpr -p

test: $(BIN_DIR)/tests
	@echo "Running Verification and Validation tests..."
	@./$(BIN_DIR)/tests

clean:
	rm -rf $(OBJ_DIR) $(BIN_DIR)
