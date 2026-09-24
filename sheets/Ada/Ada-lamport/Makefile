# Makefile for Ada Lamport Bakery Algorithm

.PHONY: all clean test run build build-tests run-tests

# Default target
all: build

# Build the main bakery program
build:
	mkdir -p obj bin
	gnatmake -P bakery.gpr

# Build and run tests
test: build-tests run-tests

build-tests:
	mkdir -p obj bin
	gnatmake -P bakery_tests.gpr

run-tests: build-tests
	./bin/bakery_tests

# Run the main program
run: build
	./bin/bakery

# Clean build artifacts (but keep .gitkeep files)
clean:
	find obj -type f ! -name '.gitkeep' -delete
	find bin -type f ! -name '.gitkeep' -delete

# Rebuild everything
rebuild: clean all
