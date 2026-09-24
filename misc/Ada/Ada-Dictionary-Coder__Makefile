.PHONY: all test clean

GNAT = gnatmake
OBJ_DIR = obj
BIN_DIR = bin

all: $(BIN_DIR)/main $(BIN_DIR)/tests

$(BIN_DIR)/main: main.adb dictionary_coder.ads dictionary_coder.adb
	mkdir -p $(OBJ_DIR) $(BIN_DIR)
	$(GNAT) -P dictionary_coder.gpr -XBuild=Debug

$(BIN_DIR)/tests: tests.adb dictionary_coder.ads dictionary_coder.adb
	mkdir -p $(OBJ_DIR) $(BIN_DIR)
	$(GNAT) -P dictionary_coder.gpr -XBuild=Debug

test: $(BIN_DIR)/tests
	@echo "Running Verification and Validation tests..."
	@$(BIN_DIR)/tests

clean:
	rm -rf $(OBJ_DIR)/* $(BIN_DIR)/*
