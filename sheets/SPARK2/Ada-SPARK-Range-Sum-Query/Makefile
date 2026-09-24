GPRBUILD := gprbuild
GNATPROVE := gnatprove
range_sum_query := range_sum_query.gpr
.PHONY: all test prove clean
all: test

test:
	mkdir -p obj bin
	$(GPRBUILD) -P$(range_sum_query)
	@bin/tests

prove:
	mkdir -p obj
	$(GNATPROVE) -P$(range_sum_query) --mode=all --level=2 --prover=cvc5 --warnings=error --checks-as-errors=on

clean:
	rm -rf obj bin gnatprove
