.PHONY: all test clean

GNAT = gnatmake

all: build

build:
	mkdir -p obj bin
	$(GNAT) -P qm.gpr

test: build
	@echo "Running verification and validation tests..."
	@./bin/tests

clean:
	rm -rf obj/* bin/*
