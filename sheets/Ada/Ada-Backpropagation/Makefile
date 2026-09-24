.PHONY: all test prove clean
all: bin/tests
bin/tests: *.ads *.adb *.gpr
	mkdir -p obj bin
	gnatmake -gnatwa -gnat2022 -P backpropagation.gpr
test: all
	@echo "Running tests..."
	@./bin/tests
prove:
	mkdir -p obj
	gnatprove -Pbackpropagation.gpr --level=2 --timeout=60 -j0
clean:
	rm -rf obj bin gnatprove
