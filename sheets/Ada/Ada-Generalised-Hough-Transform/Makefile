.PHONY: all test clean

GNAT = gprbuild
OBJ_DIR = obj
BIN_DIR = bin

all: build

build:
	mkdir -p $(OBJ_DIR) $(BIN_DIR)
	$(GNAT) -P ght.gpr

test: build
	@echo "\nExecuting test suite..."
	@$(BIN_DIR)/tests

clean:
	rm -rf $(OBJ_DIR) $(BIN_DIR)
