all: test

test:
	mkdir -p obj bin
	gprbuild -P maximum_twin_sum_of_a_linked_list.gpr
	./bin/tests

prove:
	gnatprove -P proof.gpr --level=2 --prover=cvc5 --warnings=error --checks-as-errors=on

clean:
	rm -rf obj bin gnatprove
