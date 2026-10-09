.PHONY: all test clean

# Configured to run entirely from root directory
GNAT = gprbuild
OBJ_DIR = obj
BIN_DIR = bin

all: $(BIN_DIR)/main $(BIN_DIR)/tests $(BIN_DIR)/tests_golden $(BIN_DIR)/tests_reference

$(BIN_DIR)/main: main.adb dithering.adb dithering.ads
	mkdir -p $(OBJ_DIR) $(BIN_DIR)
	$(GNAT) -P dithering.gpr main.adb

$(BIN_DIR)/tests: tests.adb dithering.adb dithering.ads
	mkdir -p $(OBJ_DIR) $(BIN_DIR)
	$(GNAT) -P dithering.gpr tests.adb

$(BIN_DIR)/tests_golden: tests_golden.adb dithering.adb dithering.ads
	mkdir -p $(OBJ_DIR) $(BIN_DIR)
	$(GNAT) -P dithering.gpr tests_golden.adb

$(BIN_DIR)/tests_reference: tests_reference.adb dithering.adb dithering.ads
	mkdir -p $(OBJ_DIR) $(BIN_DIR)
	$(GNAT) -P dithering.gpr tests_reference.adb

test: $(BIN_DIR)/tests $(BIN_DIR)/tests_golden $(BIN_DIR)/tests_reference
	@echo "Running tests..."
	@./$(BIN_DIR)/tests
	@./$(BIN_DIR)/tests_golden
	@./$(BIN_DIR)/tests_reference

clean:
	rm -rf $(OBJ_DIR) $(BIN_DIR)
