GNATPROVE := gnatprove
GPRBUILD := gprbuild

.PHONY: all test prove clean
all: test

test:
	mkdir -p obj bin
	$(GPRBUILD) -P coin_change_ii_project.gpr
	./bin/tests

prove:
	$(GNATPROVE) -P coin_change_ii_project.gpr --mode=all --level=2 --prover=cvc5 --timeout=8 --steps=0 --checks-as-errors=on --warnings=error --report=all

clean:
	rm -rf obj bin gnatprove
