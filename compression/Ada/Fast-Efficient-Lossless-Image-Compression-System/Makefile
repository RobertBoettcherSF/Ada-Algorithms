.PHONY: all test clean build

OBJ_DIR = obj
BIN_DIR = bin

all: build

build:
	mkdir -p $(OBJ_DIR) $(BIN_DIR)
	gprbuild -Pfelics.gpr

test: build
	@echo "Running tests..."
	@./$(BIN_DIR)/tests

clean:
	rm -rf $(OBJ_DIR) $(BIN_DIR)
