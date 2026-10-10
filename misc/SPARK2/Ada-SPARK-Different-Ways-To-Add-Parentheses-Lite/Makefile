GPRBUILD := gprbuild
GNATPROVE := gnatprove
PROJECT := different_ways_parentheses.gpr
PROOF_PROJECT := proof.gpr
.PHONY: all test prove clean
all: test

# make test runs the binary under a 256 MB address-space limit (ulimit -v):
# the binary needs < 10 MB; GNAT 14.2.0 leaked ~3 GB here under -gnata
# (handover H189, reproducer tools/vv/h187_gnat14_leak).
test:
	mkdir -p obj bin
	$(GPRBUILD) -P$(PROJECT)
	@ulimit -v 262144 && bin/tests

prove:
	mkdir -p obj
	$(GNATPROVE) -P$(PROOF_PROJECT) --mode=all --level=2 --prover=cvc5 --warnings=error --checks-as-errors=on

clean:
	rm -rf obj bin gnatprove
