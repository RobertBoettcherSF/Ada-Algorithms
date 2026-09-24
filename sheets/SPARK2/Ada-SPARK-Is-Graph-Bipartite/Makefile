GNAT := gnatmake
SPARK := gnatprove
FLAGS := -gnatwa -gnat2022 -gnata

.PHONY: all test prove clean
all: test

test:
	mkdir -p obj bin
	$(GNAT) $(FLAGS) -Pis_graph_bipartite.gpr
	bin/tests

prove:
	mkdir -p obj
	$(SPARK) -Pis_graph_bipartite.gpr --mode=all --level=2 --prover=cvc5 --timeout=8 --steps=0 --checks-as-errors=on --warnings=error --report=all

clean:
	rm -rf obj bin gnatprove
