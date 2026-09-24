GPRBUILD := gprbuild
GNATPROVE := gnatprove
PROJECT := median_sorted_arrays_lite.gpr
.PHONY: all test prove clean
all: test

test:
	mkdir -p obj bin
	$(GPRBUILD) -P$(PROJECT)
	@bin/tests

prove:
	mkdir -p obj
	$(GNATPROVE) -P$(PROJECT) --mode=all --level=2 --prover=cvc5 --warnings=error --checks-as-errors=on --report=all

clean:
	rm -rf obj bin gnatprove
