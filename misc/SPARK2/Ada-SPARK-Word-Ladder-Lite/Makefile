GNATPROVE := gnatprove
GPRBUILD := gprbuild
PROJECT := word_ladder_lite.gpr

.PHONY: all test prove clean
all: test

test:
	mkdir -p obj bin
	$(GPRBUILD) -P $(PROJECT)
	./bin/tests

prove:
	$(GNATPROVE) -P $(PROJECT) --mode=all --level=2 --prover=cvc5 --timeout=8 --steps=0 --checks-as-errors=on --warnings=error --report=all

clean:
	rm -rf obj bin gnatprove
