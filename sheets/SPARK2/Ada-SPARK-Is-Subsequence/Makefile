GPRBUILD := gprbuild
GNATPROVE := gnatprove
is_subsequence := is_subsequence.gpr
.PHONY: all test prove clean
all: test

test:
	mkdir -p obj bin
	$(GPRBUILD) -P$(is_subsequence)
	@bin/tests

prove:
	mkdir -p obj
	$(GNATPROVE) -P$(is_subsequence) --mode=all --level=2 --prover=cvc5 --warnings=error --checks-as-errors=on

clean:
	rm -rf obj bin gnatprove
