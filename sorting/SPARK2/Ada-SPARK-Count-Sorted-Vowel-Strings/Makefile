GPRBUILD := gprbuild
GNATPROVE := gnatprove
count_sorted_vowel_strings := count_sorted_vowel_strings.gpr
.PHONY: all test prove clean
all: test

test:
	mkdir -p obj bin
	$(GPRBUILD) -P$(count_sorted_vowel_strings)
	@bin/tests

prove:
	mkdir -p obj
	$(GNATPROVE) -P$(count_sorted_vowel_strings) --mode=all --level=2 --prover=cvc5 --warnings=error --checks-as-errors=on

clean:
	rm -rf obj bin gnatprove
