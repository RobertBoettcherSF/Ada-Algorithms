.PHONY: all test clean

GNAT = gnatmake
OBJ_DIR = obj
BIN_DIR = bin

all: $(BIN_DIR)/tests

$(BIN_DIR)/tests: tests.adb audio_compression.ads audio_compression.adb
	mkdir -p $(OBJ_DIR) $(BIN_DIR)
	$(GNAT) -P audio.gpr

test: $(BIN_DIR)/tests
	@echo "Running verification and validation tests..."
	@./$(BIN_DIR)/tests

clean:
	rm -rf $(OBJ_DIR)/* $(BIN_DIR)/*
