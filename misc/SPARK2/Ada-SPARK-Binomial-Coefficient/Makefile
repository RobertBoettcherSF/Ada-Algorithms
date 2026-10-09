all: test

test:
	mkdir -p obj bin
	gprbuild -P binomial_coefficient.gpr
	./bin/tests

prove:
	mkdir -p obj
	gnatprove -P proof.gpr --level=2 --prover=cvc5 --warnings=error --checks-as-errors=on

clean:
	rm -rf obj bin gnatprove
