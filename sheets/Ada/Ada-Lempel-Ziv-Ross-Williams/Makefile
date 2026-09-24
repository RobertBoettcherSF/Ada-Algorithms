.PHONY: all test clean

GNAT = gnatmake
OBJ_DIR = obj
BIN_DIR = bin

all:
	mkdir -p $(OBJ_DIR)
	mkdir -p $(BIN_DIR)
	$(GNAT) -P lzrw.gpr

test: all
	@echo "Running tests..."
	@./$(BIN_DIR)/tests

clean:
	rm -rf $(OBJ_DIR) $(BIN_DIR)
