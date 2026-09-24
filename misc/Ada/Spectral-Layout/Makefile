.PHONY: all test clean

GNAT = gnatmake

all:
	$(GNAT) -P spectral.gpr -p

test: all
	@echo "Running tests..."
	@./bin/tests

clean:
	rm -rf obj bin
