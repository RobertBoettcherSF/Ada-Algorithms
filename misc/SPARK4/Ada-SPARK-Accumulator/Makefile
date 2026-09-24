.PHONY: all test clean prove

all:
	mkdir -p obj bin && gnatmake -gnatwa -gnat2022 -gnata -gnaty -Paccumulator.gpr

prove:
	mkdir -p obj && gnatprove -Paccumulator.gpr --level=4

test: all
	./bin/tests

clean:
	rm -rf obj bin
