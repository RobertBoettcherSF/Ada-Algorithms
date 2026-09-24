.PHONY: all test clean

GNAT = gnatmake
OBJ_DIR = obj
BIN_DIR = bin

all: $(BIN_DIR)/tests

$(BIN_DIR)/tests: tests.adb sample_sort.adb sample_sort.ads
	mkdir -p $(OBJ_DIR) $(BIN_DIR)
	$(GNAT) -P sample_sort.gpr

test: $(BIN_DIR)/tests
	@echo "Running tests..."
	@$(BIN_DIR)/tests

clean:
	rm -rf $(OBJ_DIR)/* $(BIN_DIR)/*
