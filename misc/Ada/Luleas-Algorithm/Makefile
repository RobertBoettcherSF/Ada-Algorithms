.PHONY: all test clean

GNAT ?= gnatmake
FLAGS = -gnatwa -gnat2022 -gnata

all: test

test:
	mkdir -p obj bin
	gprbuild -p -Plulea_algorithm.gpr
	./bin/tests

clean:
	rm -rf obj bin
