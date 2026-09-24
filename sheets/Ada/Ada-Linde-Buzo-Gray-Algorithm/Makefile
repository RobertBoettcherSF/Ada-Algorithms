FLAGS   := -gnatwa -gnata -gnat2022
OBJ_DIR := obj
BIN_DIR := bin

.PHONY: all test clean

all: $(BIN_DIR)/tests

$(BIN_DIR)/tests: *.ads *.adb *.gpr
	mkdir -p obj bin
	gnatmake $(FLAGS) -Plbg.gpr

test: all
	@echo "Running tests..."
	@bin/tests

clean:
	rm -rf obj bin
