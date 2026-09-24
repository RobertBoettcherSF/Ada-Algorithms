# Makefile
.PHONY: all test clean

GNAT = gnatmake
OBJ_DIR = obj
BIN_DIR = bin

all: $(BIN_DIR)/tests

$(BIN_DIR)/tests: tests.adb tarski_kuratowski.adb tarski_kuratowski.ads
	@mkdir -p $(OBJ_DIR) $(BIN_DIR)
	$(GNAT) -P tarski_kuratowski.gpr -p

test: all
	@echo "Running Verification and Validation tests..."
	@./$(BIN_DIR)/tests

clean:
	rm -rf $(OBJ_DIR) $(BIN_DIR)
