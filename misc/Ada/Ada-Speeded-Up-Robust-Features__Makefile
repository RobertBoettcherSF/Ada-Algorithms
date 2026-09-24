.PHONY: all test clean

# Using semicolons ensures that even if a line break is lost during copy-paste, 
# the commands will execute sequentially and correctly.

all:
	mkdir -p obj bin; gnatmake -P surf.gpr

test: all
	@echo "Running tests..."
	./bin/tests

clean:
	rm -rf obj bin
