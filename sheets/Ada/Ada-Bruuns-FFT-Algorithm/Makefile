.PHONY: all test clean

GNAT = gnatmake
OBJ_DIR = obj
BIN_DIR = bin

all: $(BIN_DIR)/main $(BIN_DIR)/tests

$(BIN_DIR)/main: main.adb bruun_fft.ads bruun_fft.adb
	mkdir -p $(OBJ_DIR) $(BIN_DIR)
	$(GNAT) -o $(BIN_DIR)/main main.adb -D $(OBJ_DIR)

$(BIN_DIR)/tests: tests.adb bruun_fft.ads bruun_fft.adb
	mkdir -p $(OBJ_DIR) $(BIN_DIR)
	$(GNAT) -o $(BIN_DIR)/tests tests.adb -D $(OBJ_DIR)

test: $(BIN_DIR)/tests
	@echo "Running V&V test suite..."
	@./$(BIN_DIR)/tests

clean:
	rm -rf $(OBJ_DIR) $(BIN_DIR)
