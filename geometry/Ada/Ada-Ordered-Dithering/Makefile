.PHONY: all test clean

GNAT = gnatmake
OBJ_DIR = obj
BIN_DIR = bin

all: $(BIN_DIR)/tests

$(BIN_DIR)/tests: tests.adb ordered_dithering.adb ordered_dithering.ads
	mkdir -p $(OBJ_DIR) $(BIN_DIR)
	# Using -D to place artifacts into OBJ_DIR while keeping everything in root
	$(GNAT) -D $(OBJ_DIR) -o $(BIN_DIR)/tests tests.adb

test: $(BIN_DIR)/tests
	@echo "Running tests..."
	@./$(BIN_DIR)/tests

clean:
	rm -rf $(OBJ_DIR)/* $(BIN_DIR)/*
