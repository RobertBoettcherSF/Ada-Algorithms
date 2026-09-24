.PHONY: all test clean

GNAT = gprbuild
OBJ_DIR = obj
BIN_DIR = bin

all: $(BIN_DIR)/main $(BIN_DIR)/tests

$(BIN_DIR)/main: main.adb push_relabel.adb push_relabel.ads
	mkdir -p $(OBJ_DIR) $(BIN_DIR)
	$(GNAT) -P push_relabel.gpr

$(BIN_DIR)/tests: tests.adb push_relabel.adb push_relabel.ads
	mkdir -p $(OBJ_DIR) $(BIN_DIR)
	$(GNAT) -P push_relabel.gpr

test: $(BIN_DIR)/tests
	@echo "Running Verification & Validation tests..."
	@./$(BIN_DIR)/tests

clean:
	rm -rf $(OBJ_DIR) $(BIN_DIR)
