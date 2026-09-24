GPRBUILD := gprbuild
GNATPROVE := gnatprove
PROJECT := product_of_array_except_self.gpr
PROOF_PROJECT := proof.gpr
.PHONY: all test prove clean
all: test

test:
	mkdir -p obj bin
	$(GPRBUILD) -P$(PROJECT)
	@bin/tests

prove:
	$(GNATPROVE) -P$(PROOF_PROJECT) --mode=all --level=2 --prover=cvc5 --warnings=error --checks-as-errors=on

clean:
	rm -rf obj bin gnatprove
