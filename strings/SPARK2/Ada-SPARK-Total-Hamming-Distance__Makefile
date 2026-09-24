GPRBUILD := gprbuild
GNATPROVE := gnatprove
PROJECT := total_hamming_distance.gpr
.PHONY: all test prove clean
all: test
test:
	mkdir -p obj bin
	$(GPRBUILD) -P$(PROJECT)
	@bin/tests
prove:
	mkdir -p obj
	$(GNATPROVE) -P$(PROJECT) --mode=all --level=2 --prover=cvc5 --timeout=30 --steps=0 --warnings=error --checks-as-errors=on --report=all
clean:
	rm -rf obj bin gnatprove
