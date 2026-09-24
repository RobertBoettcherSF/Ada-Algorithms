GNAT:=gnatmake
SPARK:=gnatprove
FLAGS:=-gnatwa -gnat2022 -gnata
PROJECT:=burrows_wheeler_transform.gpr
.PHONY: all test clean prove
all:
	mkdir -p obj bin
	$(GNAT) $(FLAGS) -P$(PROJECT)
test: all
	@bin/tests
prove:
	mkdir -p obj
	$(SPARK) -P$(PROJECT) --mode=all --level=2 --prover=cvc5 --timeout=10 --steps=0 --checks-as-errors=on --warnings=error --report=all
clean:
	rm -rf obj bin gnatprove
