.PHONY: all test clean

GNAT = gnatmake
OBJ_DIR = obj
BIN_DIR = bin

all: $(BIN_DIR)/main $(BIN_DIR)/tests

$(BIN_DIR)/main: main.adb entropy_encoding.adb entropy_encoding.ads
	mkdir -p $(OBJ_DIR) $(BIN_DIR)
	$(GNAT) -D $(OBJ_DIR) -o $(BIN_DIR)/main main.adb

$(BIN_DIR)/tests: tests.adb entropy_encoding.adb entropy_encoding.ads
	mkdir -p $(OBJ_DIR) $(BIN_DIR)
	$(GNAT) -D $(OBJ_DIR) -o $(BIN_DIR)/tests tests.adb

test: $(BIN_DIR)/tests
	@echo "Running Verification and Validation test suite..."
	@$(BIN_DIR)/tests

clean:
	rm -rf $(OBJ_DIR)/* $(BIN_DIR)/*
