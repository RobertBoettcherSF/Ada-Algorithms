GNAT = gnatmake
FLAGS = -gnatwa -gnat2022

.PHONY: all test clean

all: bin/tests

bin/tests: *.ads *.adb *.gpr
	mkdir -p obj bin
	$(GNAT) $(FLAGS) -Pterm_rewriting.gpr

test: all
	@echo "Running tests..."
	@bin/tests

clean:
	rm -rf obj bin
