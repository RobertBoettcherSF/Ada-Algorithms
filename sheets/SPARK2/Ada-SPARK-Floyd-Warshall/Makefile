GNAT:=gnatmake
SPARK:=gnatprove
FLAGS:=-gnatwa -gnat2022 -gnata
.PHONY: all test clean prove
all:
	mkdir -p obj bin
	$(GNAT) $(FLAGS) -Pfloyd_warshall.gpr
test: all
	@bin/tests
prove:
	mkdir -p obj
	$(SPARK) -Pfloyd_warshall.gpr --mode=all --level=2 --prover=cvc5 --timeout=8 --steps=0 --checks-as-errors=on --warnings=error --report=all
clean:
	rm -rf obj bin gnatprove
