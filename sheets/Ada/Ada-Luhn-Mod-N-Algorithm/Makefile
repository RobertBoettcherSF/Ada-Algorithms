.PHONY: all test clean

GNAT = gnatmake
OBJ_DIR = obj
BIN_DIR = bin

all: $(BIN_DIR)/main $(BIN_DIR)/tests

$(BIN_DIR)/main: main.adb luhn_mod_n.ads luhn_mod_n.adb
	mkdir -p $(OBJ_DIR) $(BIN_DIR)
	$(GNAT) -P luhn.gpr

$(BIN_DIR)/tests: tests.adb luhn_mod_n.ads luhn_mod_n.adb
	mkdir -p $(OBJ_DIR) $(BIN_DIR)
	$(GNAT) -P luhn.gpr

test: $(BIN_DIR)/tests
	@echo "Running tests..."
	@./$(BIN_DIR)/tests

clean:
	rm -rf $(OBJ_DIR)/* $(BIN_DIR)/*
