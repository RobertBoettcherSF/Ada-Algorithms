.PHONY: all test prove clean

all: test

test:
	mkdir -p obj bin
	gnatmake -gnatwa -gnat2022 -gnata -D obj -I. tests.adb -o bin/tests
	./bin/tests

prove:
	mkdir -p obj
	. /home/box/deps/spark/env.sh && \
	  gnatprove -P beginner_board.gpr --level=2 --prover=cvc5 \
	    --warnings=error --checks-as-errors=on \
	    -u beginner_board.ads beginner_board.adb

clean:
	rm -rf obj bin gnatprove auto.cgpr
