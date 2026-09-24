.PHONY: all test clean

GNAT = gnatmake
OBJ_DIR = obj
BIN_DIR = bin

all: $(BIN_DIR)/tests

$(BIN_DIR)/tests: tests.adb region_growing.adb region_growing.ads
	mkdir -p $(OBJ_DIR) $(BIN_DIR)
	$(GNAT) -P region_growing.gpr

test: $(BIN_DIR)/tests
	@echo "Running Verification and Validation tests..."
	@./$(BIN_DIR)/tests

clean:
	rm -rf $(OBJ_DIR) $(BIN_DIR)
