.PHONY: all test clean

GNAT = gnatmake
OBJ_DIR = obj
BIN_DIR = bin
GPR_FILE = bwt.gpr

all: $(BIN_DIR)/main $(BIN_DIR)/tests

$(BIN_DIR)/main: main.adb bwt.ads bwt.adb
	mkdir -p $(OBJ_DIR) $(BIN_DIR)
	$(GNAT) -P $(GPR_FILE) main.adb

$(BIN_DIR)/tests: tests.adb bwt.ads bwt.adb
	mkdir -p $(OBJ_DIR) $(BIN_DIR)
	$(GNAT) -P $(GPR_FILE) tests.adb

test: $(BIN_DIR)/tests
	@echo "Running tests..."
	@$(BIN_DIR)/tests

clean:
	rm -rf $(OBJ_DIR) $(BIN_DIR)
