.PHONY: all test clean

GNAT = gnatmake
OBJ_DIR = obj
BIN_DIR = bin

all: $(BIN_DIR)/main $(BIN_DIR)/tests

$(BIN_DIR)/main: main.adb fast_cosine_transform.ads fast_cosine_transform.adb
	mkdir -p $(OBJ_DIR) $(BIN_DIR) && $(GNAT) -P fct.gpr -m

$(BIN_DIR)/tests: tests.adb fast_cosine_transform.ads fast_cosine_transform.adb
	mkdir -p $(OBJ_DIR) $(BIN_DIR) && $(GNAT) -P fct.gpr -m

test: $(BIN_DIR)/tests
	@echo "Running tests..."
	@./$(BIN_DIR)/tests

clean:
	rm -rf $(OBJ_DIR) $(BIN_DIR)
