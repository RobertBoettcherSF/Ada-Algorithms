GNAT := gnatmake
SPARK := gnatprove
FLAGS := -gnatwa -gnat2022 -gnata

.PHONY: all test prove clean
all: test

test:
	mkdir -p obj bin
	$(GNAT) $(FLAGS) -Pas_far_from_land_as_possible.gpr
	bin/tests

prove:
	mkdir -p obj
	$(SPARK) -Pas_far_from_land_as_possible.gpr --mode=all --level=2 --prover=cvc5 --timeout=8 --steps=0 --checks-as-errors=on --warnings=error --report=all

clean:
	rm -rf obj bin gnatprove
