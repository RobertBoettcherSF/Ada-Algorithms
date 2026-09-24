all: test

test:
	mkdir -p obj bin
	gprbuild -P alert_using_same_key_card_stub.gpr
	./bin/tests

prove:
	gnatprove -P proof.gpr --level=2 --prover=cvc5 --warnings=error --checks-as-errors=on

clean:
	rm -rf obj bin gnatprove
