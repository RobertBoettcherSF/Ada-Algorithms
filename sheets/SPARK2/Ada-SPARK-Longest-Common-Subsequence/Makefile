GNAT:=gnatmake
SPARK:=gnatprove
FLAGS:=-gnatwa -gnat2022 -gnata
.PHONY: all test clean prove
all:
	mkdir -p obj bin
	$(GNAT) $(FLAGS) -Plcs.gpr
test: all
	@bin/tests
prove:
	mkdir -p obj
	$(SPARK) -Plcs.gpr --mode=all --level=2 --prover=cvc5 --timeout=10 --steps=0 --checks-as-errors=on --warnings=error --report=all
clean:
	rm -rf obj bin gnatprove
