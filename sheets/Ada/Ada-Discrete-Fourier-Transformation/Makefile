# Makefile
.PHONY: all test clean

GNAT = gnatmake
OBJ_DIR = obj
BIN_DIR = bin

all: $(BIN_DIR)/tests

$(BIN_DIR)/tests: tests.adb discrete_fourier_transformation.ads discrete_fourier_transformation.adb
	mkdir -p $(OBJ_DIR) $(BIN_DIR)
	$(GNAT) -P dft.gpr -p

test: $(BIN_DIR)/tests
	@echo "======================================"
	@echo "Running Verification & Validation Tests"
	@echo "======================================"
	@./$(BIN_DIR)/tests

clean:
	rm -rf $(OBJ_DIR) $(BIN_DIR)
