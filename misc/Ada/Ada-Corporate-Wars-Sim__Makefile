GNAT  := gnatmake
FLAGS := -gnatwa -gnat2022 -gnata

.PHONY: all test clean

all: test

test:
	mkdir -p obj bin
	$(GNAT) $(FLAGS) -P corporate_wars_sim.gpr
	bin/tests

clean:
	rm -rf obj bin
