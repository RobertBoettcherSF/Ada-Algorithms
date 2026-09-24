GNATMAKE  := gnatmake
GNATPROVE := gnatprove
FLAGS     := -gnatwa -gnat2022 -gnata
PROJECT   := bounded_string_builder.gpr
PROOF     := proof.gpr

.PHONY: all test prove clean

all:
	mkdir -p obj bin
	$(GNATMAKE) $(FLAGS) -P$(PROJECT)

test: all
	@bin/tests

prove:
	mkdir -p obj
	$(GNATPROVE) -P$(PROOF) --mode=all --level=2 --prover=cvc5 \
	  --timeout=30 --steps=0 --checks-as-errors=on --warnings=error --report=all

clean:
	rm -rf obj bin gnatprove
