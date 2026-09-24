GPRBUILD := gprbuild
GNATPROVE := gnatprove
divisor_game := divisor_game.gpr
.PHONY: all test prove clean
all: test

test:
	mkdir -p obj bin
	$(GPRBUILD) -P$(divisor_game)
	@bin/tests

prove:
	mkdir -p obj
	$(GNATPROVE) -P$(divisor_game) --mode=all --level=2 --prover=cvc5 --warnings=error --checks-as-errors=on

clean:
	rm -rf obj bin gnatprove
