GPRBUILD  := gprbuild
GNATPROVE := gnatprove
PROJECT   := sample.gpr
PROOF     := proof.gpr

.PHONY: all build test prove clean check

all: test

build:
	mkdir -p obj bin
	$(GPRBUILD) -P$(PROJECT)

test: build
	@bin/tests
	@echo "All tests passed."

prove:
	mkdir -p obj
	$(GNATPROVE) -P$(PROOF) --mode=all --level=2 --prover=cvc5 \
	  --timeout=30 --steps=0 --checks-as-errors=on --warnings=error --report=all

check:
	@bash scripts/open-checks.sh

clean:
	rm -rf obj bin gnatprove
