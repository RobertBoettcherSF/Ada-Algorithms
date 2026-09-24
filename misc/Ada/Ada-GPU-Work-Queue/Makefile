GPRBUILD  := gprbuild
GNATPROVE := gnatprove
PROJECT   := gpu_work_queue.gpr
PROOF     := proof.gpr

.PHONY: all test prove clean

all: test

test:
	mkdir -p obj bin
	$(GPRBUILD) -P$(PROJECT) -q
	@bin/tests

prove:
	mkdir -p obj
	. /home/box/deps/spark/env.sh && \
	  $(GNATPROVE) -P $(PROOF) --mode=all --level=2 --prover=cvc5 \
	    --warnings=error --checks-as-errors=on

clean:
	rm -rf obj bin gnatprove
