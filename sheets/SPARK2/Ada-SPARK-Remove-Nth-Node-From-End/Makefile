all: test

test:
	mkdir -p obj bin
	gprbuild -P remove_nth_node_from_end.gpr
	./bin/tests

prove:
	. /home/box/deps/spark/env.sh && gnatprove -P proof.gpr --level=2 --prover=cvc5 --warnings=error --checks-as-errors=on

clean:
	rm -rf obj bin gnatprove
