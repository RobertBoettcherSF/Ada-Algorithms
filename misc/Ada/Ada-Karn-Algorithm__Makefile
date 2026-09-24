.PHONY: all test clean

GNAT = gnatmake
OBJ_DIR = obj
BIN_DIR = bin

all: $(BIN_DIR)/karns_algorithm $(BIN_DIR)/tests

$(BIN_DIR)/karns_algorithm: karns_algorithm.ads karns_algorithm.adb
	mkdir -p $(OBJ_DIR) $(BIN_DIR)
	$(GNAT) -o $(BIN_DIR)/karns_algorithm karns_algorithm.adb

$(BIN_DIR)/tests: tests.adb karns_algorithm.ads karns_algorithm.adb
	mkdir -p $(OBJ_DIR) $(BIN_DIR)
	$(GNAT) -o $(BIN_DIR)/tests tests.adb

test: $(BIN_DIR)/tests
	@echo "Running tests..."
	@$(BIN_DIR)/tests

clean:
	rm -rf $(OBJ_DIR)/* $(BIN_DIR)/*
