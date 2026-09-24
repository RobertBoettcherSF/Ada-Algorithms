GNAT:=gnatmake
SPARK:=gnatprove
FLAGS:=-gnatwa -gnat2022 -gnata
PROVERS:=cvc5,z3,altergo
.PHONY: all test clean prove prove-l4 prove-l3 prove-l2
all:
	mkdir -p obj bin
	$(GNAT) $(FLAGS) -Phuffman_coding.gpr
test: all
	@bin/tests
prove: prove-l3
prove-l4:
	mkdir -p obj
	$(SPARK) -Phuffman_coding.gpr --mode=all --level=4 --prover=$(PROVERS) --timeout=60 --steps=0 --checks-as-errors=on --warnings=error --pedantic --proof=progressive --counterexamples=on --report=all
prove-l3:
	mkdir -p obj
	$(SPARK) -Phuffman_coding.gpr --mode=all --level=3 --prover=$(PROVERS) --timeout=30 --steps=0 --checks-as-errors=on --warnings=error --report=all
prove-l2:
	mkdir -p obj
	$(SPARK) -Phuffman_coding.gpr --mode=all --level=2 --prover=cvc5 --timeout=10 --steps=0 --checks-as-errors=on --warnings=error --report=all
clean:
	rm -rf obj bin gnatprove
