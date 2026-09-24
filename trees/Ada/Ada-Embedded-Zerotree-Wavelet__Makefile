.PHONY: all test clean

GNAT = gnatmake
OBJ_DIR = obj
BIN_DIR = bin

all: $(BIN_DIR)/tests

$(BIN_DIR)/tests: tests.adb ezw.adb ezw.ads
	mkdir -p $(OBJ_DIR) $(BIN_DIR)
	$(GNAT) -P ezw.gpr

test: $(BIN_DIR)/tests
	@echo "Running verification & validation tests..."
	@./$(BIN_DIR)/tests

clean:
	rm -rf $(OBJ_DIR)/* $(BIN_DIR)/*
