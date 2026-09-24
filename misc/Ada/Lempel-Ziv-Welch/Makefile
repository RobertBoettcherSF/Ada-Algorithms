.PHONY: all test clean

GPRBUILD = gprbuild
OBJ_DIR = obj
BIN_DIR = bin

all: $(BIN_DIR)/tests

$(BIN_DIR)/tests: tests.adb lzw.ads lzw.adb lzw_project.gpr
	mkdir -p $(OBJ_DIR) $(BIN_DIR)
	$(GPRBUILD) -P lzw_project.gpr

test: $(BIN_DIR)/tests
	@echo "Running tests..."
	@./$(BIN_DIR)/tests

clean:
	rm -rf $(OBJ_DIR)/* $(BIN_DIR)/*
