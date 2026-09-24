.PHONY: all test clean

GNATMAKE = gnatmake
PROJECT = rl.gpr

all:
	$(GNATMAKE) -P $(PROJECT)

test: all
	@echo "Running verification tests..."
	@bin/tests

clean:
	rm -rf obj/* bin/*
