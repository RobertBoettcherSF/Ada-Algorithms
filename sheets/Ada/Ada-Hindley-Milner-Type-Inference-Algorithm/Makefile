.PHONY: all test clean

all: bin/tests

bin/tests: *.ads *.adb *.gpr
	mkdir -p obj bin
	gnatmake -gnatwa -gnat2022 -Phindley_milner.gpr

test: all
	@echo "Running tests..."
	@bin/tests

clean:
	rm -rf obj bin
