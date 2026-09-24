.PHONY: all test clean

GPRBUILD = gprbuild
OBJ_DIR = obj
BIN_DIR = bin

all: build

build:
	mkdir -p $(OBJ_DIR) $(BIN_DIR)
	$(GPRBUILD) -P entropy.gpr

test: build
	@echo "Running verification & validation tests..."
	@./$(BIN_DIR)/tests

clean:
	rm -rf $(OBJ_DIR) $(BIN_DIR)
