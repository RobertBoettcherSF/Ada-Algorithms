.PHONY: all test clean

all: bin/tests

bin/tests: *.ads *.adb *.gpr
	mkdir -p obj bin
	gnatmake -gnatwa -gnat2022 -Phamming.gpr

test: all
	@echo "Running tests..."
	@bin/tests

clean:
	rm -rf obj bin
