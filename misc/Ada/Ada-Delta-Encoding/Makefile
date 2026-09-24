.PHONY: all test clean

GNAT = gnatmake

all: main tests

main: main.adb delta_encoding.ads delta_encoding.adb
	$(GNAT) -P project.gpr main.adb

tests: tests.adb delta_encoding.ads delta_encoding.adb
	$(GNAT) -P project.gpr tests.adb

test: tests
	@echo "Running tests..."
	@./tests

clean:
	rm -f main tests *.o *.ali
