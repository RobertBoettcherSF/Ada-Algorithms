.PHONY: all test clean

all:
	gnatmake -P ks.gpr -p

test: all
	@echo "Running verification & validation tests..."
	@./bin/tests

clean:
	rm -rf obj bin
