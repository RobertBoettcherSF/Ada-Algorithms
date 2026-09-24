.PHONY: all test clean

GNAT = gnatmake
OBJ_DIR = obj
BIN_DIR = bin

all: $(BIN_DIR)/tests

$(BIN_DIR)/tests: tests.adb dijkstra_scholten.adb dijkstra_scholten.ads
	mkdir -p $(OBJ_DIR) $(BIN_DIR)
	$(GNAT) tests.adb -D $(OBJ_DIR) -o $(BIN_DIR)/tests

test: $(BIN_DIR)/tests
	@echo "Running tests..."
	@./$(BIN_DIR)/tests

clean:
	rm -rf $(OBJ_DIR)/* $(BIN_DIR)/*
