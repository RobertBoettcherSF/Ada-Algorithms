.PHONY: all test clean build_main build_tests

GNAT = gnatmake
OBJ_DIR = obj
BIN_DIR = bin

all: build_main build_tests

build_main: $(BIN_DIR)/main

build_tests: $(BIN_DIR)/tests

$(BIN_DIR)/main: main.adb
	mkdir -p $(OBJ_DIR) $(BIN_DIR) && $(GNAT) -o $(BIN_DIR)/main main.adb -D $(OBJ_DIR)

$(BIN_DIR)/tests: tests.adb
	mkdir -p $(OBJ_DIR) $(BIN_DIR) && $(GNAT) -o $(BIN_DIR)/tests tests.adb -D $(OBJ_DIR)

test: $(BIN_DIR)/tests
	@echo "Running tests..."
	@./$(BIN_DIR)/tests

clean:
	rm -rf $(OBJ_DIR) $(BIN_DIR)
