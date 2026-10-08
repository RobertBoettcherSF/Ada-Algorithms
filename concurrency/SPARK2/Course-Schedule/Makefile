GNAT    := gnatmake
FLAGS   := -gnatwa -gnat2022
.PHONY: all test prove clean
all: bin/tests
bin/tests: *.ads *.adb
	mkdir -p obj bin
	$(GNAT) $(FLAGS) -D obj -o bin/tests tests.adb
test: all
	@bin/tests
prove:
	gnatprove -P proof.gpr --level=2 --prover=cvc5 --warnings=error --checks-as-errors=on
clean:
	rm -rf obj bin gnatprove
