.PHONY: all test clean

GNAT = gnatmake
OBJ_DIR = obj
BIN_DIR = bin

all: main tests

main: main.adb sieve_of_sundaram.ads sieve_of_sundaram.adb
	mkdir -p $(OBJ_DIR) $(BIN_DIR)
	$(GNAT) -P sundaram.gpr main.adb

tests: tests.adb sieve_of_sundaram.ads sieve_of_sundaram.adb
	mkdir -p $(OBJ_DIR) $(BIN_DIR)
	$(GNAT) -P sundaram.gpr tests.adb

test: tests
	@echo "Running tests..."
	@./$(BIN_DIR)/tests

clean:
	rm -rf $(OBJ_DIR) $(BIN_DIR)
