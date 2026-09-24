.PHONY: all test clean

GNAT = gnatmake
PROJECT = growcut.gpr
OBJ_DIR = obj
BIN_DIR = bin

all:
	mkdir -p $(OBJ_DIR) $(BIN_DIR)
	$(GNAT) -P $(PROJECT)

test: all
	@echo "Running tests..."
	./bin/tests

clean:
	rm -rf $(OBJ_DIR)/* $(BIN_DIR)/*
