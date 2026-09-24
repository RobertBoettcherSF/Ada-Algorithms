GNAT    := gnatmake
SPARK   := gnatprove
FLAGS   := -gnatwa -gnat2022 -gnata
OBJ_DIR := obj
BIN_DIR := bin

.PHONY: all test clean prove

all: $(BIN_DIR)/tests

$(BIN_DIR)/tests: *.ads *.adb *.gpr
	mkdir -p $(OBJ_DIR) $(BIN_DIR)
	$(GNAT) $(FLAGS) -Plinear_search.gpr

prove: *.ads *.adb *.gpr
	mkdir -p $(OBJ_DIR)
	$(SPARK) -Plinear_search.gpr --level=4

test: all
	@echo "Running tests..."
	@$(BIN_DIR)/tests

clean:
	rm -rf $(OBJ_DIR) $(BIN_DIR)
