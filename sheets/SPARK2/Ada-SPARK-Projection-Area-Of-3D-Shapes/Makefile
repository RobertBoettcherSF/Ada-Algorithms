all: test

test:
	mkdir -p obj bin
	gprbuild -P projection_area_of_3d_shapes.gpr
	./bin/tests

prove:
	gnatprove -P proof.gpr --level=2 --prover=cvc5 --warnings=error --checks-as-errors=on

clean:
	rm -rf obj bin gnatprove
