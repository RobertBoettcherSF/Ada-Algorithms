GNAT:=gnatmake
SPARK:=gnatprove
FLAGS:=-gnatwa -gnat2022 -gnata
.PHONY: all test clean prove prove-l4 prove-l3 prove-l2
all:
	mkdir -p obj bin
	$(GNAT) $(FLAGS) -Plevenshtein_distance.gpr
test: all
	@bin/tests
prove: prove-l3
prove-l4:
	mkdir -p obj
	$(SPARK) -Plevenshtein_distance.gpr --mode=all --level=4 --prover=cvc5,z3,altergo --timeout=60 --steps=0 --checks-as-errors=on --warnings=error --pedantic --proof=progressive --counterexamples=on --report=all
prove-l3:
	mkdir -p obj
	$(SPARK) -Plevenshtein_distance.gpr --mode=all --level=3 --prover=cvc5 --timeout=20 --steps=0 --checks-as-errors=on --warnings=error --report=all
prove-l2:
	mkdir -p obj
	$(SPARK) -Plevenshtein_distance.gpr --mode=all --level=2 --prover=cvc5 --timeout=10 --steps=0 --checks-as-errors=on --warnings=error --report=all
clean:
	rm -rf obj bin gnatprove
