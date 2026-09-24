.PHONY: all test clean

GNAT = gnatmake
OBJ_DIR = obj
BIN_DIR = bin

all: $(BIN_DIR)/main $(BIN_DIR)/tests

$(OBJ_DIR) $(BIN_DIR):
	mkdir -p $@

$(BIN_DIR)/main: src/main.adb | $(OBJ_DIR) $(BIN_DIR)
	$(GNAT) -P cheneys.gpr src/main.adb

$(BIN_DIR)/tests: src/tests.adb | $(OBJ_DIR) $(BIN_DIR)
	$(GNAT) -P cheneys.gpr src/tests.adb

test: $(BIN_DIR)/tests
	@echo "Running tests..."
	@$(BIN_DIR)/tests

clean:
	rm -rf $(OBJ_DIR)/* $(BIN_DIR)/*
