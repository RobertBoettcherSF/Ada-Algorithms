# Schensted algorithm (Ada 2022 / GNAT)
GPR  := schensted.gpr
GNAT := gnatmake -gnatwa -gnat2022 -P$(GPR)

.PHONY: all test clean

all:
	$(GNAT)

test: all
	./bin/tests

clean:
	rm -rf obj/* bin/*
