# Makefile
.PHONY: all test clean

GNAT = gnatmake
OBJ_DIR = obj
BIN_DIR = bin

all: $(BIN_DIR)/tests

# Target handles compiling the suite and routing binaries to /bin and /obj
$(BIN_DIR)/tests: tests.adb hamming_weight.adb hamming_weight.ads
	mkdir -p $(OBJ_DIR) $(BIN_DIR)
	$(GNAT) -P hamming.gpr

test: $(BIN_DIR)/tests
	@echo "Running V&V test suite..."
	@./$(BIN_DIR)/tests

clean:
	rm -rf $(OBJ_DIR) $(BIN_DIR)
