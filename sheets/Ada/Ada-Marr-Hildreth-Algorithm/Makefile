.PHONY: all test clean

GNAT = gnatmake
OBJ_DIR = obj
BIN_DIR = bin

all: $(BIN_DIR)/main $(BIN_DIR)/tests

$(BIN_DIR)/main: main.adb marr_hildreth.adb marr_hildreth.ads
	mkdir -p $(OBJ_DIR) $(BIN_DIR)
	$(GNAT) -P marr_hildreth.gpr

$(BIN_DIR)/tests: tests.adb marr_hildreth.adb marr_hildreth.ads
	mkdir -p $(OBJ_DIR) $(BIN_DIR)
	$(GNAT) -P marr_hildreth.gpr

test: $(BIN_DIR)/tests
	@echo "Running Marr-Hildreth test suite..."
	@$(BIN_DIR)/tests

clean:
	rm -rf $(OBJ_DIR)/* $(BIN_DIR)/*
