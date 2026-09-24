GPRBUILD := gprbuild
GNATPROVE := gnatprove
delete_and_earn := delete_and_earn.gpr
.PHONY: all test prove clean
all: test

test:
	mkdir -p obj bin
	$(GPRBUILD) -P$(delete_and_earn)
	@bin/tests

prove:
	mkdir -p obj
	$(GNATPROVE) -P$(delete_and_earn) --mode=all --level=2 --prover=cvc5 --warnings=error --checks-as-errors=on

clean:
	rm -rf obj bin gnatprove
