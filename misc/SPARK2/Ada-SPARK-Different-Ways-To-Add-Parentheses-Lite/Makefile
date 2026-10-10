GPRBUILD := gprbuild
GNATPROVE := gnatprove
PROJECT := different_ways_parentheses.gpr
PROOF_PROJECT := proof.gpr
.PHONY: all test prove clean
all: test

# make test runs the binary under a 256 MB address-space limit (ulimit -v):
# the binary needs < 10 MB; GNAT 14.2.0 leaked ~3 GB here under -gnata
# (handover H189, reproducer tools/vv/h187_gnat14_leak). The grep keeps Sub's Post
# free of the per-slot bound quantifier that the element subtype now carries (H191).
test:
	mkdir -p obj bin
	$(GPRBUILD) -P$(PROJECT)
	@ulimit -v 262144 && bin/tests
	@! grep -n "for all M in 1 .. Max_Results => Sub'Result" different_ways_parentheses.adb \
	  || { echo "FAIL: Sub's Post restates the element bound over every slot (H191: the Slot element subtype carries it)"; exit 1; }

prove:
	mkdir -p obj
	$(GNATPROVE) -P$(PROOF_PROJECT) --mode=all --level=2 --prover=cvc5 --warnings=error --checks-as-errors=on

clean:
	rm -rf obj bin gnatprove
