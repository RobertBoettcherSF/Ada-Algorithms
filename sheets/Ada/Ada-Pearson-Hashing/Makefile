.PHONY: all test clean

GNAT = gnatmake
OBJ_DIR = obj
BIN_DIR = bin

all: $(BIN_DIR)/main $(BIN_DIR)/tests

$(BIN_DIR)/main: main.adb pearson_hash.adb pearson_hash.ads pearson.gpr
	mkdir -p $(OBJ_DIR) $(BIN_DIR)
	$(GNAT) -P pearson.gpr -m main.adb

$(BIN_DIR)/tests: tests.adb pearson_hash.adb pearson_hash.ads pearson.gpr
	mkdir -p $(OBJ_DIR) $(BIN_DIR)
	$(GNAT) -P pearson.gpr -m tests.adb

test: $(BIN_DIR)/tests
	@echo "Running tests..."
	@./bin/tests

clean:
	rm -rf $(OBJ_DIR)/* $(BIN_DIR)/*
