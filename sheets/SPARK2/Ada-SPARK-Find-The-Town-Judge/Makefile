GNAT := gnatmake
SPARK := gnatprove
FLAGS := -gnatwa -gnat2022 -gnata

.PHONY: all test prove clean
all: test

test:
	mkdir -p obj bin
	$(GNAT) $(FLAGS) -Pfind_the_town_judge.gpr
	bin/tests

prove:
	mkdir -p obj
	$(SPARK) -Pfind_the_town_judge.gpr --mode=all --level=2 --prover=cvc5 --timeout=8 --steps=0 --checks-as-errors=on --warnings=error --report=all

clean:
	rm -rf obj bin gnatprove
