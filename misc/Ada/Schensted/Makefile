# Schensted algorithm (Ada 2022 / GNAT)
GPR  := schensted.gpr
GNAT := gnatmake
FLAGS := -gnatwa -gnat2022 -P$(GPR)

.PHONY: all test clean

all:
	$(GNAT) $(FLAGS)

test: all
	./bin/tests

clean:
	rm -rf obj/* bin/*
