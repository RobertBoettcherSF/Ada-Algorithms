.PHONY: all test clean

GNAT = gnatmake

all: tests

tests: tests.adb tomasulo_algorithm.ads tomasulo_algorithm.adb
	$(GNAT) -P tomasulo.gpr

test: tests
	@echo "Running tests..."
	@./tests

clean:
	rm -f *.o *.ali tests b~*
