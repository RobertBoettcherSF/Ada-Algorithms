GNAT := gnatmake
FLAGS := -gnatwa -gnat2022
GPR := jump_game_project.gpr
.PHONY: all test prove clean
all:
	mkdir -p obj bin
	$(GNAT) $(FLAGS) -P$(GPR)
test: all
	@bin/tests
prove:
	gnatprove -P$(GPR) --mode=all --level=2 --prover=cvc5 --warnings=error --checks-as-errors=on
clean:
	rm -rf obj bin
