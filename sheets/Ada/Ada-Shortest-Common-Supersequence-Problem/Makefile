.PHONY: all test clean

GNAT = gnatmake
OBJ_DIR = obj
BIN_DIR = bin

all: $(BIN_DIR)/tests

$(BIN_DIR)/tests: tests.adb shortest_common_supersequence.adb shortest_common_supersequence.ads
	mkdir -p $(OBJ_DIR) $(BIN_DIR)
	# Build using GNAT Project file to ensure correct paths and flags
	$(GNAT) -p -P scs.gpr

test: $(BIN_DIR)/tests
	@echo "Running tests..."
	@./$(BIN_DIR)/tests

clean:
	rm -rf $(OBJ_DIR)/* $(BIN_DIR)/*
