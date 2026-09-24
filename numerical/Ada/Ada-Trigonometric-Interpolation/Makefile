# Makefile
.PHONY: all test clean

GNAT = gnatmake
OBJ_DIR = obj
BIN_DIR = bin

all: $(BIN_DIR)/main $(BIN_DIR)/tests

$(BIN_DIR)/main: main.adb trigonometric_interpolation.ads trigonometric_interpolation.adb
	mkdir -p $(OBJ_DIR) $(BIN_DIR) && $(GNAT) -P trig_interp.gpr

$(BIN_DIR)/tests: tests.adb trigonometric_interpolation.ads trigonometric_interpolation.adb
	mkdir -p $(OBJ_DIR) $(BIN_DIR) && $(GNAT) -P trig_interp.gpr

test: $(BIN_DIR)/tests
	@echo "Running V&V Tests..."
	@./$(BIN_DIR)/tests

clean:
	rm -rf $(OBJ_DIR) $(BIN_DIR)
