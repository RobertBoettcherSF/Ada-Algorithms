GPRBUILD := gprbuild
GNATPROVE := gnatprove
paint_fence_lite := paint_fence_lite.gpr
.PHONY: all test prove clean
all: test

test:
	mkdir -p obj bin
	$(GPRBUILD) -P$(paint_fence_lite)
	@bin/tests

prove:
	mkdir -p obj
	$(GNATPROVE) -P$(paint_fence_lite) --mode=all --level=2 --prover=cvc5 --warnings=error --checks-as-errors=on

clean:
	rm -rf obj bin gnatprove
