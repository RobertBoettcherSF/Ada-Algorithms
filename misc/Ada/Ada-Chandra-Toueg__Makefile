.PHONY: all test clean dirs

GNAT = gnatmake
OBJ_DIR = obj
BIN_DIR = bin

all: dirs $(BIN_DIR)/main $(BIN_DIR)/tests

dirs:
	mkdir -p $(OBJ_DIR) $(BIN_DIR)

$(BIN_DIR)/main: main.adb chandra_toueg.adb dirs
	$(GNAT) -o $(BIN_DIR)/main main.adb -D $(OBJ_DIR)

$(BIN_DIR)/tests: tests.adb chandra_toueg.adb dirs
	$(GNAT) -o $(BIN_DIR)/tests tests.adb -D $(OBJ_DIR)

test: $(BIN_DIR)/tests
	@echo "Running verification tests..."
	@./$(BIN_DIR)/tests

clean:
	rm -rf $(OBJ_DIR) $(BIN_DIR)
