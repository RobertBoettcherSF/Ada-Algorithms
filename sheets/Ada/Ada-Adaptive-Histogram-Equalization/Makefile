# Makefile
.PHONY: all test clean

GNAT = gnatmake
OBJ_DIR = obj
BIN_DIR = bin

all: $(BIN_DIR)/tests

$(BIN_DIR)/tests: tests.adb adaptive_histogram_equalization.ads adaptive_histogram_equalization.adb
	mkdir -p $(OBJ_DIR) $(BIN_DIR)
	$(GNAT) -P ahe.gpr

test: all
	@echo "Running verification tests..."
	@./$(BIN_DIR)/tests

clean:
	rm -rf $(OBJ_DIR)/* $(BIN_DIR)/*
