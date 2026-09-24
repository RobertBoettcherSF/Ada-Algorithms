.PHONY: all test clean

GNAT = gnatmake
OBJ_DIR = obj
BIN_DIR = bin

all: $(BIN_DIR)/tests

$(BIN_DIR)/tests: tests.adb range_encoding.adb range_encoding.ads
	mkdir -p $(OBJ_DIR) $(BIN_DIR)
	$(GNAT) -P range_project.gpr

test: $(BIN_DIR)/tests
	@echo "Running Verification and Validation tests..."
	@./$(BIN_DIR)/tests

clean:
	rm -rf $(OBJ_DIR)/* $(BIN_DIR)/*
