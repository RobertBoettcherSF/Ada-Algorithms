# Build and run the test suite: make test (GNAT 12 or later; the compiler is the gnatmake on PATH).
.PHONY: all test clean FORCE

GNAT = gnatmake
FLAGS = -gnat2022 -gnata
OBJ_DIR = obj
BIN_DIR = bin

all: $(BIN_DIR)/tests $(BIN_DIR)/main

$(BIN_DIR)/tests: FORCE
	mkdir -p $(OBJ_DIR) $(BIN_DIR)
	$(GNAT) $(FLAGS) -D $(OBJ_DIR) -o $(BIN_DIR)/tests tests.adb

$(BIN_DIR)/main: FORCE
	mkdir -p $(OBJ_DIR) $(BIN_DIR)
	$(GNAT) $(FLAGS) -D $(OBJ_DIR) -o $(BIN_DIR)/main main.adb

test: $(BIN_DIR)/tests
	./$(BIN_DIR)/tests

clean:
	rm -rf $(OBJ_DIR) $(BIN_DIR)
