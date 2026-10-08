GNAT    := gnatmake
FLAGS   := -gnatwa -gnat2022
.PHONY: all test clean
all: bin/tests
bin/tests: *.ads *.adb
	mkdir -p obj bin
	$(GNAT) $(FLAGS) -D obj -o bin/tests tests.adb
test: all
	@bin/tests
	@sh tests/phase_alone.sh
clean:
	rm -rf obj bin
