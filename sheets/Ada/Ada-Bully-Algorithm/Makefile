.PHONY: all test clean

GNAT = gnatmake
PROJECT_FILE = bully.gpr
BIN_DIR = bin

all:
	mkdir -p obj bin
	$(GNAT) -P $(PROJECT_FILE)

test: all
	@echo "Running tests..."
	@./$(BIN_DIR)/tests

clean:
	rm -rf obj/* bin/*
