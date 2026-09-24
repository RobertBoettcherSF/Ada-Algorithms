.PHONY: all test clean

GNAT = gnatmake
OBJ_DIR = obj
BIN_DIR = bin

all: $(BIN_DIR)/tests

$(BIN_DIR)/tests: tests.adb ziggurat.adb ziggurat.ads
	mkdir -p $(OBJ_DIR) && mkdir -p $(BIN_DIR) && $(GNAT) -P ziggurat.gpr

test: $(BIN_DIR)/tests
	@echo "Running Verification & Validation tests..."
	@./$(BIN_DIR)/tests

clean:
	rm -rf $(OBJ_DIR) $(BIN_DIR)
