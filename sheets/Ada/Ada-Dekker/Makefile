# Simple Makefile for Dekker's Algorithm project
# Usage:
#   make        - Build everything
#   make run    - Build and run the demonstration
#   make test   - Build and run the tests
#   make clean  - Clean build artifacts

.PHONY: all run test clean

all: dekker dekker_tests

dekker: dekker.adb dekker.gpr
	mkdir -p obj
	gnatmake -P dekker.gpr

dekker_tests: tests/dekker_tests.adb tests/tests.gpr dekker.adb
	mkdir -p obj
	cd tests && gnatmake -P tests.gpr

run: dekker
	./obj/dekker

test: dekker_tests
	./obj/dekker_tests

clean:
	rm -rf obj tests/obj *.o *.ali *.bexch
	cd tests && rm -f *.o *.ali *.bexch
