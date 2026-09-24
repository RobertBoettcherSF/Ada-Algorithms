.PHONY: all test clean

all: test

test: bin/tests
	./bin/tests

bin/tests: tests.adb
	mkdir -p obj bin
	gnatmake -D obj -o bin/tests tests.adb

clean:
	rm -rf obj bin
