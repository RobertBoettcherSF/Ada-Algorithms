.PHONY: all test clean

GNAT = gnatmake
OBJ_DIR = obj
BIN_DIR = bin

all: $(BIN_DIR)/tests

$(BIN_DIR)/tests: tests.adb cyclic_redundancy_check.adb cyclic_redundancy_check.ads
	mkdir -p $(OBJ_DIR) $(BIN_DIR)
	$(GNAT) -P crc.gpr

test: $(BIN_DIR)/tests
	@echo "Running tests..."
	@./$(BIN_DIR)/tests

clean:
	rm -rf $(OBJ_DIR)/* $(BIN_DIR)/*
