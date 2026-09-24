.PHONY: all test clean

GNAT = gprbuild
PROJECT = damm.gpr
OBJ_DIR = obj
BIN_DIR = bin

all: $(BIN_DIR)/main $(BIN_DIR)/tests

$(BIN_DIR)/main $(BIN_DIR)/tests: main.adb tests.adb damm_algorithm.adb damm_algorithm.ads
	mkdir -p $(OBJ_DIR) $(BIN_DIR)
	$(GNAT) -P $(PROJECT)

test: all
	@echo "Running Verification and Validation tests..."
	@./$(BIN_DIR)/tests

clean:
	rm -rf $(OBJ_DIR)/* $(BIN_DIR)/*
