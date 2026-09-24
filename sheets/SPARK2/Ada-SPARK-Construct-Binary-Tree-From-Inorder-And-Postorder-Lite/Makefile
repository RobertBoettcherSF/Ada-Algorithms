all: test

test:
	mkdir -p obj bin
	gprbuild -P construct_inorder_postorder_lite.gpr
	./bin/tests

prove:
	gnatprove -P proof.gpr --level=2 --prover=cvc5 --warnings=error --checks-as-errors=on

clean:
	rm -rf obj bin gnatprove
