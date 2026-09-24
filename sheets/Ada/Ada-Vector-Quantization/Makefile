.PHONY: all test clean

GNAT = gnatmake
GPR = gprbuild
OBJ_DIR = obj
BIN_DIR = bin

all: $(BIN_DIR)/tests

$(BIN_DIR)/tests: tests.adb vector_quantization.ads vector_quantization.adb
	mkdir -p $(OBJ_DIR) $(BIN_DIR)
	# Using GNAT with Project file handles root-dir specifications gracefully
	$(GNAT) -P vq.gpr

test: $(BIN_DIR)/tests
	@echo "Running tests..."
	@./$(BIN_DIR)/tests

clean:
	rm -rf $(OBJ_DIR)/* $(BIN_DIR)/*
