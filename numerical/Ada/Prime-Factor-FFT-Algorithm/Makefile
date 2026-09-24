.PHONY: all test clean

all:
	mkdir -p obj bin
	gnatmake -P pfa.gpr

test: all
	@echo "Running tests..."
	@./bin/tests

clean:
	rm -rf obj bin
