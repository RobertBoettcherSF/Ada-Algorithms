.PHONY: all test clean

GNAT = gnatmake
GPRBUILD = gprbuild
PROJECT = median.gpr
BIN_DIR = bin
OBJ_DIR = obj

all:
	mkdir -p $(OBJ_DIR) $(BIN_DIR)
	$(GPRBUILD) -P $(PROJECT)

test: all
	@echo "Running tests..."
	@./$(BIN_DIR)/tests

clean:
	rm -rf $(OBJ_DIR)/* $(BIN_DIR)/*
