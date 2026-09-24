all: test

test:
	mkdir -p obj bin
	gprbuild -P house_robber_iii_stub.gpr
	./bin/tests

prove:
	gnatprove -P proof.gpr --level=2 --prover=cvc5 --warnings=error --checks-as-errors=on

clean:
	rm -rf obj bin gnatprove
