.PHONY: all test run clean

GNAT = gnatmake
FLAGS = -gnat2012 -O2 -gnatwa -gnata
OBJ_DIR = obj
BIN_DIR = bin

all: $(BIN_DIR)/main $(BIN_DIR)/tests

$(BIN_DIR)/main: main.adb lempel_ziv_oberhumer.ads lempel_ziv_oberhumer.adb
	mkdir -p $(OBJ_DIR) $(BIN_DIR)
	$(GNAT) $(FLAGS) -D $(OBJ_DIR) -o $(BIN_DIR)/main main.adb

$(BIN_DIR)/tests: tests.adb lempel_ziv_oberhumer.ads lempel_ziv_oberhumer.adb
	mkdir -p $(OBJ_DIR) $(BIN_DIR)
	$(GNAT) $(FLAGS) -D $(OBJ_DIR) -o $(BIN_DIR)/tests tests.adb

test: $(BIN_DIR)/tests
	@echo "Running test suite..."
	@$(BIN_DIR)/tests

run: $(BIN_DIR)/main
	@echo "Running main application..."
	@$(BIN_DIR)/main

clean:
	rm -rf $(OBJ_DIR) $(BIN_DIR)
