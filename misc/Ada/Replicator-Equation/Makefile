# Makefile for Replicator Equation 
# Ensures tests and project compile seamlessly from root directory.

.PHONY: all test clean

GNAT = gnatmake
OBJ_DIR = obj
BIN_DIR = bin

all: $(BIN_DIR)/tests

$(BIN_DIR)/tests: tests.adb replicator_equation.ads replicator_equation.adb
	mkdir -p $(OBJ_DIR) $(BIN_DIR)
	$(GNAT) -P replicator.gpr -p

test: $(BIN_DIR)/tests
	@echo "Running tests..."
	@./$(BIN_DIR)/tests

clean:
	rm -rf $(OBJ_DIR)/* $(BIN_DIR)/*
