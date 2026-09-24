.PHONY: all test clean

GNAT = gnatmake
OBJ_DIR = obj
BIN_DIR = bin

all: $(BIN_DIR)/tests

$(BIN_DIR)/tests: tests.adb blind_deconvolution.adb blind_deconvolution.ads
	mkdir -p $(OBJ_DIR) $(BIN_DIR)
	$(GNAT) -P blind_deconvolution.gpr

test: all
	@echo "Running verification tests..."
	@./$(BIN_DIR)/tests

clean:
	rm -rf $(OBJ_DIR) $(BIN_DIR)
