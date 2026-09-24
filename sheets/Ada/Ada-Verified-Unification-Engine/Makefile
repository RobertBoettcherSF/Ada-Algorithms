GNAT    := gnatmake
FLAGS   := -gnatwa -gnat2022 -gnata
OBJ_DIR := obj
BIN_DIR := bin

.PHONY: all test prove clean

all: $(BIN_DIR)/tests

$(BIN_DIR)/tests: *.ads *.adb *.gpr
	mkdir -p $(OBJ_DIR) $(BIN_DIR)
	$(GNAT) $(FLAGS) -Punification_engine.gpr

test: all
	@echo "Running tests..."
	@$(BIN_DIR)/tests

prove:
	mkdir -p $(OBJ_DIR)
	gnatprove -Punification_engine.gpr -u unification_engine.adb \
	  --level=2 --prover=cvc5 --warnings=error --checks-as-errors=on

clean:
	rm -rf $(OBJ_DIR) $(BIN_DIR) gnatprove
