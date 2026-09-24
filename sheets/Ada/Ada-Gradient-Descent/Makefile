GNAT:=gnatmake
FLAGS:=-gnatwa -gnat2022
.PHONY: all test prove clean
all: bin/tests
bin/tests: *.ads *.adb *.gpr
	mkdir -p obj bin
	$(GNAT) $(FLAGS) -Pgradient_descent.gpr
test: all
	@echo "Running tests..."
	@./bin/tests
prove:
	mkdir -p obj
	gnatprove -Pgradient_descent.gpr --level=2 --timeout=60 -j0
clean:
	rm -rf obj bin gnatprove
