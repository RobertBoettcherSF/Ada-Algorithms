.PHONY: all test clean

GNAT = gnatmake
OBJ_DIR = obj
BIN_DIR = bin
SRC_DIR = src
GPR_FILE = chandy_lamport.gpr

all: $(BIN_DIR)/main $(BIN_DIR)/tests

$(BIN_DIR)/main: $(SRC_DIR)/main.adb $(SRC_DIR)/chandy_lamport.adb
	mkdir -p $(OBJ_DIR) $(BIN_DIR)
	$(GNAT) -P $(GPR_FILE)

$(BIN_DIR)/tests: $(SRC_DIR)/tests.adb $(SRC_DIR)/chandy_lamport.adb
	mkdir -p $(OBJ_DIR) $(BIN_DIR)
	$(GNAT) -P $(GPR_FILE)

test: $(BIN_DIR)/tests
	@echo "Running tests..."
	@./$(BIN_DIR)/tests

clean:
	rm -rf $(OBJ_DIR)/* $(BIN_DIR)/*
