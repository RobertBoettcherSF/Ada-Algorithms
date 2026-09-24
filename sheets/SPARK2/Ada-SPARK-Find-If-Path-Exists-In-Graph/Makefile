GNATPROVE := gnatprove
GPRBUILD := gprbuild
PROJECT := find_if_path_exists_in_graph.gpr

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
