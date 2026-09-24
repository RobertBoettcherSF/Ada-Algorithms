.PHONY: all test clean

GNAT = gnatmake
OBJ_DIR = obj
BIN_DIR = bin
SRC_DIR = src

all: $(BIN_DIR)/tests

$(BIN_DIR)/tests: tests.adb $(SRC_DIR)/lamport_ordering.ads $(SRC_DIR)/lamport_ordering.adb
	mkdir -p $(OBJ_DIR) $(BIN_DIR)
	$(GNAT) -I$(SRC_DIR) -D $(OBJ_DIR) -o $(BIN_DIR)/tests tests.adb

test: $(BIN_DIR)/tests
	@echo "Running V&V test suite..."
	@$(BIN_DIR)/tests

clean:
	rm -rf $(OBJ_DIR) $(BIN_DIR)
