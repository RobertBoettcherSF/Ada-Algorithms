.PHONY: all test clean

GNAT = gnatmake
OBJ_DIR = obj
BIN_DIR = bin

all: $(BIN_DIR)/tests

$(BIN_DIR)/tests: tests.adb unicode_collation.adb unicode_collation.ads
	mkdir -p $(OBJ_DIR);
	mkdir -p $(BIN_DIR);
	$(GNAT) -P uca.gpr;

test: all
	@echo "Running tests..."
	@./$(BIN_DIR)/tests

clean:
	rm -rf $(OBJ_DIR)/* $(BIN_DIR)/*
