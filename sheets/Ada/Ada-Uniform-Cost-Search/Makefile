.PHONY: all test clean

GNAT = gnatmake
OBJ_DIR = obj
BIN_DIR = bin

all: $(BIN_DIR)/tests

$(BIN_DIR)/tests: tests.adb uniform_cost_search.ads uniform_cost_search.adb ucs.gpr
	mkdir -p $(OBJ_DIR) $(BIN_DIR)
	$(GNAT) -P ucs.gpr

test: $(BIN_DIR)/tests
	@echo "Running tests..."
	@./$(BIN_DIR)/tests

clean:
	rm -rf $(OBJ_DIR) $(BIN_DIR)
