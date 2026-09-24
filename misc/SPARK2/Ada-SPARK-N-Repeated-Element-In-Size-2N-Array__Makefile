GPRBUILD := gprbuild
GNATPROVE := gnatprove
PROJECT := n_repeated_element_in_size_2n_array.gpr
.PHONY: all test prove clean
all: test

test:
	mkdir -p obj bin
	$(GPRBUILD) -P$(PROJECT)
	@bin/tests

prove:
	mkdir -p obj
	$(GNATPROVE) -P$(PROJECT) --mode=all --level=2 --prover=cvc5 --warnings=error --checks-as-errors=on

clean:
	rm -rf obj bin gnatprove
