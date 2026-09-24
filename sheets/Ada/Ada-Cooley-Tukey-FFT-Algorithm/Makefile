.PHONY: all test clean

GNAT = gnatmake
OBJ_DIR = obj
BIN_DIR = bin

all: $(BIN_DIR)/main $(BIN_DIR)/tests

$(BIN_DIR)/main: main.adb cooley_tukey.adb cooley_tukey.ads
	mkdir -p $(OBJ_DIR) $(BIN_DIR)
	$(GNAT) -o $(BIN_DIR)/main main.adb -D $(OBJ_DIR) -g -O2 -gnata

$(BIN_DIR)/tests: tests.adb cooley_tukey.adb cooley_tukey.ads
	mkdir -p $(OBJ_DIR) $(BIN_DIR)
	$(GNAT) -o $(BIN_DIR)/tests tests.adb -D $(OBJ_DIR) -g -O2 -gnata

test: $(BIN_DIR)/tests
	@echo "Running V&V tests..."
	@$(BIN_DIR)/tests

clean:
	rm -rf $(OBJ_DIR)/* $(BIN_DIR)/*
