.PHONY: all test clean

GNAT = gnatmake
OBJ_DIR = obj
BIN_DIR = bin

all: $(BIN_DIR)/main $(BIN_DIR)/tests

$(BIN_DIR)/main: src/main.adb src/vector_clocks.adb src/vector_clocks.ads
	mkdir -p $(OBJ_DIR) $(BIN_DIR)
	$(GNAT) -Isrc -D $(OBJ_DIR) -o $(BIN_DIR)/main src/main.adb -gnata

$(BIN_DIR)/tests: tests.adb src/vector_clocks.adb src/vector_clocks.ads
	mkdir -p $(OBJ_DIR) $(BIN_DIR)
	$(GNAT) -Isrc -D $(OBJ_DIR) -o $(BIN_DIR)/tests tests.adb -gnata

test: $(BIN_DIR)/tests
	@echo "Running tests..."
	@$(BIN_DIR)/tests

clean:
	rm -rf $(OBJ_DIR)/* $(BIN_DIR)/*
