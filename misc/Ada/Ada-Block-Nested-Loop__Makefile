.PHONY: all test clean

GNAT = gprbuild
OBJ_DIR = obj
BIN_DIR = bin

all: $(BIN_DIR)/tests

$(BIN_DIR)/tests: tests.adb block_nested_loop.adb block_nested_loop.ads bnl.gpr
	mkdir -p $(OBJ_DIR)
	mkdir -p $(BIN_DIR)
	$(GNAT) bnl.gpr

test: $(BIN_DIR)/tests
	@echo "Running tests..."
	@./$(BIN_DIR)/tests

clean:
	rm -rf $(OBJ_DIR)/* $(BIN_DIR)/*
