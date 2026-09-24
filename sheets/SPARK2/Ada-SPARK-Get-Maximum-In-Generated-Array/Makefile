GPRBUILD := gprbuild
GNATPROVE := gnatprove
get_maximum_in_generated_array := get_maximum_in_generated_array.gpr
.PHONY: all test prove clean
all: test

test:
	mkdir -p obj bin
	$(GPRBUILD) -P$(get_maximum_in_generated_array)
	@bin/tests

prove:
	mkdir -p obj
	$(GNATPROVE) -P$(get_maximum_in_generated_array) --mode=all --level=2 --prover=cvc5 --warnings=error --checks-as-errors=on

clean:
	rm -rf obj bin gnatprove
