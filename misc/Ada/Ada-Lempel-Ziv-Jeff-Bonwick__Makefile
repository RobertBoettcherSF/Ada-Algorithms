.PHONY: all test clean

GNAT = gnatmake
OBJ_DIR = obj
BIN_DIR = bin

all: $(BIN_DIR)/tests

$(BIN_DIR)/tests: tests.adb lzjb.adb lzjb.ads
	mkdir -p $(OBJ_DIR) $(BIN_DIR)
	$(GNAT) tests.adb -D $(OBJ_DIR) -o $(BIN_DIR)/tests

test: all
	@echo "Running tests..."
	@$(BIN_DIR)/tests

clean:
	rm -rf $(OBJ_DIR)/* $(BIN_DIR)/*
