.PHONY: all test clean

GNAT = gnatmake

all:
	mkdir -p obj bin
	$(GNAT) -P pow.gpr

test: all
	@echo "Running tests..."
	@./bin/tests

clean:
	rm -rf obj bin
