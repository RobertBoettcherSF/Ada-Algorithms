# Makefile
.PHONY: all test clean build

all: test

build:
	mkdir -p obj
	mkdir -p bin
	gnatmake -P fft_project.gpr

test: build
	@echo "Running Verification & Validation tests..."
	./bin/tests

clean:
	rm -rf obj
	rm -rf bin
