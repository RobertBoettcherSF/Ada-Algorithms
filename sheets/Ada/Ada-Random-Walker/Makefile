# Makefile
.PHONY: all test clean

GNAT = gnatmake
OBJ_DIR = obj
BIN_DIR = bin

all: $(BIN_DIR)/tests

$(BIN_DIR)/tests: tests.adb random_walker.adb random_walker.ads
	mkdir -p $(OBJ_DIR) $(BIN_DIR)
	gprbuild -P random_walker.gpr -p || $(GNAT) -P random_walker.gpr -p

test: $(BIN_DIR)/tests
	@echo "Running Random Walker tests..."
	@./$(BIN_DIR)/tests

clean:
	rm -rf $(OBJ_DIR) $(BIN_DIR)
