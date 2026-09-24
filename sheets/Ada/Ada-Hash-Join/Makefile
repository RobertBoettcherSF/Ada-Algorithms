.PHONY: all test clean

GNAT = gnatmake
OBJ_DIR = obj
BIN_DIR = bin

all: $(BIN_DIR)/tests

$(BIN_DIR)/tests: tests.adb hash_join.ads hash_join.adb
	mkdir -p $(OBJ_DIR)
	mkdir -p $(BIN_DIR)
	# Compile directly using gnatmake into the target bin/obj folders.
	# -gnata ensures that pragmas like Assert are executed.
	$(GNAT) -o $(BIN_DIR)/tests tests.adb -D $(OBJ_DIR) -gnata

test: $(BIN_DIR)/tests
	@echo "Running tests..."
	@./$(BIN_DIR)/tests

clean:
	rm -rf $(OBJ_DIR)/* $(BIN_DIR)/*
