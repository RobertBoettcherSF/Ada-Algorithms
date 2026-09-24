.PHONY: test prove clean
test: prove
	@mkdir -p bin
	@gnatmake -gnat2022 -gnata -Isrc tests/main.adb -o bin/main
	@bin/main
prove:
	@gnatprove -P ada_spark_swap_nodes_in_pairs.gpr --mode=all --level=2 --prover=cvc5 --warnings=error --checks-as-errors=on
clean:
	@rm -rf obj bin gnatprove *.ali *.o
