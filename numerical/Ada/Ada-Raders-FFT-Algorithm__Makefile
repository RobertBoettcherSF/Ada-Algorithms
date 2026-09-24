.PHONY: all test clean

GNAT = gnatmake
OBJ_DIR = obj
BIN_DIR = bin

all:
	mkdir -p $(OBJ_DIR) $(BIN_DIR)
	$(GNAT) -P raders_fft.gpr

test: all
	@echo "Running verification and validation suite..."
	@./$(BIN_DIR)/tests

clean:
	rm -rf $(OBJ_DIR) $(BIN_DIR)
