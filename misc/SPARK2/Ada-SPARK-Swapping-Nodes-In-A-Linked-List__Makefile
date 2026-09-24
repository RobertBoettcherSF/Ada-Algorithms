all: test

test:
	mkdir -p obj bin
	gprbuild -P swapping_nodes_in_a_linked_list.gpr
	./bin/tests

prove:
	gnatprove -P proof.gpr --level=2 --prover=cvc5 --warnings=error --checks-as-errors=on

clean:
	rm -rf obj bin gnatprove
