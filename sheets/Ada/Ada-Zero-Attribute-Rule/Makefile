GNAT = gnatmake
FLAGS = -gnatwa -gnat2022
OBJ_DIR = obj
BIN_DIR = bin

.PHONY: all test clean

all: bin/tests

bin/tests: *.ads *.adb zero_attribute_rule.gpr
	mkdir -p obj bin
	gnatmake -gnatwa -gnat2022 -Pzero_attribute_rule.gpr

test: all
	@echo "Running tests..."
	@bin/tests

clean:
	rm -rf obj bin
