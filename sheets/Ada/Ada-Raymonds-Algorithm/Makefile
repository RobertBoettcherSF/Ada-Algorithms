.PHONY: all test clean

GNAT = gnatmake
OBJ_DIR = obj
BIN_DIR = bin

all: $(BIN_DIR)/main $(BIN_DIR)/tests

$(BIN_DIR)/main: main.adb raymonds_algorithm.adb
	mkdir -p $(OBJ_DIR) $(BIN_DIR)
	$(GNAT) -gnata -D $(OBJ_DIR) -I. -o $(BIN_DIR)/main main.adb

$(BIN_DIR)/tests: tests.adb raymonds_algorithm.adb
	mkdir -p $(OBJ_DIR) $(BIN_DIR)
	$(GNAT) -gnata -D $(OBJ_DIR) -I. -o $(BIN_DIR)/tests tests.adb

test: $(BIN_DIR)/tests
	@echo "Running tests..."
	@$(BIN_DIR)/tests

clean:
	rm -rf $(OBJ_DIR)/* $(BIN_DIR)/*
