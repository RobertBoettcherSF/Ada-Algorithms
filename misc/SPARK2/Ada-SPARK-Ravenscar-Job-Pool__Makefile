.PHONY: all test prove clean

all: test

test:
	mkdir -p obj bin
	gprbuild -P ravenscar_job_pool.gpr
	./bin/tests

prove:
	mkdir -p obj
	gnatprove -P proof.gpr --level=2 --prover=cvc5 --warnings=error --checks-as-errors=on

clean:
	rm -rf obj bin gnatprove
