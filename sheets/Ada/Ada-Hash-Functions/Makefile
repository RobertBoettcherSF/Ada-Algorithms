.PHONY: all test clean

GNAT = gnatmake
OBJ_DIR = obj
BIN_DIR = bin

all:
	mkdir -p $(OBJ_DIR) $(BIN_DIR)
	$(GNAT) -P hash.gpr

test: all
	@echo "Running V&V test suite..."
	./bin/tests

clean:
	rm -rf $(OBJ_DIR)/* $(BIN_DIR)/*
