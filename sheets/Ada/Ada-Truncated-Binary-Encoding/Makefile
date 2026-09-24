.PHONY: all test clean

all: build

build:
	mkdir -p obj bin
	gprbuild -P truncated_binary.gpr

test: build
	@echo "Running verification tests..."
	@./bin/tests

clean:
	rm -rf obj bin
