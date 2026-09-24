.PHONY: all test clean

GNAT = gprbuild
GPR = universal_codes.gpr

all:
	mkdir -p obj bin
	$(GNAT) -P$(GPR)

test: all
	@echo "Running tests..."
	./bin/tests

clean:
	rm -rf obj/* bin/*
