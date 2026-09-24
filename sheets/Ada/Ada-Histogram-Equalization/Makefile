.PHONY: all test clean

GNAT = gnatmake
PROJECT = hist_eq.gpr
BIN = bin/tests

all:
	mkdir -p obj bin
	$(GNAT) -P $(PROJECT)

test: all
	@echo "Running verification tests..."
	@./$(BIN)

clean:
	rm -rf obj/* bin/*
